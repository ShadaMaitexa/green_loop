# GreenLoop Flutter Deployment Runbook

## 1. Prerequisites
- **Flutter SDK**: v3.22.2 or later
- **Melos**: Installed globally (`dart pub global activate melos`)
- **Git**: For version control
- **Android Studio / Xcode**: For platform-specific builds

## 2. Environment Configuration
Apps use `--dart-define` or a `.env` file via `packages/network/lib/src/environment.dart`.

### Required Keys:
- `MAPS_API_KEY`: Google Maps API Key (Android/iOS)
- `API_BASE_URL`: Production backend URL
- `FIREBASE_API_KEY`: Web/Android/iOS Firebase configuration

## 3. Build Process (Melos)
The project uses Melos for workspace management.

### Bootstrap
First, link all packages and download dependencies:
```bash
melos bootstrap
```

### Build APK (Production)
For Android deployment:
```bash
# In root directory
melos exec --dir-exists="android" -- "flutter build apk --release --obfuscate --split-debug-info=./debug-info"
```

### Build IPA (iOS)
For iOS deployment (Mac only):
```bash
melos exec --dir-exists="ios" -- "flutter build ipa --release"
```

## 4. Signing (Android)
Ensure `apps/<app_name>/android/key.properties` exists with:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=../../upload-keystore.jks
```

## 5. Deployment Checklist
1. [ ] Increment `version` in `pubspec.yaml`
2. [ ] Run `melos run analyze` to ensure no lints
3. [ ] Run `melos run test` for unit/widget tests
4. [ ] Build the release artifact
5. [ ] Upload to Google Play (Internal/Production) / Apple App Store
6. [ ] Verify ProGuard/R8 rules in `android/app/proguard-rules.pro` (if using ML/TensorFlow)
