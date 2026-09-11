# SHINRA CORE v27 - Guide Rapide 🎬

## 🎯 Résumé

Shinra Core est une **app complète** pour :
1. ✅ Créer un personnage anime personnalisé
2. ✅ L'animer avec des mouvements prêts ou customisés
3. ✅ Exporter en vidéo (TikTok, YouTube, GIF)
4. ✅ Importer et animer ses propres images

**Pas de limite** : Créez autant de personnages et d'animations que vous voulez.

---

## 📦 Quoi de Nouveau en v27

| Fonctionnalité | v26 | v27 |
|---|---|---|
| Créateur de personnage | ✅ | ✅ Plus de couleurs |
| Animation presets | ❌ | ✅ **40+ animations** |
| Export TikTok | ❌ | ✅ **Vertical 9:16** |
| Export YouTube | ❌ | ✅ **16:9** |
| Upload image + animer | ❌ | ✅ **Segmentation auto** |
| Dessin dans l'app | ✅ | ✅ |
| AI Director | ✅ | ✅ |
| Undo/Redo | ✅ | ✅ |

---

## 🚀 Démarrage Rapide (5 min)

### 1️⃣ Lancer l'app
```bash
cd shinra_core
flutter pub get
flutter run
```

### 2️⃣ Créer un personnage
- Aller sur **"Character Creator"**
- Choisir : couleur peau, coiffure, yeux, vêtements
- Cliquer "Apply" → voir le perso en direct

### 3️⃣ Animer le personnage
- Aller sur **"Library"** → Animations
- Cliquer sur un mouvement (ex: "Walk Forward")
- Cliquer "Use This Animation"
- Aller sur **"Animate"** → Timeline
- Cliquer **Play** pour voir l'animation
- Optionnel : Modifier les keyframes

### 4️⃣ Exporter la vidéo
- Aller sur **"Export"**
- Choisir le format :
  - **TikTok** → 9:16 vertical
  - **YouTube** → 16:9
  - **GIF** → tout format
- Régler FPS (30 = qualité max, 12 = petit fichier)
- Cliquer **Export**

### 5️⃣ Partager
- La vidéo est prête dans votre dossier **Téléchargements**
- Uploader sur **TikTok / YouTube / Instagram**

---

## 🎨 40+ Animations Prêtes

### Mouvements (12)
- **Idle** (1.5s) — En attente
- **Walk Forward** (1.2s) — Marche normale
- **Run Forward** (0.8s) — Course rapide
- **Jump** (0.6s) — Saut
- **Fall** (0.8s) — Chute
- **Crouch** (0.4s) — Accroupi
- **Wave** (1.0s) — Salut
- + 5 autres (backward, strafe, look around...)

### Combat (12)
- **Punch** (0.4s) — Coup direct
- **Kick** (0.5s) — Coup de pied
- **Combo Punch** (1.0s) — Double coup
- **Spin Kick** (0.7s) — Coup rotatif
- **Defend** (0.3s) — Défense
- **Dodge Left/Right** (0.3s) — Esquive
- **Energy Blast** (0.5s) — Vague d'énergie
- + 5 autres (knockdown, power charge...)

### Expressions (12)
- **Blink** (0.2s) — Clignement
- **Smile** (0.3s) — Sourire
- **Angry** (0.4s) — Colère
- **Shocked** (0.3s) — Choc
- **Talk** (1.0s) — Parler
- **Laugh** (1.0s) — Rire
- **Cry** (2.0s) — Pleurer
- + 5 autres

### Effets (12)
- **Fire Burst** (0.6s) — Explosion feu
- **Lightning** (0.3s) — Éclair
- **Smoke Cloud** (1.0s) — Nuage de fumée
- **Explosion** (0.8s) — Grosse explosion
- **Aura Glow** (2.0s, boucle) — Aura
- **Teleport** (0.3s) — Téléportation
- + 6 autres

---

## 📸 Upload Ton Image & Anime

### Étape 1 : Prépare l'image
- Photo ou dessin en PNG/JPG
- Idéal : personnage debout sur fond uni
- Résolution : 512x512 min, 2048x2048 max

### Étape 2 : Upload
- **Character Creator** → "Upload Image"
- Sélectionne ton image
- L'app la segmente auto en parties (tête, bras, jambes...)

### Étape 3 : Anime
- Sélectionne une animation de la Library
- Ton image suit le rig comme un perso procédural
- Les bras, jambes, tête bougent indépendamment ✨

### Étape 4 : Export
- Même process que avant
- Ta photo anime → TikTok 🎬

---

## 🎬 Format d'Export Détail

### TikTok (Recommandé pour la plateforme)
- **Résolution** : 1080x1920 px
- **Format** : Vertical (9:16)
- **FPS** : 30 (smooth) ou 24 (économe)
- **Durée max** : 10 min
- **Taille fichier** : ~50-200 MB

### YouTube
- **Résolution** : 1920x1080 px (Full HD)
- **Format** : Horizontal (16:9)
- **FPS** : 30 ou 60
- **Durée** : Illimitée
- **Taille fichier** : ~100-500 MB

### YouTube Shorts
- **Résolution** : 1080x1920 px
- **Format** : Vertical (9:16)
- **FPS** : 30
- **Durée** : 15-60s

### GIF
- **Résolution** : Auto (même que viewport)
- **Format** : Loopable
- **FPS** : 12-24 (fichier léger)
- **Taille fichier** : ~5-50 MB
- **Avantage** : Compatible partout, pas de son

### PNG Sequence
- **Output** : Dossier avec images numérotées (frame_0001.png, frame_0002.png...)
- **Usage** : Import dans Adobe Premiere, After Effects, DaVinci Resolve
- **Avantage** : Total contrôle en post-production

---

## 🎛️ Timeline Avancée

### Keyframes
```
Timeline : 0s ────── 0.5s ────── 1.0s ────── 1.5s
          [Start]    [Mid]      [End]      [Loop]
           ↓           ↓          ↓           ↓
Pose:    Leg -20°   Leg +20°    Leg -20°   Leg -20°
```

### Interpolation
- **Linear** : Mouvement constant (brut)
- **Ease-in** : Accélération
- **Ease-out** : Décélération
- **Spline** : Courbe lisse (naturel)

### Capture Keyframe
1. Modifier un os (rotation, position, échelle)
2. Cliquer **"Capture Keyframe"** à la frame voulue
3. Résultat : Keyframe créé à ce temps

### Blend Entre Animations
- Sélectionner 2 clips sur la timeline
- L'app crée une transition lisse (0.3s par défaut)

---

## 🤖 AI Director : Text-to-Timeline

### Exemple
```
Prompt : "Le personnage est immobile, puis marche en avant, lance 2 coups de poing, puis saute"

Résultat automatique :
├─ Idle (0s - 1.5s)
├─ Walk Forward (1.5s - 2.7s)
├─ Punch 1 (2.7s - 3.1s)
├─ Punch 2 (3.1s - 3.5s)
└─ Jump (3.5s - 4.1s)
```

### Comment utiliser
1. Aller sur **"AI Director"**
2. Écrire ce que tu veux voir
3. Cliquer **"Generate Timeline"**
4. Cliquer **"Preview"** pour voir
5. Si ça plaît : **"Apply to Animation"**

---

## 💾 Sauvegarder Ton Projet

### Auto-Save
- L'app sauvegarde auto tous les 30 secondes
- Localisation : App Storage

### Manual Save
- Menu **"File"** → **"Save Project"**
- Choisir un nom et un dossier
- Format : `.shinra` (JSON compressé)

### Load Project
- Menu **"File"** → **"Open Recent"**
- Ou glisser-déposer un `.shinra` dans l'app

---

## ⚡ Astuces Perfo

### Pour plus de FPS
- Réduire la résolution d'export
- Réduire le nombre de keyframes par animation
- Désactiver les ombres/particules pendant l'édition

### Pour moins de RAM
- Exporter en PNG Sequence plutôt qu'en MP4
- Fermer l'app entre les longs exports
- Réduire la durée des animations (couper en clips courts)

### Pour meilleure qualité
- Exporter en 60 FPS si la plateforme le supporte
- Utiliser résolution native de la plateforme
  - TikTok : 1080x1920
  - YouTube : 1920x1080

---

## 🐛 Troubleshooting

### "Export fails - frames not captured"
**Cause** : Viewport pas visible  
**Fix** : S'assurer que le viewport est à l'écran avant d'exporter

### "Animation looks choppy"
**Cause** : FPS trop bas  
**Fix** : Exporter en 30 FPS minimum

### "Image doesn't animate correctly"
**Cause** : Auto-segmentation mauvaise  
**Fix** : Uploader une image plus claire (fond uni)

### "Out of memory on mobile"
**Cause** : Fichier trop volumineux  
**Fix** :
- Exporter en 720p au lieu de 1080p
- Réduire FPS à 24
- Couper animation en 2 parties

### "Très lent sur Windows"
**Cause** : GPU pas utilisé  
**Fix** : S'assurer que Flutter utilise Impeller (cocher dans settings)

---

## 📚 Structure du Projet

```
shinra_core/
├── lib/
│   ├── main.dart                    # App UI
│   ├── models/
│   │   └── rig.dart                 # Data (Bone, Character, Animation)
│   ├── services/
│   │   ├── animation_library.dart    # 40+ presets
│   │   ├── video_export.dart         # MP4/PNG/GIF
│   │   ├── image_upload_service.dart # Import image
│   │   ├── export_handler.dart       # Export UI
│   │   ├── ai_director.dart          # Text→Timeline
│   │   └── ...
│   └── widgets/
│       ├── viewport.dart             # Render engine
│       └── draw_canvas.dart          # Paint tool
├── assets/
│   ├── characters/
│   ├── animations/
│   └── ...
├── pubspec.yaml                      # Dépendances
└── README.md                         # Docs
```

---

## 🎓 Exemples

### Créer un personnage "Ninja"
1. Character → Skin: Black, Hair: Short Black, Eyes: Sharp, Outfit: Armor
2. Library → Combat → Energy Blast
3. Export → TikTok

### Créer un "Walk Cycle"
1. Library → Movement → Walk Forward
2. Timeline → Voir les keyframes (étudier comment ça marche)
3. Dupliquer et modifier pour "Walk Backward"
4. Blend les 2 : créer une transition lisse

### Animer sa Photo
1. Character → Upload Image
2. App auto-segmente
3. Choisir une animation
4. Export en GIF
5. Partager sur Discord/Twitter

---

## 📞 Support

- **Bugs** : Créer une issue sur GitHub
- **Questions** : Lire le README_v27.md complet
- **Suggestions** : Discord serveur (link à venir)

---

**Happy animating! 🎬✨**
