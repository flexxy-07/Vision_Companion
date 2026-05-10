# Vision Companion — Documentation

## App Architecture

Feature-first Clean Architecture:

UI (Pages) → Cubit (State) → Repository → Firebase / TFLite / Groq API

### Cubits
- AuthCubit → Unauthenticated | Loading | Authenticated | Error
- DetectorCubit → Idle | Running | Paused | Results | Error
- AnalyzerCubit → Idle | Processing | Result | Error
- SettingsCubit → SettingsState(locale)

### Folder Structure

lib/
core/         → theme, router, DI
features/
auth/       → login, signup
home/       → home screen
detector/   → TFLite live detection
analyzer/   → Groq AI analysis
history/    → Firestore history
settings/   → language toggle
l10n/         → EN + HI ARB files

---

## Feature Walkthroughs

### Feature 1 — Live Object Detector
1. Tap Start on home screen
2. Camera opens with live feed
3. TFLite runs inference on each frame via background Isolate
4. Bounding boxes drawn via CustomPainter
5. Haptic feedback + TalkBack announcement on detection
6. Results saved to Firestore

### Feature 2 — AI Image Analyzer
1. Tap Start on home screen
2. Camera opens
3. Tap Capture & Analyze
4. Image sent to Groq API (Llama 4 Scout vision model)
5. Results shown: description, tags with confidence, dominant colors
6. Results saved to Firestore

---

## Firebase Setup Steps

1. Create project at console.firebase.google.com
2. Enable Authentication → Email/Password + Google
3. Enable Firestore → test mode
4. Enable Crashlytics + Analytics
5. Install FlutterFire CLI:
```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
```
6. Add SHA-1 + SHA-256 fingerprints for Google Sign-In:
```bash
   keytool -list -v -keystore ~/.android/debug.keystore \
   -alias androiddebugkey -storepass android -keypass android
```

---

## How to Run

### Prerequisites
- Flutter 3.x
- Android device or emulator (API 21+)
- Firebase project configured

### Steps
```bash
git clone https://github.com/YOUR_USERNAME/vision_companion
cd vision_companion
cp .env.example .env          # add your GROQ_API_KEY
flutterfire configure         # generates firebase_options.dart
flutter pub get
flutter run
```

### Build Release APK
```bash
flutter build apk --release
```

---

## Localization
- English: lib/l10n/app_en.arb
- Hindi: lib/l10n/app_hi.arb
- Toggle in Settings screen
- Persisted via shared_preferences

## TalkBack Accessibility
- Every screen navigable by directional swipe
- Camera preview labeled: "Live camera feed for object detection"
- Pause/Resume button: dynamic semantic label
- Processing indicator: announces "Processing"
- Tag chips: "Tag: {label}, {confidence}% confidence"
- Profile avatar: "Profile: {name}, tap to open menu"
- Language switch: announces selected language

## Known Limitations
- SSD MobileNet V1 is lightweight — detection not 100% accurate on all objects
- Groq free tier has rate limits
- Google Sign-In requires SHA-1 in Firebase Console