Ce dossier EST maintenant lu par le code (AudioCueService), contrairement aux
4 autres dossiers assets/ qui restent inutilisés.

Nomme tes fichiers d'après le nom exact de la cue, en minuscules,
espaces -> underscore :
  "Impact SFX"   -> impact_sfx.mp3
  "Footsteps"    -> footsteps.mp3
  "Whoosh"       -> whoosh.mp3
  "Voice Cue"    -> voice_cue.mp3
  "Music Start"  -> music_start.mp3
  "Music Stop"   -> music_stop.mp3

Aucun fichier fourni ici par défaut (pas d'accès réseau pour en récupérer) —
sans fichier, la cue reste silencieuse (pas de crash), juste un flash visuel
et une ligne de log dans la console.
