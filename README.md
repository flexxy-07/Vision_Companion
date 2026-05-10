# 👁️ Vision Companion

A camera-powered AI assistant built for the ProxMaq Flutter Developer Intern Assignment.

## Features
- Firebase Auth (Email/Password + Google Sign-In)
- Object Detector (TFLite SSD MobileNet V1)
- AI Image Analyzer (Groq Llama 4 Scout)
- English + Hindi localization
- Full TalkBack accessibility
-  history logging

## Tech Stack
| Area | Technology |
|---|---|
| Framework | Flutter 3.x |
| State Management | flutter_bloc (Cubit) |
| Backend | Firebase (Auth, Firestore, Crashlytics, Analytics) |
| ML Feature 1 | TensorFlow Lite (SSD MobileNet V1) |
| ML Feature 2 | Groq API (Llama 4 Scout) |
| Navigation | go_router |
| DI | get_it |

## Setup

### 1. Clone
```bash
git clone https://github.com/flexxy-07/vision_companion
cd vision_companion
```

### 2. Environment variables
```bash
cp .env.example .env
```
Edit `.env` and add your Groq API key.

### 3. Firebase
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 4. TFLite model
Place `ssd_mobilenet_v1.tflite` in `assets/models/`

### 5. Run
```bash
flutter pub get
flutter run
```

### 6. Build APK
```bash
flutter build apk --release
```

## APK Download
[Download latest APK](https://github.com/YOUR_USERNAME/vision_companion/releases/latest)

## Documentation
See [docs/documentation.md](docs/documentation.md)
