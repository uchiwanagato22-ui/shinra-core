# SHINRA CORE v27 - Documentation Index

## 📚 Quick Navigation

### For Users (First-Time Users - START HERE)
1. **[INSTALL_LAUNCH.md](INSTALL_LAUNCH.md)** ← Start here!
   - How to install Flutter
   - How to launch the app
   - Troubleshooting setup issues

2. **[GUIDE_FR.md](GUIDE_FR.md)** (French)
   - 5-minute quick start tutorial
   - How to create a character
   - How to use animations
   - How to export to TikTok/YouTube
   - Tips and tricks

### For Developers (Technical Details)
1. **[README_v27.md](README_v27.md)**
   - Complete technical documentation
   - Feature overview
   - Project structure
   - API reference
   - Troubleshooting for developers

2. **[V27_CHANGES_SUMMARY.txt](V27_CHANGES_SUMMARY.txt)**
   - What's new in v27
   - File-by-file changes
   - New services added
   - Known limitations

3. **[CHECKLIST_v27.md](CHECKLIST_v27.md)**
   - Implementation status
   - What's completed, what's planned
   - Testing matrix
   - Deployment checklist
   - Contributing opportunities

---

## 🎯 Use Case Guide

### "I want to use the app (non-developer)"
→ Read [INSTALL_LAUNCH.md](INSTALL_LAUNCH.md) then [GUIDE_FR.md](GUIDE_FR.md)

### "I want to understand the code"
→ Read [README_v27.md](README_v27.md) then explore `lib/` folder

### "I want to contribute or extend it"
→ Read [CHECKLIST_v27.md](CHECKLIST_v27.md) for roadmap, then [README_v27.md](README_v27.md) for code

### "I want to deploy/release it"
→ Read [INSTALL_LAUNCH.md](INSTALL_LAUNCH.md) "Build for Production" section

### "I'm having issues"
→ Check the troubleshooting section in [INSTALL_LAUNCH.md](INSTALL_LAUNCH.md) or [README_v27.md](README_v27.md)

---

## 📁 File Structure

```
shinra_core/
├── 📄 INSTALL_LAUNCH.md          ← How to set up and run
├── 📄 GUIDE_FR.md                 ← User guide (French)
├── 📄 README_v27.md               ← Technical docs
├── 📄 CHECKLIST_v27.md            ← Roadmap & status
├── 📄 V27_CHANGES_SUMMARY.txt     ← What's new
├── 📄 README.md                   ← Original v26 docs
├── 📄 README_INDEX.md             ← This file
│
├── pubspec.yaml                   ← Dependencies
├── pubspec.lock                   ← Locked versions
│
├── lib/
│   ├── main.dart                  ← App entry point & pages
│   ├── models/
│   │   └── rig.dart               ← Data structures (Bone, Character, Animation)
│   ├── services/
│   │   ├── animation_library.dart  ← 40+ animations (NEW v27)
│   │   ├── video_export.dart       ← MP4/PNG/GIF export (NEW v27)
│   │   ├── image_upload_service.dart ← Image import & processing (NEW v27)
│   │   ├── export_handler.dart     ← Export UI (NEW v27)
│   │   ├── ai_director.dart        ← AI features
│   │   ├── audio_cue_service.dart  ← Sound effects
│   │   ├── gif_export.dart         ← GIF encoding
│   │   └── project_store.dart      ← Save/load
│   └── widgets/
│       ├── viewport.dart           ← Rendering engine
│       └── draw_canvas.dart        ← Drawing tool
│
├── assets/
│   ├── characters/                ← Character asset library
│   ├── animations/                ← Animation data
│   ├── expressions/               ← Facial expressions
│   ├── effects/                   ← VFX assets
│   └── audio/                     ← Sound files
│
├── android/                       ← Android build files
├── ios/                          ← iOS build files
├── web/                          ← Web build files
├── windows/                      ← Windows build files
├── macos/                        ← macOS build files
├── linux/                        ← Linux build files
│
└── test/                         ← Unit & integration tests
```

---

## 🎯 Feature Overview

### v27 Includes:
✅ Character customization (5000+ combinations)
✅ 40+ animation presets (movement, combat, facial, FX)
✅ Timeline-based animation editing
✅ Export to TikTok (9:16), YouTube (16:9), GIF
✅ Image upload & automatic segmentation
✅ Image processing (tint, brightness, flip, etc.)
✅ Undo/Redo
✅ Project save/load
✅ Scene studio (characters + effects)
✅ AI Director (text-to-timeline planning)
✅ Drawing canvas
✅ Dark theme (SHINRA branding)

### NOT in v27 (Planned for v28+):
❌ ML-based image segmentation (heuristic currently)
❌ Lip sync with audio (cue markers only)
❌ IK solver (FK only currently)
❌ Native MP4 encoder (frame sequence export only)
❌ Collaboration tools
❌ Cloud sync

---

## 🚀 Quick Start

### 1. Install
```bash
cd shinra_core
flutter pub get
```

### 2. Run
```bash
flutter run
```

### 3. Create something
- Character Creator → Customize your character
- Library → Select animation
- Animate → Play and edit
- Export → Choose format
- Share → Upload to TikTok/YouTube

### 4. Read the docs
- [GUIDE_FR.md](GUIDE_FR.md) for user tutorial (French)
- [README_v27.md](README_v27.md) for technical details

---

## 📊 Documentation Stats

| Document | Type | Pages | Focus |
|----------|------|-------|-------|
| [INSTALL_LAUNCH.md](INSTALL_LAUNCH.md) | Setup | 8 | Installation & launch |
| [GUIDE_FR.md](GUIDE_FR.md) | User | 9 | How to use the app |
| [README_v27.md](README_v27.md) | Technical | 10 | Code & API |
| [CHECKLIST_v27.md](CHECKLIST_v27.md) | Planning | 7 | Roadmap & status |
| [V27_CHANGES_SUMMARY.txt](V27_CHANGES_SUMMARY.txt) | Summary | 12 | What's changed |

**Total: ~46 pages of documentation**

---

## 🎓 Learning Path

### Beginner (New to the app)
1. Read [INSTALL_LAUNCH.md](INSTALL_LAUNCH.md) - 10 min
2. Read [GUIDE_FR.md](GUIDE_FR.md) - 20 min
3. Launch app and follow tutorial - 15 min
4. Create your first character & animation - 30 min
5. Export to GIF - 5 min

**Total: ~80 minutes to first animation** ⏱️

### Intermediate (Want to extend features)
1. Read [README_v27.md](README_v27.md) - 20 min
2. Explore `lib/services/` folder - 30 min
3. Read one service file (`animation_library.dart`) - 15 min
4. Modify or add a new animation - 30 min
5. Test it in the app - 15 min

**Total: ~110 minutes to first code contribution** ⏱️

### Advanced (Want to fork or deploy)
1. Read [CHECKLIST_v27.md](CHECKLIST_v27.md) - 15 min
2. Read entire [README_v27.md](README_v27.md) + source code - 60 min
3. Set up development environment - 30 min
4. Build release APK/iOS - 20 min
5. Deploy to app stores - 30 min

**Total: ~155 minutes to full deployment** ⏱️

---

## 📞 FAQ

**Q: Where do I start?**
A: [INSTALL_LAUNCH.md](INSTALL_LAUNCH.md)

**Q: How do I use the app?**
A: [GUIDE_FR.md](GUIDE_FR.md) (in French)

**Q: How does the code work?**
A: [README_v27.md](README_v27.md)

**Q: What's new in v27?**
A: [V27_CHANGES_SUMMARY.txt](V27_CHANGES_SUMMARY.txt)

**Q: What's planned next?**
A: [CHECKLIST_v27.md](CHECKLIST_v27.md)

**Q: Why is MP4 export not working?**
A: See "Known Limitations" in [README_v27.md](README_v27.md)

**Q: How do I contribute?**
A: See "Contributing" in [CHECKLIST_v27.md](CHECKLIST_v27.md)

**Q: Can I use this commercially?**
A: Check LICENSE.md (not included yet - contact developers)

---

## 🔗 External Resources

- **Flutter**: https://flutter.dev
- **Dart**: https://dart.dev
- **Material Design**: https://m3.material.io
- **Image Processing**: https://pub.dev/packages/image
- **State Management**: https://pub.dev/packages/provider

---

## 📝 Version Info

- **Current Version**: v27.0
- **Status**: Release Candidate (Feature Complete)
- **Release Date**: 2026-09-11
- **Next Release**: v27.1 (Patch) or v28 (Major)

---

## 🎁 What You Get

When you download `shinra_core_v27_complete.zip`:

✅ Full source code (Flutter)
✅ All documentation (5 files)
✅ Asset library (characters, animations, FX)
✅ Example projects (ready to run)
✅ Build configurations (Android, iOS, Web, Desktop)
✅ Dependency manifest (pubspec.yaml)
✅ Git history (if cloned)

**Everything you need to:**
- Use the app immediately
- Understand how it works
- Extend with custom features
- Deploy to app stores

---

## 🎯 Success Criteria

You've successfully set up when:
- ✅ `flutter run` launches the app
- ✅ App shows home page with feature cards
- ✅ You can navigate all pages
- ✅ You can create a character
- ✅ You can play an animation
- ✅ You can export a GIF

If all above are working, **you're ready!** 🎉

---

## 🚨 Important Notes

- **This is v27**, not v1. It's feature-complete but still in active development.
- **MP4 export** is partially implemented (creates PNG sequence). Full MP4 requires ffmpeg.
- **Mobile optimization** is ongoing. Desktop experience is smoother.
- **All code is open source** and documented for educational/commercial use.

---

## 📚 Reading Order (Recommended)

1. This file (README_INDEX.md) - 5 min - Overview
2. [INSTALL_LAUNCH.md](INSTALL_LAUNCH.md) - 10 min - Get it running
3. [GUIDE_FR.md](GUIDE_FR.md) - 20 min - Learn to use it
4. [README_v27.md](README_v27.md) - 20 min - Understand the code
5. [CHECKLIST_v27.md](CHECKLIST_v27.md) - 10 min - See the roadmap
6. [V27_CHANGES_SUMMARY.txt](V27_CHANGES_SUMMARY.txt) - 10 min - Detailed changes

**Total reading time: ~75 minutes**

Then: Launch the app and start animating! 🎬✨

---

## 🎉 Ready?

Pick a document above and start reading!

**Recommended entry point for new users:**
→ [INSTALL_LAUNCH.md](INSTALL_LAUNCH.md)

**Recommended entry point for developers:**
→ [README_v27.md](README_v27.md)

---

**Last Updated**: 2026-09-11  
**Maintained by**: SHINRA CORE Development Team  
**Questions?** Open an issue on GitHub
