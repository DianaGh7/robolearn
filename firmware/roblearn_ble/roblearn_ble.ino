/*
 * RoboLearn ESP32 BLE GATT Server
 *
 * Device name : RoboLearn
 * Service     : 12345678-1234-1234-1234-123456789001
 * Characteristic (WRITE + WRITE_NR):
 *               12345678-1234-1234-1234-123456789002
 *
 * Accepted commands (ASCII string):
 *   D0 D1 D2 D3 D4 D5 D10 SUN SLF LF SFL HPY SAD
 *
 * Display hardware: SSD1306 128x64 OLED (I2C, SDA=21 SCL=22)
 * Required libraries: Adafruit_SSD1306, Adafruit_GFX
 */

#include <math.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define DEVICE_NAME "RoboLearn"

#define SERVICE_UUID        "12345678-1234-1234-1234-123456789001"
#define CHARACTERISTIC_UUID "12345678-1234-1234-1234-123456789002"

// ── OLED ─────────────────────────────────────────────────────────────────────
#define SCREEN_WIDTH  128
#define SCREEN_HEIGHT  64
#define OLED_RESET     -1
#define OLED_ADDRESS 0x3C

Adafruit_SSD1306 oled(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// ── BLE ───────────────────────────────────────────────────────────────────────
BLEServer          *pServer                = nullptr;
BLECharacteristic  *pCommandCharacteristic = nullptr;

bool deviceConnected    = false;
bool oldDeviceConnected = false;

// ── Display helpers ───────────────────────────────────────────────────────────

// Show a number (0-99) large and centred.
void showNumber(int n) {
  oled.clearDisplay();
  String text = String(n);

  uint8_t sz = (text.length() == 1u) ? 5u : 4u;
  int16_t charW = (int16_t)(sz * 6);
  int16_t charH = (int16_t)(sz * 8);
  int16_t x     = (int16_t)((SCREEN_WIDTH  - charW * (int16_t)text.length()) / 2);
  int16_t y     = (int16_t)((SCREEN_HEIGHT - charH) / 2);

  oled.setTextSize(sz);
  oled.setTextColor(SSD1306_WHITE);
  oled.setCursor(x, y);
  oled.print(text);
  oled.display();
}

// Draw a simple sun: filled circle + 8 short rays.
void drawSun() {
  oled.clearDisplay();

  const int16_t cx = (int16_t)(SCREEN_WIDTH  / 2);
  const int16_t cy = (int16_t)(SCREEN_HEIGHT / 2);
  const int16_t r  = 12;   // sun body radius
  const int16_t rl = 8;    // ray length
  const float   gap = 4.0f; // gap between body and ray start

  oled.fillCircle(cx, cy, r, SSD1306_WHITE);

  // 8 rays at 45-degree steps
  const float step = (float)(M_PI / 4.0);
  for (int i = 0; i < 8; i++) {
    float rad = (float)i * step;
    float cosR = cosf(rad);
    float sinR = sinf(rad);
    int16_t x1 = (int16_t)((float)cx + ((float)r + gap)        * cosR);
    int16_t y1 = (int16_t)((float)cy + ((float)r + gap)        * sinR);
    int16_t x2 = (int16_t)((float)cx + ((float)r + gap + (float)rl) * cosR);
    int16_t y2 = (int16_t)((float)cy + ((float)r + gap + (float)rl) * sinR);
    oled.drawLine(x1, y1, x2, y2, SSD1306_WHITE);
  }
  oled.display();
}

// Draw a smiley face. happy=true -> smile, happy=false -> frown.
void drawFace(bool happy) {
  oled.clearDisplay();

  const int16_t cx = (int16_t)(SCREEN_WIDTH  / 2);
  const int16_t cy = (int16_t)(SCREEN_HEIGHT / 2);
  const int16_t fr = 22;  // face radius
  const int16_t er = 3;   // eye radius
  const int16_t ex = 8;   // eye X offset from centre
  const int16_t ey = 7;   // eye Y offset from centre (upward)

  oled.drawCircle(cx, cy, fr, SSD1306_WHITE);
  oled.fillCircle((int16_t)(cx - ex), (int16_t)(cy - ey), er, SSD1306_WHITE);
  oled.fillCircle((int16_t)(cx + ex), (int16_t)(cy - ey), er, SSD1306_WHITE);

  // Mouth: parabola arc, 19 pixels wide
  const int16_t mHalfW = 9;
  const int16_t mOffY  = 6;   // centre of mouth below face centre
  const int16_t mDepth = 5;   // max depth of the curve

  for (int16_t i = -mHalfW; i <= mHalfW; i++) {
    float t  = (float)i / (float)mHalfW;   // -1.0 .. +1.0
    int16_t dy = (int16_t)((float)mDepth * t * t);
    if (!happy) dy = (int16_t)(-dy);
    int16_t px = (int16_t)(cx + i);
    int16_t py = (int16_t)(cy + mOffY + dy);
    oled.drawPixel(px, py,            SSD1306_WHITE);
    oled.drawPixel(px, (int16_t)(py + 1), SSD1306_WHITE);
  }
  oled.display();
}

// Draw a plant at growth stage 1 (seedling), 2 (sprout), 3 (sunflower).
void drawPlant(uint8_t stage) {
  oled.clearDisplay();

  const int16_t cx  = (int16_t)(SCREEN_WIDTH  / 2);
  const int16_t bot = (int16_t)(SCREEN_HEIGHT - 4);

  int16_t stemH   = (int16_t)(8 + (int16_t)stage * 10);
  int16_t stemTop = (int16_t)(bot - stemH);

  oled.drawLine(cx, bot, cx, stemTop, SSD1306_WHITE);

  if (stage >= 1u) {
    int16_t ly = (int16_t)(stemTop + stemH / 2);
    oled.drawLine(cx, ly, (int16_t)(cx - 8), (int16_t)(ly - 4), SSD1306_WHITE);
  }

  if (stage >= 2u) {
    int16_t ly2 = (int16_t)(stemTop + 6);
    oled.drawLine(cx, ly2, (int16_t)(cx + 10), (int16_t)(ly2 - 4), SSD1306_WHITE);
    oled.drawLine(cx, ly2, (int16_t)(cx - 10), (int16_t)(ly2 - 4), SSD1306_WHITE);
  }

  if (stage >= 3u) {
    int16_t fcy = (int16_t)(stemTop - 8);
    oled.fillCircle(cx, fcy, 7, SSD1306_WHITE);
    oled.drawLine(cx,              (int16_t)(fcy - 7),  cx,              (int16_t)(fcy - 13), SSD1306_WHITE);
    oled.drawLine(cx,              (int16_t)(fcy + 7),  cx,              (int16_t)(fcy + 13), SSD1306_WHITE);
    oled.drawLine((int16_t)(cx-7), fcy, (int16_t)(cx-13), fcy, SSD1306_WHITE);
    oled.drawLine((int16_t)(cx+7), fcy, (int16_t)(cx+13), fcy, SSD1306_WHITE);
  }

  oled.display();
}

// ── Command handler ───────────────────────────────────────────────────────────

void handleCommand(const String &command) {
  Serial.print("[CMD] ");
  Serial.println(command);

  if      (command == "D0")  { showNumber(0); }
  else if (command == "D1")  { showNumber(1); }
  else if (command == "D2")  { showNumber(2); }
  else if (command == "D3")  { showNumber(3); }
  else if (command == "D4")  { showNumber(4); }
  else if (command == "D5")  { showNumber(5); }
  else if (command == "D10") { showNumber(10); }
  else if (command == "SUN") { drawSun(); }
  else if (command == "HPY") { drawFace(true); }
  else if (command == "SAD") { drawFace(false); }
  else if (command == "SLF") { drawPlant(1); }
  else if (command == "LF")  { drawPlant(2); }
  else if (command == "SFL") { drawPlant(3); }
  else {
    oled.clearDisplay();
    oled.setTextSize(1);
    oled.setTextColor(SSD1306_WHITE);
    oled.setCursor(0, 0);
    oled.print("? ");
    oled.print(command);
    oled.display();
    Serial.print("[CMD] unknown: ");
    Serial.println(command);
  }
}

// ── BLE callbacks ─────────────────────────────────────────────────────────────

class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *server) override {
    deviceConnected = true;
    Serial.println("[BLE] device connected");
  }

  void onDisconnect(BLEServer *server) override {
    deviceConnected = false;
    Serial.println("[BLE] device disconnected");
  }
};

class CommandCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *characteristic) override {
    std::string value = characteristic->getValue();
    if (value.empty()) return;

    String command = String(value.c_str());
    command.trim();
    command.toUpperCase();

    Serial.print("[BLE] write received: ");
    Serial.println(command);

    handleCommand(command);
  }
};

// ── Setup & loop ──────────────────────────────────────────────────────────────

void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println();
  Serial.println("[BOOT] RoboLearn BLE server starting");

  Wire.begin();
  if (!oled.begin(SSD1306_SWITCHCAPVCC, OLED_ADDRESS)) {
    Serial.println("[OLED] SSD1306 init failed - check wiring (SDA=21, SCL=22)");
  } else {
    oled.clearDisplay();
    oled.setTextColor(SSD1306_WHITE);
    oled.setTextSize(2);
    oled.setCursor(10, 20);
    oled.print("RoboLearn");
    oled.display();
    Serial.println("[OLED] ready");
  }

  BLEDevice::init(DEVICE_NAME);

  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  pCommandCharacteristic = pService->createCharacteristic(
      CHARACTERISTIC_UUID,
      BLECharacteristic::PROPERTY_WRITE |
          BLECharacteristic::PROPERTY_WRITE_NR);

  pCommandCharacteristic->setCallbacks(new CommandCallbacks());
  pCommandCharacteristic->setValue("");

  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMaxPreferred(0x12);

  BLEDevice::startAdvertising();
  Serial.println("[BLE] advertising started");
}

void loop() {
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("[BLE] advertising restarted");
    oldDeviceConnected = deviceConnected;
  }

  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }

  delay(10);
}
