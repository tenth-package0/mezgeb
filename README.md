# Mezgeb

Mezgeb is an offline-first Flutter app for protecting photos and files locally, with Ethiopian calendar dates and a choice of clean modern themes.

## Why Mezgeb

Private memories should not require a cloud account. Mezgeb keeps its core vault workflow on the device while adding Ethiopian calendar organization for people who want their files presented in a culturally familiar timeline.

The app does not request internet access, use analytics, show ads, or create user accounts.

## Run

```powershell
flutter pub get
flutter run
```

If no Android phone or emulator appears, run:

```powershell
flutter devices
flutter emulators
```

## Verify

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

The debug APK is built at:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Current v1

- Flutter app named `Mezgeb`
- PIN onboarding and PIN unlock
- Biometric/device auth through `local_auth`
- `FLAG_SECURE` enabled in the Android host activity
- SQLCipher-backed metadata database
- AES-GCM encrypted files in app-private storage
- Android system document picker through a small MethodChannel
- Ethiopian calendar converter with Amharic month names
- Timeline year/month/day browsing with pinch zoom-out
- Albums, fullscreen viewer, Settings, and theme picker
- Themes: One Light, Sky Glass, Forest, Rose, Midnight

## Security Design

- PINs are derived with PBKDF2-HMAC-SHA256 and a random per-user salt
- Encryption keys are generated with a cryptographically secure random source
- Keys are stored through Android secure storage
- File contents use AES-GCM authenticated encryption
- Metadata is stored in a SQLCipher-backed database
- Screenshots and app-switcher previews are blocked with `FLAG_SECURE`
- The app locks when moved to the background

This project has not received an independent security audit. Review the implementation and test it carefully before relying on it for irreplaceable or highly sensitive data.

## Project Structure

```text
lib/
├── calendar/   Ethiopian calendar conversion
├── data/       encrypted database and vault repository
├── domain/     vault and album models
├── platform/   Android document picker bridge
├── security/   PIN, biometric, and key management
└── ui/         app screens, themes, and controller
```

## Next Pass

- Camera capture directly into encrypted vault storage
- Encrypted thumbnails for faster grid performance
- Share-out flow with a wiped temporary decrypted cache file
- More album management polish

## Play Store

See `PLAYSTORE_RELEASE.md` for signing, bundle, and Play Console checklist steps.

## Source Availability

No open-source license has been selected. The source is publicly viewable, but reuse, modification, and redistribution are not granted by default. Vendored dependencies under `third_party/` retain their respective license files.
