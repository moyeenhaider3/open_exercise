# Phase 05 Plan 03 Summary: AUTH-05 guest-only audit & checklist closure

**Completed Date**: 2026-09-30
**Execution Type**: autonomous

## Summary of Accomplishments

1. **Repeatable Guest Audit Script (`tool/guest_audit.sh`)**:
   - Implemented `tool/guest_audit.sh` with checks (a) through (i):
     - (a) Ensures no call to `ApiClientFactory.create()` outside `lib/core/api/`.
     - (b) Ensures no direct `Dio(` instantiation and no `import 'package:dio/'` outside `lib/core/api/`.
     - (c) Ensures no import of `core/api/generated/` outside `lib/core/api/`.
     - (d) Ensures `lib/core/router/app_router.dart` has no auth/server/admin routes.
     - (e) Ensures no account/server UI strings (`t('Sign in`, `t('Connect to my server`, etc.) or components (`SyncBanner`, `LoginScreen`, etc.) exist in `lib/`.
     - (f) Ensures `pubspec.yaml` has no forbidden network/auth packages (`flutter_passkey_service`, `http`, `firebase_*`, `supabase`, `google_sign_in`, etc.).
     - (g) Ensures `android/app/src/main/AndroidManifest.xml` has no `android.permission.INTERNET` or `USE_EXACT_ALARM`.
     - (h) Ensures `js_engine_service.dart` initializes JavaScript runtime with `xhr: false`.
     - (i) Informational merged release manifest inspect.
   - Tested positive pass (`GUEST AUDIT: PASS`).
   - Tested negative detection (throwaway call to `ApiClientFactory().create` triggered failure exit 1).

2. **Inert ApiClientFactory Documentation**:
   - Updated `lib/core/api/open_gym_api_client.dart` with class doc comment explicitly declaring the v1 guest-only (AUTH-05, D-01/D-02) rule and referencing `tool/guest_audit.sh`.
   - Preserved generated Dio/Retrofit client files untouched per D-11.

3. **Checklist Update**:
   - Updated `.planning/phases/03-bloc-ui-translation/03-UI07-CHECKLIST.md`:
     - Marked all account/guest actions (`isGuest`, `setGuest`, `loadConfig`, `refreshConfig`, `setUser`, `signOut`, `signOutAll`, `chooseLocalMode`, `connectToServer`, `disconnectServer`) as N/A (guest-only, Phase 5 D-01).
     - Documented `guestAllowed(null) === true` rationale (D-03).
     - Marked `pushState`, `pullState`, `adoptProfile` as N/A per 2026-09-30 roadmap scope update (local backup replacing online sync in Phase 6).
     - Marked section 4 "Account / pairing / passkey rows" and "Home 'Hi {name}' greeting" as N/A.

4. **Audits & Verification**:
   - `bash tool/guest_audit.sh`: PASS.
   - `flutter analyze`: clean.
   - Verification loops in `03-UI07-CHECKLIST.md` all succeeded.
