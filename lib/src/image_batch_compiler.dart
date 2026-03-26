import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';

/// Utility class to compile multiple tiles into one image.
/// Usage example:
///
/// ```dart
/// final mapComponent = await TiledComponent.load('map.tmx', Vector2.all(16));
/// final imageCompiler = ImageBatchCompiler();
/// final ground = await imageCompiler.compileMapLayer(tileMap: mapComponent.tileMap, layerNames: ['ground']);
/// ground.priority = RenderPriority.ground.priority;
/// add(ground);
/// ```
class ImageBatchCompiler {
  PositionComponent compileMapLayer({
    required RenderableTiledMap tileMap,
    List<String>? layerNames,
    Paint? paint,
  }) {
    layerNames ??= [];
    paint ??= Paint();

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    final layerNameSet = layerNames.toSet();
    for (final rl in tileMap.renderableLayers) {
      if (layerNameSet.contains(rl.layer.name)) {
        rl.render(canvas, null);
      }
    }

    final picture = recorder.endRecording();

    final image = picture.toImageSync(
      tileMap.map.width * tileMap.map.tileWidth,
      tileMap.map.height * tileMap.map.tileHeight,
    );
    picture.dispose();

    return _ImageComponent(image, paint);
  }
}

class _ImageComponent extends PositionComponent {
  _ImageComponent(this.image, this.paint);

  final Image image;
  final Paint paint;

  @override
  void render(Canvas canvas) {
    canvas.drawImage(image, const Offset(0, 0), paint);
  }
}
