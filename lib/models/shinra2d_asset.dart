import 'dart:convert';

class Shinra2DPartAsset {
  Shinra2DPartAsset({
    required this.id,
    required this.name,
    required this.boneId,
    required this.visible,
    required this.crop,
    required this.imageBase64,
    this.offsetX = 0,
    this.offsetY = 0,
  });
  final String id;
  final String name;
  final String boneId;
  final bool visible;
  final List<double>? crop; // left, top, width, height
  final String imageBase64;
  final double offsetX, offsetY;

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'boneId': boneId, 'visible': visible,
    'crop': crop, 'imageBase64': imageBase64, 'offsetX': offsetX, 'offsetY': offsetY,
  };
  static Shinra2DPartAsset fromJson(Map<String,dynamic> j) => Shinra2DPartAsset(
    id: j['id'] as String, name: j['name'] as String? ?? j['id'] as String,
    boneId: j['boneId'] as String, visible: j['visible'] as bool? ?? true,
    crop: (j['crop'] as List?)?.map((e)=>(e as num).toDouble()).toList(),
    imageBase64: j['imageBase64'] as String? ?? '',
    offsetX: (j['offsetX'] as num?)?.toDouble() ?? 0,
    offsetY: (j['offsetY'] as num?)?.toDouble() ?? 0,
  );
}

class Shinra2DBoneAsset {
  Shinra2DBoneAsset({
    required this.id, required this.name, required this.type,
    required this.parentId, required this.x, required this.y,
    required this.rotation, required this.length, required this.scale,
  });
  final String id, name, type;
  final String? parentId;
  final double x, y, rotation, length, scale;

  Map<String,dynamic> toJson() => {
    'id':id,'name':name,'type':type,'parentId':parentId,
    'x':x,'y':y,'rotation':rotation,'length':length,'scale':scale,
  };
  static Shinra2DBoneAsset fromJson(Map<String,dynamic> j) => Shinra2DBoneAsset(
    id:j['id'] as String,name:j['name'] as String,type:j['type'] as String? ?? 'root',
    parentId:j['parentId'] as String?,x:(j['x'] as num?)?.toDouble() ?? 0,
    y:(j['y'] as num?)?.toDouble() ?? 0,rotation:(j['rotation'] as num?)?.toDouble() ?? 0,
    length:(j['length'] as num?)?.toDouble() ?? 60,scale:(j['scale'] as num?)?.toDouble() ?? 1,
  );
}

class Shinra2DPuppetAsset {
  Shinra2DPuppetAsset({
    required this.formatVersion,
    required this.name,
    required this.sourceImageBase64,
    required this.bones,
    required this.parts,
  });
  final int formatVersion;
  final String name;
  final String sourceImageBase64;
  final List<Shinra2DBoneAsset> bones;
  final List<Shinra2DPartAsset> parts;

  Map<String,dynamic> toJson() => {
    'format':'shinra-2d-puppet',
    'formatVersion':formatVersion,
    'name':name,
    'sourceImageBase64':sourceImageBase64,
    'bones':bones.map((e)=>e.toJson()).toList(),
    'parts':parts.map((e)=>e.toJson()).toList(),
  };

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  static Shinra2DPuppetAsset decode(String text) {
    final j=jsonDecode(text) as Map<String,dynamic>;
    if(j['format']!='shinra-2d-puppet') {
      throw const FormatException('Not a Shinra 2D Puppet file');
    }
    return Shinra2DPuppetAsset(
      formatVersion:(j['formatVersion'] as num?)?.toInt() ?? 1,
      name:j['name'] as String? ?? 'Shinra Character',
      sourceImageBase64:j['sourceImageBase64'] as String? ?? '',
      bones:[for(final x in (j['bones'] as List? ?? const [])) Shinra2DBoneAsset.fromJson(Map<String,dynamic>.from(x as Map))],
      parts:[for(final x in (j['parts'] as List? ?? const [])) Shinra2DPartAsset.fromJson(Map<String,dynamic>.from(x as Map))],
    );
  }
}
