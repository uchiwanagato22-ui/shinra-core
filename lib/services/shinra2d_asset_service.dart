import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/rig.dart';
import '../models/shinra2d_asset.dart';

/// Shinra's native 2D puppet format.
///
/// A .shn2d file is deliberately NOT a video, sprite sheet or 3D file.
/// It is a portable character package: source artwork + cut-out textures +
/// the exact 2D bone hierarchy. This lets the same artwork be animated
/// independently from the procedural character generator.
class Shinra2DAssetService {
  static const extension = 'shn2d';

  static Future<Shinra2DPuppetAsset> fromProject(ProjectState p, {String name = 'Shinra Character'}) async {
    final source = p.importedImagePath.isEmpty ? '' : base64Encode(await File(p.importedImagePath).readAsBytes());
    final parts=<Shinra2DPartAsset>[];
    for(final part in p.parts) {
      var encoded='';
      if(part.imagePath.isNotEmpty) {
        try { encoded=base64Encode(await File(part.imagePath).readAsBytes()); } catch (_) {}
      }
      parts.add(Shinra2DPartAsset(
        id:part.id,name:part.name,boneId:part.boneId,visible:part.visible,
        crop:part.crop==null?null:[part.crop!.left,part.crop!.top,part.crop!.width,part.crop!.height],
        imageBase64:encoded, offsetX:part.imageOffsetX, offsetY:part.imageOffsetY,
      ));
    }
    return Shinra2DPuppetAsset(
      formatVersion:1,name:name,sourceImageBase64:source,
      bones:[for(final b in p.bones) Shinra2DBoneAsset(
        id:b.id,name:b.name,type:b.type.name,parentId:b.parentId,x:b.x,y:b.y,
        rotation:b.rotation,length:b.length,scale:b.scale)],
      parts:parts,
    );
  }

  static Future<String> writeProject(ProjectState p, String outputPath, {String name='Shinra Character'}) async {
    final asset=await fromProject(p,name:name);
    await File(outputPath).writeAsString(asset.encode());
    return outputPath;
  }

  /// Materializes the embedded artwork/cut-outs and replaces the selected
  /// actor's puppet with them. The procedural character is not used.
  static Future<void> applyToProject(ProjectState p, Shinra2DPuppetAsset asset) async {
    final dir=Directory('${(await getApplicationSupportDirectory()).path}/shinra/puppets/imported/${DateTime.now().microsecondsSinceEpoch}');
    await dir.create(recursive:true);

    String sourcePath='';
    if(asset.sourceImageBase64.isNotEmpty) {
      sourcePath='${dir.path}/source.png';
      await File(sourcePath).writeAsBytes(base64Decode(asset.sourceImageBase64));
    }

    final typeByName={for(final t in BoneType.values)t.name:t};
    p.bones=[
      for(final b in asset.bones)
        Bone(id:b.id,name:b.name,type:typeByName[b.type]??BoneType.root,parentId:b.parentId,
          x:b.x,y:b.y,rotation:b.rotation,length:b.length,scale:b.scale)
    ];

    final parts=<CharacterPart>[];
    for(final a in asset.parts) {
      String imagePath='';
      if(a.imageBase64.isNotEmpty) {
        imagePath='${dir.path}/${a.id}.png';
        await File(imagePath).writeAsBytes(base64Decode(a.imageBase64));
      }
      Rect? crop;
      if(a.crop!=null && a.crop!.length==4) crop=Rect.fromLTWH(a.crop![0],a.crop![1],a.crop![2],a.crop![3]);
      final matches=p.parts.where((x)=>x.id==a.id).toList();
      final original=matches.isEmpty?null:matches.first;
      parts.add(CharacterPart(
        id:a.id,name:a.name,type:original?.type??PartType.body,boneId:a.boneId,
        visible:a.visible,crop:crop,imagePath:imagePath, imageOffsetX:a.offsetX, imageOffsetY:a.offsetY,
      ));
    }
    p.parts=parts;
    p.importedImagePath=sourcePath;
    p.useImageAsBody=true;
    p.selectedBoneId=p.bones.isEmpty?'':p.bones.first.id;
    p.persistSelectedActor();
    p.status='Shinra 2D Puppet imported — artwork is now the animated character';
    p.refresh();
  }
}
