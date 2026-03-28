# GreenLoop Developer Onboarding Checklist

## 1. Local Environment Setup
- [ ] Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.22.x+).
- [ ] Install [Visual Studio Code](https://code.visualstudio.com/) with Flutter extension.
- [ ] Install [Melos](https://pub.dev/packages/melos) globally: `dart pub global activate melos`.
- [ ] Clone the repository: `git clone <repo-url>`.

## 2. Project Bootstrapping
- [ ] Navigate to the project root and run `melos bootstrap`.
- [ ] Verify that all packages are linked correctly in `.dart_tool/package_config.json`.
- [ ] Run `flutter doctor` to ensure no environment issues remain.

## 3. Configuration & API Access
- [ ] Obtain a `development.env` (or comparable) from the team.
- [ ] Place the Maps API key in `apps/resident_app/android/app/src/main/AndroidManifest.xml`.
- [ ] Place the Maps API key in `apps/resident_app/ios/Runner/AppDelegate.swift`.
- [ ] Check `packages/network/lib/src/environment.dart` for default backend URLs.

## 4. First Run Examples
- [ ] **Resident App**: `cd apps/resident_app && flutter run`.
- [ ] **Admin Dashboard**: `cd apps/admin_dashboard && flutter run -d chrome`.
- [ ] **HKS App**: `cd apps/hks_app && flutter run` (Tested on physical device for camera).

## 5. Coding Standards
- [ ] Always create UI components in `packages/ui_kit`.
- [ ] Ensure all API models are in `packages/data_models`.
- [ ] Run `melos run format` before every commit.
- [ ] Run `melos run analyze` to check for lints.

## 6. Access Controls
- [ ] Request access to the Firebase Console: GreenLoop Project.
- [ ] Request access to Google Play Console / App Store Connect.
- [ ] Request access to the Backend Admin for test user creation.
