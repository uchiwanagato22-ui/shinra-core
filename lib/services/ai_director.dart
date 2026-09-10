class DirectorAction { DirectorAction(this.type, this.label, this.time); final String type; final String label; final double time; }

class AiDirector {
  static List<DirectorAction> parse(String text) {
    final lower = text.toLowerCase();
    final words = <String>[];
    final candidates = <String, String>{
      'cour': 'Run', 'marche': 'Walk', 'saute': 'Jump', 'tombe': 'Fall', 'frappe': 'Punch', 'coup de pied': 'Kick', 'esquive': 'Dodge', 'terrifiant': 'Terrifying', 'regarde': 'Look Behind', 'arrête': 'Stop', 'arrete': 'Stop', 'expression': 'Face Expression'
    };
    for (final e in candidates.entries) if (lower.contains(e.key)) words.add(e.value);
    if (words.isEmpty) words.add('Idle');
    final unique = <String>[]; for (final w in words) if (!unique.contains(w)) unique.add(w);
    return [for (var i = 0; i < unique.length; i++) DirectorAction(unique[i].toLowerCase().replaceAll(' ', '_'), unique[i], i * .8)];
  }
}
