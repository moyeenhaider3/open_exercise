# OpenGym – Google Play Store Deployment Guide & Listing Metadata

This document contains all exact copy-paste information, policy declarations, graphic specifications, and build instructions required to submit **OpenGym** to the Google Play Console.

---

## 1. Store Listing Metadata

### App Name (30 character limit)
```text
OpenGym: Workout Log & Tracker
```

### Short Description (80 character limit)
```text
Private, offline gym and bodyweight workout tracker. No ads, no account needed.
```

### Full Description (Up to 4000 characters)
```text
Take complete control of your fitness journey with OpenGym — the private, offline-first gym workout and bodyweight tracker. 

Designed for lifters, athletes, and calisthenics practitioners who want a clean, lightning-fast workout log without subscriptions, intrusive ads, or forced cloud accounts. All your data stays strictly on your device.

KEY FEATURES:

• WORKOUT & EXERCISE TRACKING
  - Log sets, reps, weights (kg/lbs), RPE, and warmups in seconds.
  - Interactive rest timer with audible chimes and background notification support.
  - Plate calculator and dynamic progressive overload tracking.

• EXTENSIVE EXERCISE LIBRARY
  - Hundreds of built-in barbell, dumbbell, cable, machine, and bodyweight exercises.
  - Detailed muscle targeting breakdown (primary and secondary muscle groups).
  - Clean anatomical demonstration animations and guides.

• PROGRESS & ANALYTICS
  - Track personal records (PRs), estimated 1-Rep Max (1RM), and total volume over time.
  - Muscle recovery and volume distribution heatmaps.
  - Interactive calendar and workout streak history.

• BODYWEIGHT & MEASUREMENTS
  - Record bodyweight check-ins and body composition changes.
  - Visual trend lines to track cutting, bulking, or maintenance phases.

• TOTAL PRIVACY & ZERO CLOUD DEPENDENCY
  - No account registration, email, or login required.
  - 100% offline functionality — works anywhere without an internet connection.
  - One-tap export and import of your complete database via JSON backups.
  - Zero third-party trackers, zero advertising SDKs, and zero telemetry.

• OPEN SOURCE
  - Free and open-source software licensed under AGPL-3.0.
  - Built with transparency and respect for user ownership.

Get stronger, stay consistent, and keep your data yours with OpenGym.
```

### Categorization
- **Application Type**: App
- **Category**: Health & Fitness
- **Tags**: Fitness, Workout, Gym, Calisthenics, Weightlifting

### Store Listing Contact Details
- **Email**: `your-email@domain.com` (use your developer email)
- **Website**: `https://moyeenhaider3.github.io/open_exercise`
- **Privacy Policy URL**: `https://moyeenhaider3.github.io/open_exercise/privacy.html`

---

## 2. Store Graphic Assets Required

| Asset | Size / Specs | Requirements |
|---|---|---|
| **App Icon** | 512 x 512 px | 32-bit PNG, sRGB, max 1024 KB. Flat square without rounded corners (Google Play rounds automatically). |
| **Feature Graphic** | 1024 x 500 px | PNG or JPEG, 24-bit, no transparency, max 15 MB. Bold banner featuring OpenGym branding and neon accent. |
| **Phone Screenshots** | Min 2, Max 8 | 16:9 or 9:16 aspect ratio (e.g. 1080x1920 or 1080x2400). Recommended screens: Active Workout Log, Exercise Library, Progress Stats, Calendar. |

---

## 3. Play Console Policy & Declarations Questionnaire

When completing the **App Content** section in Google Play Console, enter these answers:

### Privacy Policy
- URL: `https://moyeenhaider3.github.io/open_exercise/privacy.html`

### App Access
- Select: **"All functionality is available without special access"** (no login credentials required).

### Ads
- Select: **"No, my app does not contain ads"**.

### Content Ratings Questionnaire
- Category: **Utility, Productivity, Communication, or Other**
- Violence: **No**
- Sexuality: **No**
- Language / Profanity: **No**
- Controlled Substances: **No**
- User Interaction / Location Sharing: **No**
- Result: **PEGI 3 / Everyone (All ages)**

### Target Audience and Content
- Target age group: **18 and over**
- Appeal to children: **No**

### News / COVID-19 / Government / Financial
- Select **No** for all.

### Health Apps Declaration
- Does the app provide health-related features? -> **Yes**
- Category: **Fitness & wellness tracker (Physical activity and workouts)**
- Non-medical disclaimer acknowledged: **Yes**

### Data Safety Questionnaire (CRITICAL)
- Does your app collect or share any user data? -> **NO**
- Explanation: All workout data, weights, body measurements, and settings are stored locally on the user's phone in a local SQLite database. No data is transmitted off-device.

---

## 4. GitHub Pages Deployment (Privacy Policy & Versioning)

The legal pages and version manifest are located in `/docs`. To make them live:

1. Push your repository commits to GitHub:
   ```bash
   git add .
   git commit -m "feat: configure OpenGym branding, legal docs, and update check"
   git push origin main
   ```
2. In your GitHub repository:
   - Navigate to: **Settings** -> **Pages**.
   - Under **Build and deployment** -> **Source**: select **Deploy from a branch**.
   - Under **Branch**: select `main` and folder `/docs`.
   - Click **Save**.
3. Your live URLs will be:
   - Privacy Policy: `https://<your-username>.github.io/<repo-name>/privacy.html`
   - Terms: `https://<your-username>.github.io/<repo-name>/terms.html`
   - Version manifest: `https://<your-username>.github.io/<repo-name>/version.json`

*(Note: Replace `moyeenhaider3` and `open_exercise` in the URLs if your repo name or username differs).*

---

## 5. Release Keystore & Build Instructions

> **Keystore Status:** Created and configured in `android/upload-keystore.jks` and `android/key.properties` (both ignored by `.gitignore`).

### Keystore Credentials:
- **Location**: `android/upload-keystore.jks`
- **Alias**: `upload`
- **Store Password**: `OpenGymRelease2026!`
- **Key Password**: `OpenGymRelease2026!`
- **Config file**: `android/key.properties`

> [!CAUTION]
> **Backup this file:** Save `android/upload-keystore.jks` and passwords to a secure backup (password manager / private backup drive). If you lose this keystore, Google Play will NOT let you publish updates to the app.

### Build the Android App Bundle (AAB)
Run:

```bash
flutter build appbundle --release
```

Output file ready to upload to Play Console:
```text
build/app/outputs/bundle/release/app-release.aab
```

---

## 6. How the App Force Update Mechanism Works

The app automatically fetches [docs/version.json](docs/version.json) on launch:

```json
{
  "latest_version": "1.0.0",
  "latest_build_number": 1,
  "min_supported_version": "1.0.0",
  "min_supported_build_number": 1,
  "force_update": false,
  "update_url": "https://play.google.com/store/apps/details?id=io.github.moyeenhaider3.opengym",
  "title": "Update Available",
  "message": "A new version of OpenGym is available. Please update to continue."
}
```

### When releasing an optional update:
1. Bump `version: 1.0.1+2` in `pubspec.yaml`.
2. Update `docs/version.json`:
   - Set `"latest_version": "1.0.1"`, `"latest_build_number": 2`.
   - Leave `"min_supported_build_number": 1` and `"force_update": false`.
3. Push to `main`. Users on build `1` will see a gentle update reminder with a **"Later"** button.

### When forcing an update (blocking older versions):
1. In `docs/version.json`, set:
   - `"min_supported_build_number": 2`
   - `"force_update": true`
2. Push to `main`. Users on build `1` will receive a non-dismissible modal directing them to Google Play to update before continuing.
