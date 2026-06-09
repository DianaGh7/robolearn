<div align="center">

# 🤖 RoboLearn

### Teaching Kids to Code Through Physical Robotics

[![Flutter](https://img.shields.io/badge/Flutter-3.10.4+-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%2B%20Auth-FFCA28?style=flat&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=flat)](https://flutter.dev/multi-platform)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat)](LICENSE)

**RoboLearn** is a child-friendly mobile app that bridges the gap between visual programming and physical robotics. Children learn core coding concepts — sequencing, conditionals, loops, and variables — by dragging code blocks and watching their programs run on a real Bluetooth-connected ESP32 robot.

</div>

---

## 📖 Overview

RoboLearn targets young learners (ages 6–12) with a progressive 4-level curriculum that introduces programming fundamentals through play. Parents create accounts, manage child profiles, and track progress, while children interact with a colorful drag-and-drop programming interface and an actual physical robot that responds to their code.

The app combines:
- **Visual block-based programming** — no typing required
- **Physical feedback** — code controls a real robot via Bluetooth LE
- **Gamification** — streaks, celebrations, and unlockable levels
- **Bilingual support** — full English and Arabic UI with RTL layout

---

## ✨ Key Features

| Feature | Description |
|---|---|
| 🔐 Parent authentication | Firebase email/password login and registration |
| 👶 Multi-child profiles | Manage multiple children under one parent account |
| 🗺️ Adventure Map | Visual level-select screen with lock/unlock progression |
| 🧩 Drag-and-drop coding | Custom block editor with visual execution highlighting |
| 🤖 BLE robot control | Sends commands to an ESP32 robot over Bluetooth LE |
| 📈 Progress tracking | Per-child level progress and streak counter in Firestore |
| 🌐 Bilingual UI | English & Arabic with full RTL support |
| 🎵 Audio & TTS | Sound effects and text-to-speech for interactive feedback |
| 🎉 Gamification | Daily streaks, completion celebrations, attempt counters |
| 👨‍👩‍👧 Parent dashboard | Password-protected area for adding and managing children |

---

## 📱 Screens & Functionality

### Authentication Flow

| Screen | Purpose |
|---|---|
| **Splash Screen** | Animated loading screen; detects auth state and routes accordingly |
| **Welcome Screen** | Onboarding screen with language selector |
| **Login Screen** | Firebase email/password authentication |
| **Sign Up Screen** | New parent registration; auto-creates Firestore parent profile |

### Parent Area

| Screen | Purpose |
|---|---|
| **Choose Child Screen** | Displays all children under the logged-in parent |
| **Parent Dashboard** | Add, view, and manage child profiles (name, age, gender, avatar) |

### Learning Levels

All levels are accessed from the **Adventure Map**, which shows progress bars and locks levels until the previous one is completed.

---

#### 🟢 Level 1 — Move Your Robot *(Basic Sequencing)*

Children build programs using directional commands and observe them execute step-by-step on a grid visualization. BLE commands are sent to move the physical robot.

**Code blocks:** `START`, `Move Forward/Backward/Left/Right`, `Turn Left/Right`, `END`

---

#### 🔵 Level 2 — Play with Colors *(Conditional Logic)*

Introduces `IF/ELSE` logic through sound- and emotion-based challenges. Children program emotional responses and animal identification sequences.

**Code blocks:** `IF Happy`, `IF Sad`, `ELSE`, `Play Music`, `Play Sad Tone`, animal sound blocks

---

#### 🟡 Level 3 — Make Some Noise *(Loops & LED Control)*

Teaches repetition and LED color control. Children program the robot's LED to flash specific colors a set number of times.

**Code blocks:** `Set Red/Green/Blue/Yellow`, `LED Off`, `Repeat 2×/3×/5×`, `Wait`

---

#### 🔴 Level 4 — Magic Screen *(Variables & Advanced Logic)*

Introduces variables, arithmetic, and variable-based conditions. Challenges simulate real-world logic like score tracking, countdowns, and temperature-based decisions.

**Code blocks:** Variable assignment (`score`, `count`, `temperature`, `water`, `speed`), arithmetic operations, `IF/ELSE` with variable conditions

---

## 🛠️ Technologies

### Framework & Language
- **Flutter** 3.10.4+ / **Dart** 3.x

### Backend & Cloud
| Package | Version | Purpose |
|---|---|---|
| `firebase_core` | ^4.7.0 | Firebase SDK initialization |
| `firebase_auth` | ^6.1.1 | User authentication |
| `cloud_firestore` | ^6.1.0 | Cloud database for profiles and progress |
| `google_sign_in` | ^6.2.2 | Google Sign-In integration |

### Hardware & Connectivity
| Package | Version | Purpose |
|---|---|---|
| `flutter_blue_plus` | ^1.35.5 | Bluetooth Low Energy scanning and communication |
| `permission_handler` | ^11.4.0 | Runtime BLE and location permissions |

### UI & Design
| Package | Version | Purpose |
|---|---|---|
| `google_fonts` | ^8.0.2 | Nunito font for a friendly, readable UI |
| `flutter_animate` | ^4.4.0 | Smooth entrance and UI animations |
| `font_awesome_flutter` | ^10.7.0 | Extended icon set |

### Audio & Media
| Package | Version | Purpose |
|---|---|---|
| `audioplayers` | ^6.6.0 | Sound effect playback |
| `flutter_tts` | ^4.2.5 | Text-to-speech for animal sounds |

### Utilities
| Package | Version | Purpose |
|---|---|---|
| `shared_preferences` | ^2.3.2 | Persistent local storage (language preference) |
| `http` | ^1.2.2 | HTTP requests |

---

## 🏗️ Project Structure

```
robolearn/
├── lib/
│   ├── main.dart                     # App entry point, Firebase initialization
│   ├── firebase_options.dart         # Firebase project configuration
│   ├── screens/                      # All application screens
│   │   ├── splash_screen.dart
│   │   ├── welcome_screen.dart
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   ├── choose_child_screen.dart
│   │   ├── parent_dashboard_screen.dart
│   │   ├── adventure_map_screen.dart
│   │   ├── level_one_screen.dart
│   │   ├── level_one_intro_screen.dart
│   │   ├── level_two_screen.dart
│   │   ├── level_two_intro_screen.dart
│   │   ├── level_three_screen.dart
│   │   ├── level_three_intro_screen.dart
│   │   ├── level_four_screen.dart
│   │   └── level_four_intro_screen.dart
│   ├── models/
│   │   ├── child_model.dart           # Child profile data structure
│   │   └── challenge_model.dart       # Challenge and code block definitions
│   ├── services/
│   │   ├── firebase_refs.dart         # Firestore path helpers
│   │   ├── parent_service.dart        # Parent profile management
│   │   ├── child_firestore_service.dart
│   │   ├── child_progress_service.dart # Progress and streak logic
│   │   ├── robolearn_ble_service.dart  # BLE connection and command dispatch
│   │   ├── robot_command_mapper.dart   # Code block → ESP32 command mapping
│   │   ├── level4_ble_commands.dart    # Variable-based BLE commands (Level 4)
│   │   ├── sound_service.dart          # Audio playback and TTS
│   │   ├── ble_constants.dart          # BLE UUIDs and service constants
│   │   └── language_notifier.dart      # Reactive language switching
│   ├── widgets/
│   │   ├── shared_widgets.dart         # Reusable UI components
│   │   └── code_blocks_drag.dart       # Drag-and-drop block editor
│   ├── theme/
│   │   └── app_theme.dart              # Colors, gradients, typography
│   ├── l10n/
│   │   └── app_strings.dart            # Localized strings (EN + AR)
│   └── utils/
│       └── responsive.dart             # Responsive layout helpers
├── assets/
│   ├── icon/
│   │   └── app_icon.png
│   └── sounds/                         # MP3 audio files
│       ├── 0001-0008.mp3               # Numbered voice instructions
│       └── *.mp3                       # Sound effects (cheer, clap, etc.)
├── android/                            # Android configuration
├── ios/                                # iOS configuration
└── pubspec.yaml
```

---

## ⚙️ Installation & Setup

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.10.4 or later
- [Dart SDK](https://dart.dev/get-dart) (included with Flutter)
- Android Studio or Xcode (for device/emulator)
- A Firebase project (see below)
- Physical Android or iOS device recommended for Bluetooth testing

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/robolearn.git
cd robolearn
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

This project requires a Firebase project with **Authentication** and **Firestore** enabled.

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Email/Password** authentication
3. Create a **Firestore** database in production mode
4. Register your Android and iOS apps in Firebase
5. Download `google-services.json` → place in `android/app/`
6. Download `GoogleService-Info.plist` → place in `ios/Runner/`
7. Update `lib/firebase_options.dart` with your project's configuration

> **Note:** The existing `firebase_options.dart` is configured for the original Firebase project. You must replace it with your own configuration when setting up a new environment.

### 4. Android Permissions

The following permissions are already declared in `android/app/src/main/AndroidManifest.xml`:
- `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT` (Android 12+)
- `BLUETOOTH`, `BLUETOOTH_ADMIN` (legacy Android)
- `ACCESS_FINE_LOCATION` (required for BLE scanning)

No manual changes are needed.

### 5. iOS Permissions

The Bluetooth usage description is already set in `ios/Runner/Info.plist`:
```
RoboLearn uses Bluetooth to send programs to your robot screen.
```

---

## 🚀 Running the Project

```bash
# Check connected devices
flutter devices

# Run in debug mode
flutter run

# Run on a specific device
flutter run -d <device-id>

# Build a release APK (Android)
flutter build apk --release

# Build for iOS
flutter build ios --release
```

> **Bluetooth Note:** BLE features require a physical device. An emulator will run the app but the robot connection will not function. The app includes a **developer mode** flag to test level functionality without a physical robot.

---

## 🤖 BLE Robot Specification

The app connects to an ESP32-based robot over Bluetooth LE using the following configuration:

| Property | Value |
|---|---|
| Device name | `RoboLearn` |
| Service UUID | `12345678-1234-1234-1234-123456789001` |
| Command characteristic UUID | `12345678-1234-1234-1234-123456789002` |

**Supported command codes:**

| Command | Action |
|---|---|
| `D0` | Move forward |
| `D1` | Move backward |
| `D2` | Move left |
| `D3` | Move right |
| `D5` | Turn left |
| `D10` | Turn right |
| `HPY` | Happy / play music |
| `SAD` | Sad / snow animation |
| `SUN` | Sunny display |
| `LF` | Beep / clap sound |

---

## 🗄️ Firestore Data Structure

```
parents/{uid}
  ├── email: string
  ├── displayName: string
  ├── createdAt: timestamp
  └── children/{childId}
        ├── name: string
        ├── age: number
        ├── gender: string
        ├── level: number
        ├── progress: number
        ├── streak: number
        ├── completedChallengeIds: string[]
        ├── subLevelProgressByLevel: map
        ├── createdAt: timestamp
        └── updatedAt: timestamp
```

---

## 🌐 Localization

The app supports **English** and **Arabic** with full RTL layout switching.

- All UI strings are centralized in `lib/l10n/app_strings.dart`
- Language preference persists across sessions via `SharedPreferences`
- Direction and alignment adjust automatically for Arabic
- Language can be toggled from the Welcome, Login, and Sign Up screens

---

## 🗺️ Roadmap

The following improvements are planned or in consideration:

- [ ] **Offline mode** — cache child progress locally for use without internet
- [ ] **Level 5+** — expand the curriculum with more advanced programming concepts
- [ ] **Custom avatars** — let children personalize their robot companion
- [ ] **Parent progress reports** — detailed analytics dashboard for parents
- [ ] **Additional languages** — expand beyond English and Arabic
- [ ] **Web/Desktop support** — extend the app to more platforms
- [ ] **Variable execution on robot** — send Level 4 variable logic as actual ESP32 commands
- [ ] **Classroom mode** — multi-device support for school environments

---

## 👥 Contributors

| Name | Role |
|---|---|
| Diana Ghannam | Flutter Developer |
| Nour | Flutter Developer |

---

## 📄 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

---

<div align="center">

Built with ❤️ using Flutter · Firebase · Bluetooth LE

</div>
