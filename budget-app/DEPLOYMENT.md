# SafeSpend - App Store & Play Store Deployment Guide

Your app is now configured for deployment to both the **Apple App Store** and **Google Play Store** using Capacitor.

## Project Structure

```
budget-app/
├── android/          # Android native project (Android Studio)
├── ios/              # iOS native project (Xcode)
├── dist/             # Built web assets
├── src/              # React source code
├── capacitor.config.ts
└── package.json
```

## App Configuration

- **App ID:** `com.safespend.budgetapp`
- **App Name:** SafeSpend
- **Web Directory:** `dist`

---

## Prerequisites

### For Android (Play Store)
1. **Android Studio** - Download from https://developer.android.com/studio
2. **Java JDK 17+** - Usually bundled with Android Studio
3. **Google Play Developer Account** - $25 one-time fee at https://play.google.com/console

### For iOS (App Store)
1. **macOS** - Required for iOS development
2. **Xcode** - Download from Mac App Store
3. **Apple Developer Account** - $99/year at https://developer.apple.com
4. **CocoaPods** - Install via `sudo gem install cocoapods`

---

## Build & Deploy Workflow

### Step 1: Build Web Assets
```bash
npm run build
```

### Step 2: Sync to Native Projects
```bash
npx cap sync
```

### Step 3: Open in Native IDE

**For Android:**
```bash
npx cap open android
```
This opens Android Studio. From there:
1. Wait for Gradle sync to complete
2. Build > Generate Signed Bundle / APK
3. Create a keystore (first time) or use existing
4. Build release AAB file
5. Upload to Google Play Console

**For iOS:**
```bash
npx cap open ios
```
This opens Xcode. From there:
1. Select your Team in Signing & Capabilities
2. Product > Archive
3. Distribute App > App Store Connect
4. Upload to App Store Connect

---

## Development Commands

```bash
# Run on Android device/emulator
npx cap run android

# Run on iOS device/simulator (macOS only)
npx cap run ios

# Live reload during development
npx cap run android --livereload --external
npx cap run ios --livereload --external
```

---

## App Icons & Splash Screens

You'll need to add app icons and splash screens:

### Android
Place icons in: `android/app/src/main/res/`
- `mipmap-mdpi/` (48x48)
- `mipmap-hdpi/` (72x72)
- `mipmap-xhdpi/` (96x96)
- `mipmap-xxhdpi/` (144x144)
- `mipmap-xxxhdpi/` (192x192)

### iOS
Open Xcode and add icons to: `App/App/Assets.xcassets/AppIcon.appiconset/`

### Recommended Tool
Use **capacitor-assets** to auto-generate all sizes:
```bash
npm install @capacitor/assets --save-dev
npx capacitor-assets generate
```

---

## Plugins You May Want to Add

```bash
# Push Notifications
npm install @capacitor/push-notifications

# In-App Purchases (for subscriptions)
npm install cordova-plugin-purchase

# Haptic Feedback
npm install @capacitor/haptics

# Status Bar Control
npm install @capacitor/status-bar

# Splash Screen
npm install @capacitor/splash-screen
```

After installing plugins, run:
```bash
npx cap sync
```

---

## Store Submission Checklist

### Google Play Store
- [ ] App icons (512x512 for store listing)
- [ ] Feature graphic (1024x500)
- [ ] Screenshots (phone & tablet)
- [ ] Privacy policy URL
- [ ] App description
- [ ] Content rating questionnaire
- [ ] Signed AAB file

### Apple App Store
- [ ] App icons (1024x1024 for store)
- [ ] Screenshots (all device sizes)
- [ ] Privacy policy URL
- [ ] App description
- [ ] App Review information
- [ ] Export compliance
- [ ] Age rating

---

## Troubleshooting

### Android Build Issues
```bash
# Clean and rebuild
cd android && ./gradlew clean && cd ..
npx cap sync android
```

### iOS Build Issues
```bash
# Update pods
cd ios/App && pod install --repo-update && cd ../..
npx cap sync ios
```

### General
```bash
# Check Capacitor doctor
npx cap doctor
```

---

## Next Steps

1. **Install Android Studio** to build and test the Android app
2. **Get a Mac with Xcode** for iOS development (required by Apple)
3. **Create developer accounts** on both stores
4. **Design app icons** (1024x1024 master, will be resized)
5. **Prepare store listings** (descriptions, screenshots, etc.)
6. **Test thoroughly** on real devices before submission

---

## Useful Links

- [Capacitor Documentation](https://capacitorjs.com/docs)
- [Google Play Console](https://play.google.com/console)
- [Apple App Store Connect](https://appstoreconnect.apple.com)
- [Capacitor Android Guide](https://capacitorjs.com/docs/android)
- [Capacitor iOS Guide](https://capacitorjs.com/docs/ios)
