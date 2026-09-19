import 'dart:convert';
import 'dart:io';

/// Layered 2D character interchange used by Shinra Core.
///
/// This is intentionally not a 3D format. A layered character is a set of
/// transparent raster layers plus depth, pivot and bone-binding metadata.
/// External AI decomposition can produce the layers; Shinra can then consume
/// the result without knowing which model produced it.
class ShinraLayeredCharacter {
  ShinraLayeredCharacter({
    required this.version,
    required this.name,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.layers,
  });

  final int version;
  final String name;
  final int canvasWidth;
  final int canvasHeight;
  final List<ShinraLayer> layers;

  Map<String, dynamic> toJson() => {
    'format': 'shinra-2d-layers',
    'version': version,
    'name': name,
    'canvasWidth': canvasWidth,
    'canvasHeight': canvasHeight,
    'layers': layers.map((e) => e.toJson()).toList(),
  };

  static ShinraLayeredCharacter fromJson(Map<String, dynamic> j) {
    if (j['format'] != 'shinra-2d-layers') {
      throw const FormatException('Not a Shinra 2D layer manifest');
    }
    return ShinraLayeredCharacter(
      version: (j['version'] as num?)?.toInt() ?? 1,
      name: j['name'] as String? ?? 'Shinra Character',
      canvasWidth: (j['canvasWidth'] as num?)?.toInt() ?? 0,
      canvasHeight: (j['canvasHeight'] as num?)?.toInt() ?? 0,
      layers: [
        for (final raw in (j['layers'] as List? ?? const []))
          ShinraLayer.fromJson(Map<String, dynamic>.from(raw as Map)),
      ],
    );
  }

  Future<void> save(String path) =>
      File(path).writeAsString(const JsonEncoder.withIndent('  ').convert(toJson()));
}

class ShinraLayer {
  ShinraLayer({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.z,
    this.boneId,
    this.parentLayerId,
    this.pivotX = .5,
    this.pivotY = .5,
    this.maskLayerId,
    this.hidden = false,
  });

  final String id;
  final String name;
  final String imagePath;
  final int z;
  final String? boneId;
  final String? parentLayerId;
  final double pivotX;
  final double pivotY;
  final String? maskLayerId;
  final bool hidden;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imagePath': imagePath,
    'z': z,
    'boneId': boneId,
    'parentLayerId': parentLayerId,
    'pivotX': pivotX,
    'pivotY': pivotY,
    'maskLayerId': maskLayerId,
    'hidden': hidden,
  };

  static ShinraLayer fromJson(Map<String, dynamic> j) => ShinraLayer(
    id: j['id'] as String,
    name: j['name'] as String? ?? j['id'] as String,
    imagePath: j['imagePath'] as String,
    z: (j['z'] as num?)?.toInt() ?? 0,
    boneId: j['boneId'] as String?,
    parentLayerId: j['parentLayerId'] as String?,
    pivotX: (j['pivotX'] as num?)?.toDouble() ?? .5,
    pivotY: (j['pivotY'] as num?)?.toDouble() ?? .5,
    maskLayerId: j['maskLayerId'] as String?,
    hidden: j['hidden'] as bool? ?? false,
  );
}
