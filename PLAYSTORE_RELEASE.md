# Mezgeb Play Store Release Checklist

Mezgeb is designed as a local-only private vault. It does not declare `INTERNET`, does not use analytics, and stores imported content encrypted in app-private storage.

## App Identity

- App name: `Mezgeb`
- Android package/application ID: `com.mezgeb.vault`
- Minimum SDK: 26
- Target SDK: inherited from the installed Flutter/Android SDK
- Runtime permissions: biometric/device authentication only
- Backups disabled: yes
- Screenshots/app switcher previews blocked: yes, via `FLAG_SECURE`

## Before Upload

1. Create or reuse your upload keystore.
2. Run:

   ```powershell
   cd android
   powershell -ExecutionPolicy Bypass -File .\setup-upload-signing.ps1
   ```

3. Build the Play bundle:

   ```powershell
   cd ..
   flutter build appbundle
   ```

   If Flutter still reports the native debug-symbol stripping issue on this PC, direct Gradle currently works:

   ```powershell
   cd android
   .\gradlew.bat :app:bundleRelease
   ```

4. Upload:

   ```text
   build\app\outputs\bundle\release\app-release.aab
   ```

Do not upload a bundle until `android/key.properties` exists. Without it, release builds are only local verification builds.

## Play Console Answers

- Data collection: no data collected
- Data sharing: no data shared
- Network access: no
- Account creation: no
- Ads: no
- App category: Tools or Productivity
- Content access: app stores user-selected private files locally only
- Encryption: files are encrypted at rest, metadata database is encrypted

## Still Manual

- Create Play Store listing text and screenshots.
- Add a privacy policy URL. It can say the app is offline, local-only, and does not collect or transmit personal data.
- Test release build on a real Android phone before production rollout.
- Accept Android SDK licenses on this PC with `flutter doctor --android-licenses`.
