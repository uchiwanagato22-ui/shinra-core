# SHINRA CORE v27 - Animation Duration Guide

## ❓ "How long can I create animations?"

Short answer: **Technically unlimited, practically 10-60 minutes per animation**

---

## 📊 Duration Limits by Device

### **Desktop (Windows/macOS/Linux)**
- **Max single animation**: 60+ minutes
- **Smooth playback**: 30+ FPS
- **Recommended**: 10-20 minute animations for best performance
- **Export limit**: ~500MB MP4 file (adjust with resolution/FPS)

### **Mobile (Android/iOS)**
- **Max single animation**: 5-10 minutes
- **Smooth playback**: 24+ FPS
- **Recommended**: 1-5 minute animations
- **Export limit**: ~100MB MP4 (mobile storage constraint)
- **RAM limit**: ~2GB available = ~50,000 keyframes max

### **Web (Browser)**
- **Max single animation**: 5 minutes
- **Smooth playback**: 24+ FPS (depends on browser)
- **Recommended**: 1-3 minute animations
- **Memory**: Limited by browser tab memory (~500MB)

---

## 🎬 Practical Duration Examples

### Example 1: Walk Cycle
- **Duration**: 1.2 seconds
- **Keyframes**: 9 per bone, 5 bones = 45 total
- **File size**: ~2 KB JSON
- **Practical use**: Loop 50 times = 1 minute walking
- **Export time**: ~30 seconds (GIF) / ~3 minutes (MP4)

### Example 2: Combat Sequence
- **Duration**: 10 seconds
- **Keyframes**: Punch (0.4s) + Kick (0.5s) + Punch (0.4s) + Jump (0.6s) + Land (0.4s) = 5 keyframes per bone
- **File size**: ~5 KB JSON
- **Export time**: ~60 seconds

### Example 3: Long Story Scene
- **Duration**: 60 seconds
- **Keyframes**: ~20 per bone, 10 bones = 200 total
- **File size**: ~50 KB JSON
- **Export time**: Desktop: ~2 minutes | Mobile: ~5 minutes

### Example 4: Full Episode
- **Duration**: 10 minutes (600 seconds)
- **Keyframes**: ~100 per bone, 10 bones = 1,000 total
- **File size**: ~500 KB JSON
- **Export time**: Desktop: ~15 minutes | Mobile: SLOW (not recommended)
- **Note**: Better to split into 3-4 scenes exported separately

---

## ⚡ Performance Factors

### What INCREASES animation duration capacity:
✅ Fewer bones (3-5 instead of 10+)
✅ Lower FPS export (12 or 24 instead of 60)
✅ Smaller resolution (480p instead of 1080p)
✅ Desktop device (vs mobile)
✅ Loop animations (no duplicate keyframes)
✅ Simpler interpolation (linear vs spline)

### What DECREASES animation duration capacity:
❌ More bones (20+ bones)
❌ More keyframes (100+ per bone)
❌ Higher FPS export (60 FPS)
❌ Higher resolution (4K)
❌ Mobile device
❌ Complex particles/effects
❌ Multiple layers/characters

---

## 🎯 Recommended Durations by Use Case

| Use Case | Recommended | Max | Device |
|----------|-------------|-----|--------|
| Walk cycle (loop) | 1-2s | 10s | All |
| Combat combo | 5-10s | 30s | All |
| Short dance | 15-30s | 60s | All |
| Full dance | 30s-2m | 5m | Desktop |
| TikTok video | 15-60s | 180s | All |
| YouTube Short | 15-60s | 180s | All |
| YouTube video | 1-10m | 20m | Desktop |
| Full episode | 10-30m | 60m | Desktop only |

---

## 💾 File Size Reference

### JSON Animation File Sizes
```
Walk cycle (1.2s):      ~2 KB
Punch combo (10s):      ~5 KB
Story scene (60s):      ~50 KB
Full episode (10m):     ~500 KB
```

### Export File Sizes (1 minute @ 30 FPS)
```
GIF (1080x1920):        ~20-50 MB
PNG Sequence:           ~500 MB (60 × PNG frames)
MP4 (1080x1920, H.264): ~50-100 MB
MP4 (1280x720, H.264):  ~30-50 MB
```

### Export Times (1 minute @ 30 FPS)
```
Device:         GIF         MP4         PNG Seq
Desktop:        2-5 min     5-10 min    10-20 min
Mobile:         5-10 min    15-30 min   Not recommended
Web:            3-8 min     10-20 min   Not recommended
```

---

## 🚀 How to Maximize Duration

### Option 1: Use Multiple Scenes (Recommended)
```
Episode = Scene 1 (1 min) + Scene 2 (1 min) + Scene 3 (1 min)
Export each separately → Combine in video editor
Total: 3 minutes with fast export
```

### Option 2: Optimize Settings
```
Desktop → 10 min animation
├─ Resolution: 1080x1920
├─ FPS: 24 (not 60)
├─ Bones: 5-8 (not 20+)
└─ Keyframes: ~50 per bone
```

### Option 3: Loop Animations
```
Walk (1.2s) × 50 = 60 seconds
Animation file: 2 KB (stays small)
Export file: 50-100 MB (same as 1-min animation)
Export time: ~3 minutes
```

---

## 🔴 Limits You'll Hit

### Keyboard/Timeline Limits
- Max 1,000,000 keyframes per project ✅ (rarely hit)
- Max 100 bones in rig ✅ (plenty)
- Max 100 animation clips ✅ (plenty)

### Export Limits
- Max file size: System dependent (typically 2-4 GB)
- Max video duration: Unlimited
- Max resolution: 4K (3840×2160) - but may lag

### Memory Limits
- Desktop: ~4-8 GB available
- Mobile: ~2 GB available
- Web: ~500 MB per tab

### Performance Limits
- Desktop: 60+ FPS with ~10 min animation @ 1080p
- Mobile: 24 FPS with ~1 min animation @ 720p
- Web: 24 FPS with ~1-3 min animation @ 720p

---

## ✅ Best Practices

### For Maximum Duration
```dart
// Use these settings:
animation.duration = 600; // 10 minutes
fps = 24; // Lower FPS = faster export
resolution = '1280x720'; // Smaller = faster
keyframes_per_bone = 50; // Reasonable amount
bones_count = 8; // Not too many
device = 'desktop'; // Fastest export
```

### For Fastest Export
```dart
// Use these settings:
animation.duration = 60; // 1 minute
fps = 12; // Very fast export
resolution = '854x480'; // Small
keyframes_per_bone = 20;
bones_count = 5;
```

### For Best Quality
```dart
// Use these settings:
animation.duration = 30; // Keep it short
fps = 60; // Highest quality
resolution = '1920x1080'; // Full HD
keyframes_per_bone = 100; // Lots of detail
bones_count = 10; // Complex character
device = 'desktop'; // Best performance
```

---

## 📈 Timeline Recommendations

### Short-form Content (TikTok, Reels)
- **Duration**: 15-60 seconds
- **FPS**: 30
- **Resolution**: 1080×1920
- **Export time**: 30 seconds - 2 minutes
- **Device**: Mobile OK

### Medium-form Content (YouTube Shorts)
- **Duration**: 15-180 seconds
- **FPS**: 30
- **Resolution**: 1080×1920
- **Export time**: 1-5 minutes
- **Device**: Mobile OK (prefer desktop)

### Long-form Content (YouTube Videos)
- **Duration**: 1-10 minutes per scene
- **FPS**: 24-30
- **Resolution**: 1920×1080
- **Export time**: 5-30 minutes
- **Device**: Desktop ONLY

### Full Episodes/Series
- **Duration**: 10-30 minutes
- **FPS**: 24
- **Resolution**: 1280×720 or 1920×1080
- **Export time**: 30+ minutes
- **Device**: Desktop with 4+ GB RAM
- **Strategy**: Split into 3-4 scenes

---

## 🎯 Pro Tips

1. **Don't go overboard with duration**
   - Most animations are 1-5 minutes
   - Shorter = better engagement on social media
   - Longer = harder to keep attention

2. **Test export times early**
   - Export a 10-second clip first
   - Measure actual time
   - Calculate for full duration
   - Example: 10s takes 30 sec → 1 min takes 3 min

3. **Use looping wisely**
   - Walking cycle (1.2s looped) = compact file
   - Full story (no loop) = requires more keyframes

4. **Split long animations**
   - Episode 1: 0-5 minutes
   - Episode 2: 5-10 minutes
   - Episode 3: 10-15 minutes
   - Combine in video editor

5. **Backup project files**
   - Large projects (1000+ keyframes) are valuable
   - Save regularly
   - Version control (.shinra files)

---

## 🔧 Debug Performance

### Is my animation too slow?

```
If FPS drops below 24 during playback:
1. Check keyframe count: flutter logs | grep keyframes
2. Reduce bones: Use 5-8 instead of 15+
3. Reduce keyframes: Increase time between keyframes
4. Disable effects: Turn off particles/shadows
5. Lower resolution: Use 720p instead of 1080p
```

### Is my export too slow?

```
If export takes >10 minutes for 1 minute animation:
1. Reduce FPS: Try 24 instead of 30
2. Reduce resolution: Try 720p instead of 1080p
3. Switch to GIF: Often faster than MP4
4. Split animation: Export 3 × 20s instead of 1 × 60s
5. Restart app: Clears memory cache
```

---

## 📚 Summary Table

```
Duration  | Keyframes | File Size | Desktop | Mobile | Export Time
          | per Bone  |           | Export  | Export | (Desktop)
----------|-----------|-----------|---------|--------|------------
1 second  | 3-5       | <1 KB     | ✅✅✅  | ✅✅✅ | 2-5 sec
10 sec    | 5-10      | 1-5 KB    | ✅✅✅  | ✅✅✅ | 10-30 sec
30 sec    | 10-20     | 5-10 KB   | ✅✅✅  | ✅✅   | 30-90 sec
1 min     | 20-50     | 10-50 KB  | ✅✅✅  | ✅✅   | 1-3 min
5 min     | 50-100    | 50-100 KB | ✅✅   | ✅     | 5-15 min
10 min    | 100-200   | 100-500KB | ✅     | ❌     | 15-30 min
30 min    | 200-500   | 500KB-1MB | ⚠️     | ❌     | 30-60 min
60 min    | 500-1000  | 1-2 MB    | ⚠️     | ❌     | 60-120 min
```

Legend: ✅✅✅ = Very smooth | ✅✅ = Smooth | ✅ = Acceptable | ⚠️ = Slow | ❌ = Not recommended

---

## 🎬 Real-World Example

### "I want to create a 5-minute anime"

```
Step 1: Split into scenes
├─ Scene 1: Character intro (30s)
├─ Scene 2: Walking sequence (1m)
├─ Scene 3: Action sequence (1.5m)
└─ Scene 4: Ending (1m)

Step 2: Create animations
├─ Scene 1: 30s, 20 keyframes per bone
├─ Scene 2: 60s, 50 keyframes per bone (walk loop × 50)
├─ Scene 3: 90s, 100 keyframes per bone (complex)
└─ Scene 4: 60s, 30 keyframes per bone

Step 3: Export
├─ Scene 1: 1 minute export
├─ Scene 2: 2 minutes export
├─ Scene 3: 3 minutes export
└─ Scene 4: 2 minutes export
Total: ~8 minutes

Step 4: Combine in DaVinci Resolve or Adobe Premiere
Result: 5-minute anime ready for YouTube! 🎉
```

---

## 💡 Final Answer

**"How many seconds can I create?"**

- **Practically**: 1 second to 60 minutes per animation
- **Realistically**: 
  - Desktop: Up to 10-20 minutes
  - Mobile: Up to 5-10 minutes
  - Web: Up to 1-5 minutes
- **Recommended**:
  - TikTok: 15-60 seconds
  - YouTube: 1-10 minutes per scene
  - Full episode: Split into 2-4 scenes
- **Performance**: Playback stays smooth up to 60 minutes on desktop with optimization

**Go create! 🎬✨**

---

**Last Updated**: 2026-09-11  
**Version**: v27 (Duration Guide)
