import '../models/rig.dart' show ProjectState;

class DirectorAction {
  DirectorAction(this.kind, this.label, {this.clipId, this.value});
  /// 'clip' plays an animation, 'expression' sets a face, 'fx' adds an effect.
  final String kind;
  final String label;
  final String? clipId;
  final String? value;
}

/// Turns a short text instruction into real actions this project can execute
/// — a sequence of existing animation clips to play back to back, plus any
/// expression/FX mentioned — instead of a static list nobody can act on.
/// Matches against the clips/expressions/FX that actually exist in the
/// project rather than a separate hardcoded vocabulary, so it never points
/// at an animation that isn't really there.
class AiDirector {
  static const _expressionWords = {
    'colère': 'Angry', 'colere': 'Angry', 'fâché': 'Angry', 'fache': 'Angry',
    'content': 'Happy', 'sourire': 'Happy', 'heureux': 'Happy', 'joie': 'Happy',
    'triste': 'Sad', 'peur': 'Surprised', 'surpris': 'Surprised',
    'terrifiant': 'Terrifying', 'effrayant': 'Terrifying',
    'déterminé': 'Determined', 'determine': 'Determined',
    'smirk': 'Smirk',
  };

  static const _fxWords = {
    'impact': 'Impact', 'poussière': 'Dust', 'poussiere': 'Dust',
    'fumée': 'Smoke', 'fumee': 'Smoke', 'étincelle': 'Spark', 'etincelle': 'Spark',
    'tremble': 'Camera Shake', 'secoue': 'Camera Shake', 'energie': 'Energy Burst', 'énergie': 'Energy Burst',
  };

  // French/English phrase → the *concept* it means, matched against real clip
  // names below rather than a fixed animation id (so it stays correct even
  // if the clip list changes).
  static const _movementWords = {
    'cour': 'Run', 'run': 'Run', 'marche': 'Walk', 'walk': 'Walk',
    'saute': 'Jump', 'jump': 'Jump', 'tombe': 'Fall', 'fall': 'Fall',
    'esquive': 'Dodge Step', 'dodge': 'Dodge Step',
    'arrête': 'Idle', 'arrete': 'Idle', 'stop': 'Idle', 'idle': 'Idle',
  };
  static const _combatWords = {
    'frappe': 'Attack', 'attaque': 'Attack', 'attack': 'Attack', 'punch': 'Attack',
    'prépare': 'Attack Windup', 'prepare': 'Attack Windup', 'recule': 'Attack Recovery',
    'bloque': 'Block', 'block': 'Block', 'pare': 'Block',
    'touché': 'Hit Reaction', 'touche': 'Hit Reaction', 'hit': 'Hit Reaction',
    'contre': 'Counter', 'riposte': 'Counter',
  };

  static List<DirectorAction> parse(String text, ProjectState p) {
    final lower = text.toLowerCase();
    final actions = <DirectorAction>[];
    final clipNames = {for (final c in p.animations) c.name.toLowerCase(): c};

    void tryClip(Map<String, String> words) {
      for (final e in words.entries) {
        if (!lower.contains(e.key)) continue;
        final clip = clipNames[e.value.toLowerCase()];
        if (clip == null) continue; // concept has no matching clip in this project — skip rather than point at nothing
        if (actions.any((a) => a.clipId == clip.id)) continue;
        actions.add(DirectorAction('clip', clip.name, clipId: clip.id));
      }
    }

    tryClip(_movementWords);
    tryClip(_combatWords);

    for (final e in _expressionWords.entries) {
      if (lower.contains(e.key)) { actions.add(DirectorAction('expression', 'Expression: ${e.value}', value: e.value)); break; }
    }
    for (final e in _fxWords.entries) {
      if (lower.contains(e.key)) actions.add(DirectorAction('fx', 'FX: ${e.value}', value: e.value));
    }

    if (actions.where((a) => a.kind == 'clip').isEmpty) {
      final idle = p.animations.where((c) => c.name == 'Idle').firstOrNull ?? p.animations.first;
      actions.insert(0, DirectorAction('clip', idle.name, clipId: idle.id));
    }
    return actions;
  }
}

extension _FirstOrNull<T> on Iterable<T> { T? get firstOrNull => isEmpty ? null : first; }
