# Contributing

Thanks for helping improve Mezgeb. Keep changes focused, preserve the offline-first privacy model, and avoid committing real vault content or signing material.

## Development Checks

Before submitting a change, run:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Android behavior that touches file selection, secure storage, biometrics, screenshots, or app lifecycle locking should also be tested on a physical device.

## Change Guidelines

- Keep UI widgets focused on presentation and delegate state changes to `AppController`.
- Keep database access in `VaultDatabase` and encrypted-file operations in `VaultRepository`.
- Never log PINs, encryption keys, decrypted bytes, or user-selected filenames.
- Add tests for calendar conversion, serialization, and other deterministic logic.
- Update security documentation when changing authentication or encryption behavior.

This repository has no open-source license. Public source visibility does not grant reuse or redistribution rights.
