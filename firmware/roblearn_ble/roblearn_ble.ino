/*
 * RoboLearn ESP32 BLE GATT Server
 *
 * Device name : RoboLearn
 * Service     : 12345678-1234-1234-1234-123456789001
 * Characteristic (WRITE + WRITE_NR):
 *               12345678-1234-1234-1234-123456789002
 *
 * Accepted commands (ASCII string):
 *   D0 D1 D2 D3 D5 D10 SUN SLF LF SFL HPY SAD
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define DEVICE_NAME "RoboLearn"

#define SERVICE_UUID "12345678-1234-1234-1234-123456789001"
#define CHARACTERISTIC_UUID "12345678-1234-1234-1234-123456789002"

BLEServer *pServer = nullptr;
BLECharacteristic *pCommandCharacteristic = nullptr;

bool deviceConnected = false;
bool oldDeviceConnected = false;

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
    if (value.empty()) {
      return;
    }

    String command = String(value.c_str());
    command.trim();
    command.toUpperCase();

    Serial.print("[BLE] write received: ");
    Serial.println(command);

    handleCommand(command);
  }
};

void handleCommand(const String &command) {
  if (command == "D0") {
    Serial.println("[CMD] move forward");
  } else if (command == "D1") {
    Serial.println("[CMD] move backward");
  } else if (command == "D2") {
    Serial.println("[CMD] move left");
  } else if (command == "D3") {
    Serial.println("[CMD] move right");
  } else if (command == "D5") {
    Serial.println("[CMD] turn left");
  } else if (command == "D10") {
    Serial.println("[CMD] turn right");
  } else if (command == "SUN") {
    Serial.println("[CMD] show sun");
  } else if (command == "SLF") {
    Serial.println("[CMD] sleep");
  } else if (command == "LF") {
    Serial.println("[CMD] look forward");
  } else if (command == "SFL") {
    Serial.println("[CMD] smile");
  } else if (command == "HPY") {
    Serial.println("[CMD] happy");
  } else if (command == "SAD") {
    Serial.println("[CMD] sad");
  } else {
    Serial.print("[CMD] unknown: ");
    Serial.println(command);
  }
}

void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println();
  Serial.println("[BOOT] RoboLearn BLE server starting");

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
