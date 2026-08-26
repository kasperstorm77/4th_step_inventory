# local_files/ — git-ignored secrets and build inputs

Everything a fresh clone needs that git must never carry. Only this README and
`pack.sh` are tracked; every other file here is ignored (see `.gitignore`).

| File | Used by |
|---|---|
| `my-release-key.jks` | Release signing — `android/app/build.gradle.kts` via `key.properties`. **Irreplaceable.** |
| `debug.keystore` | Debug signing (SHA-1 registered in Google Cloud) — picked up automatically by `build.gradle.kts` when present. |
| `key.properties` | Release keystore path + passwords (`storeFile` is relative to `android/app/`). |
| `google-services_debug.json` / `google-services_release.json` | Copied to `android/app/google-services.json` per build type by gradle. |
| `desktop_oauth_config.dart` | Desktop OAuth client; `lib/shared/services/google_drive/desktop_oauth_config.dart` is a symlink to it. |
| `play-service-account.json` | `scripts/upload-aab-to-play.sh`, `scripts/publish-play-listing.sh` |
| `AuthKey_<KEYID>.p8` + `asc_issuer` | App Store Connect API — TestFlight notes and `scripts/appstore-*.sh` |
| `app_sp_pw` | Apple app-specific password — `scripts/upload-ipa-to-testflight.sh` |
| `LOCAL_SETUP.md` | Full clone→build runbook with every credential value. |

## Moving to another machine

```bash
bash local_files/pack.sh list              # what will be packed, what is missing
bash local_files/pack.sh pack              # -> ~/Desktop/twelve_steps_local_files.tar.gz.enc (AES-256, prompts for a password)
# on the new machine, inside a fresh clone:
bash local_files/pack.sh unpack ~/Desktop/twelve_steps_local_files.tar.gz.enc
```

`pack` also bundles the regenerable platform files `flutter create` would stub
(Android launcher icons/MainActivity/gradle wrapper, iOS app icon + launch
images, `pubspec.lock`) so the clone builds without the fix-up steps. `unpack`
restores everything to its original path and re-creates the Dart symlink.
Add `--plain` to skip encryption (then treat the archive as a password file).

Also needed off-repo: your Apple signing certificate/profile (Xcode account),
and the sibling `../emotional_sobriety` checkout for `scripts/verify-cross-app-recovery.sh`.
