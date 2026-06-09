<div align="center">

# 🤖 RoboLearn

**A Flutter app that teaches kids programming through a real Bluetooth robot**

[![Flutter](https://img.shields.io/badge/Flutter-3.10.4+-02569B?style=flat&logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-FFCA28?style=flat&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=flat)](https://flutter.dev)

</div>

---

## Overview

RoboLearn lets children (ages 6–12) learn coding by dragging visual code blocks that control a real ESP32 robot over Bluetooth LE. Parents manage child profiles and track progress through a progressive 4-level curriculum covering sequencing, conditionals, loops, and variables.

---

## Features

- 🔐 **Parent accounts** — Firebase email/password auth, multi-child profile management
- 🗺️ **Adventure Map** — 4 unlockable levels with progress tracking and daily streaks
- 🧩 **Drag-and-drop editor** — visual block programming with live execution highlighting
- 🤖 **BLE robot control** — sends commands to an ESP32 robot in real time
- 🌐 **Bilingual** — full English and Arabic UI with RTL support
- 🎵 **Audio feedback** — sound effects and TTS for interactive responses

---

## Learning Levels

| Level | Theme | Concept Taught |
|---|---|---|
| 1 | Move Your Robot | Sequencing & movement |
| 2 | Play with Colors | IF/ELSE conditionals |
| 3 | Make Some Noise | Loops & LED control |
| 4 | Magic Screen | Variables & arithmetic |

---

## Tech Stack

- **Flutter / Dart** — UI and app logic
- **Firebase Auth + Firestore** — authentication and cloud data
- **flutter_blue_plus** — Bluetooth LE robot communication
- **audioplayers + flutter_tts** — sound effects and text-to-speech
- **google_fonts, flutter_animate** — UI styling and animations
- **shared_preferences** — local language preference storage

---

## Getting Started

### Prerequisites
- Flutter SDK 3.10.4+
- A Firebase project with Auth (Email/Password) and Firestore enabled
- Physical device for Bluetooth testing

### Setup

```bash
git clone https://github.com/your-org/robolearn.git
cd robolearn
flutter pub get
```

Add your Firebase config files:
- `google-services.json` → `android/app/`
- `GoogleService-Info.plist` → `ios/Runner/`
- Update `lib/firebase_options.dart` with your project credentials

```bash
flutter run
```

> Bluetooth requires a physical device. A developer mode is available for testing levels without a robot.

---

## Project Structure

```
lib/
├── screens/       # All app screens (auth, levels, dashboard)
├── models/        # Child profile and challenge data models
├── services/      # Firebase, BLE, audio, and language services
├── widgets/       # Shared UI components and drag-and-drop editor
├── theme/         # Colors, gradients, and typography
└── l10n/          # Localized strings (EN + AR)
```

---

## Contributors

| Name | Role |
|---|---|
| Diana Ghannam | CSE student |
| Nour Bzoor | CSE student |
| Misk Haneef | CSE student |

---

## License

MIT License — see [LICENSE](LICENSE) for details.
