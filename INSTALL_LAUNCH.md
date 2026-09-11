# SHINRA CORE v27 - Installation & Launch Guide

## 🎯 TL;DR

```bash
cd shinra_core
flutter pub get
flutter run
```

That's it! The app will launch.

---

## 📋 Prerequisites

You need:
1. **Flutter SDK** (3.3.0 or higher)
   - Download: https://flutter.dev/docs/get-started/install
   - Verify: `flutter --version`

2. **Platform Setup**
   - **Android**: Android Studio + SDK 26+ (Android 8.0+)
   - **iOS**: Xcode + iOS 13.0+ (macOS only)
   - **Windows**: Visual Studio or build tools
   - **Web**: Any browser (Chrome recommended)

3. **Git** (optional, but recommended)
   - For version control and updates

---

## 🚀 Full Installation Steps

### Step 1: Extract v27

```bash
# Download shinra_core_v27_complete.zip
# Extract to your working directory
unzip shinra_core_v27_complete.zip
cd shinra_core
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

This downloads all required packages:
- provider (state management)
- image (image processing)
- image_picker (file selection)
- audioplayers (sound)
- path_provider (file storage)
- shared_preferences (project save)

### Step 3: Verify Setup

```bash
flutter doctor
```

Expected output:
```
✓ Flutter (Channel stable, ...)
✓ Android toolchain
✓ Xcode (iOS only)
✓ VS Code / Android Studio (IDE)
✓ Connected devices (1 device available)
```

If any `✗`, follow the messages to fix them.

### Step 4: Analyze Code (Optional)

```bash
flutter analyze
```

Should show no errors (only warnings about unused imports are OK).

---

## ▶️ Running the App

### On Android Device or Emulator

```bash
flutter run
```

- First run: ~2-3 minutes (builds APK)
- Subsequent runs: ~30 seconds
- Hot reload: Press `r` in terminal to reload without rebuilding

### On iOS Device or Simulator (macOS only)

```bash
flutter run -d ios
```

### On Windows/macOS Desktop

```bash
flutter run -d windows
# or
flutter run -d macos
```

### On Web (Browser)

```bash
flutter run -d web
```

Opens in Chrome at `http://localhost:56123`

---

## 🎮 Using the App

### First Launch
1. App opens on **Home** page
2. Click a feature card to navigate (e.g., "Character Creator")
3. Use the left sidebar to switch pages anytime

### Quick Workflow
1. **Character Creator** → Customize appearance
2. **Library** → Select animation
3. **Animate** → Preview/edit timeline
4. **Export** → Choose format (TikTok/YouTube/GIF)
5. **Share** → Upload to social media

### Keyboard Shortcuts
- `r` = Hot reload
- `R` = Hot restart
- `q` = Quit

---

## 🐛 Troubleshooting Setup

### "Flutter not found"
```bash
# Add Flutter to PATH
# On Windows: Add C:\flutter\bin to System Environment Variables
# On macOS/Linux: Add to ~/.bashrc or ~/.zshrc:
#   export PATH="$PATH:/path/to/flutter/bin"
```

### "Android SDK not found"
```bash
flutter config --android-sdk /path/to/android/sdk
# or run Android Studio and let it install SDK
```

### "Build failed: permission denied"
```bash
# Ensure you have write permissions in the project folder
chmod -R u+w shinra_core/  # macOS/Linux
```

### "Gradle build error"
```bash
flutter clean
flutter pub get
flutter run
```

### "Out of memory during build"
```bash
# Increase Gradle memory
export GRADLE_OPTS="-Xmx2048m"
flutter run
```

### "Device not found"
```bash
# List available devices
flutter devices

# If emulator not running, start it:
emulator -avd Pixel_4  # Android
# or launch Xcode simulator (iOS)
```

---

## 📊 Expected Performance

| Device | First Run | Subsequent | Hot Reload |
|--------|-----------|------------|-----------|
| Mobile | 2-3 min | 30-60s | 2-5s |
| Desktop | 1-2 min | 20-40s | 1-2s |
| Web | 30-60s | 10-20s | <1s |

If your device is slower, it might be due to:
- Slow SSD/HDD (wait longer)
- Weak CPU (use release build instead of debug)
- Limited RAM (<2GB)

---

## 🔨 Build for Production

### APK for Android (Play Store)
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### App Bundle (Android)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS App (TestFlight / App Store)
```bash
flutter build ios --release
# Follow xcode prompts to upload
```

### Windows Executable
```bash
flutter build windows --release
# Output: build/windows/runner/Release/
```

### macOS App
```bash
flutter build macos --release
# Output: build/macos/Build/Products/Release/
```

### Web App
```bash
flutter build web --release
# Output: build/web/
# Upload to any web host (Vercel, Netlify, GitHub Pages, etc.)
```

---

## 📱 Device Support

### Tested & Verified
- ✅ Android 8.0+ (Pixel, Samsung, etc.)
- ✅ iOS 13.0+ (iPhone 8+)
- ✅ Windows 10/11
- ✅ macOS 10.15+
- ✅ Web (Chrome, Edge, Firefox)

### Should Work (Not Tested)
- ? Linux (Ubuntu, Fedora, etc.)
- ? Older Android 6-7
- ? Older iOS

### Unlikely to Work
- ✗ iOS <12
- ✗ Android <6

---

## 🔧 Advanced Configuration

### Custom Dart Version
```bash
flutter downgrade 3.3.0  # Use specific version
```

### Enable Impeller (GPU Acceleration)
```bash
# Add to android/app/build.gradle:
flutter {
    compileSdkVersion 34
    minSdkVersion 26
    targetSdkVersion 34
}

# Or via command line:
flutter run --enable-impeller
```

### Disable Analytics
```bash
flutter config --no-analytics
```

### Use Different Channel (Beta, Dev, Master)
```bash
flutter channel beta
flutter upgrade
flutter run
```

---

## 📚 Documentation Links

- **Official Flutter Docs**: https://flutter.dev/docs
- **Material Design 3**: https://m3.material.io
- **Dart Language**: https://dart.dev
- **This Project Docs**: 
  - README_v27.md (technical)
  - GUIDE_FR.md (user guide in French)
  - CHECKLIST_v27.md (development roadmap)

---

## 💾 File Structure After Setup

```
shinra_core/
├── .dart_tool/              (Generated - ignore)
├── android/                 (Android build files)
├── build/                   (Generated - ignore)
├── ios/                     (iOS build files)
├── lib/
│   ├── main.dart
│   ├── models/
│   ├── services/            (NEW: animation, export, image)
│   └── widgets/
├── assets/
│   ├── characters/
│   ├── animations/
│   └── ...
├── test/
├── web/                     (Web build files)
├── pubspec.yaml
├── pubspec.lock             (Locked versions)
├── README_v27.md
├── GUIDE_FR.md
├── CHECKLIST_v27.md
└── V27_CHANGES_SUMMARY.txt
```

---

## 🎉 Success!

If the app launches and shows the home page with:
- "SHINRA CORE" title
- Grid of feature cards (Character, Library, Animate, Export, etc.)
- Left sidebar navigation

**You're ready to animate!** 🎬✨

---

## 📞 Getting Help

1. **Check the docs**
   - README_v27.md (technical)
   - GUIDE_FR.md (user guide)
   - V27_CHANGES_SUMMARY.txt (what's new)

2. **Debug the app**
   - Look at terminal output for errors
   - Use `flutter logs` to see app logs
   - Check `build/` folder for build artifacts

3. **Common Issues**
   - Delete `pubspec.lock` and run `flutter pub get` again
   - Run `flutter clean && flutter pub get && flutter run`
   - Restart IDE/terminal

4. **Report Bugs**
   - Check CHECKLIST_v27.md for known issues
   - Open GitHub issue with error message

---

## 🚀 Next Steps

After successful launch:

1. **Create a character**
   - Character Creator page
   - Customize appearance
   - Save project

2. **Try animations**
   - Library page
   - Select "Walk Forward"
   - Preview on timeline

3. **Export your first video**
   - Export page
   - Choose "GIF" (easiest, no external tools needed)
   - Click Export
   - Video saved to Downloads/

4. **Share online**
   - TikTok: Use TikTok export format
   - YouTube: Use YouTube export format
   - Discord/Twitter: Share GIF directly

5. **Keep exploring**
   - Try Face expressions
   - Add FX (particles, effects)
   - Build complex scenes

---

## 📞 Support

- **Documentation**: Check GUIDE_FR.md (French) or README_v27.md (English)
- **Bugs**: Open issue on GitHub
- **Feature Requests**: GitHub Discussions
- **Questions**: GitHub Issues with [QUESTION] tag

---

**Happy animating! 🎬✨**

For questions, visit: https://github.com/shinra-core/issues

---

Last Updated: 2026-09-11  
Version: v27.0 (Release Candidate)
