# Security Policy

## Reporting a Vulnerability

Please do not open a public issue for a suspected vulnerability involving PIN handling, encryption keys, decrypted temporary files, or access to vault contents. Instead, use GitHub's private vulnerability reporting feature for this repository.

Include the affected version, Android version, reproduction steps, expected behavior, and observed impact. Do not attach real private media, credentials, keystores, or encryption keys.

## Security Scope

Mezgeb is designed to keep its core vault workflow on the device. It uses secure storage for key material, PBKDF2 for PIN verification, AES-GCM for files, SQLCipher for metadata, and Android `FLAG_SECURE` for screen protection.

The project has not received an independent security audit. A report will be evaluated before any public disclosure or release guidance is provided.
