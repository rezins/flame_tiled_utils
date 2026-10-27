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
  /// Compiles the listed layers of [tileMap] into one image.
  ///
  /// [destTileSize] is the size a tile is drawn at in the game, the same
  /// `destTileSize` that was passed to `TiledComponent.load`.
  ///
  /// When [bakeAtSourceResolution] is true (the default), the image is stored
  /// at the tileset's own pixel size (the map's `tilewidth`/`tileheight`) and
  /// scaled up to [destTileSize] when it is rendered. For a 16px tileset drawn
  /// at 40px this keeps 6.25x fewer pixels in memory, and the tiles are scaled
  /// once, on screen, like sprites that are scaled in code. Set it to false to
  /// store the image at [destTileSize], as before.
  ///
  /// The upscale uses the filter quality of [paint]; keep it at
  /// [FilterQuality.none] (the default of [Paint]) for pixel art.
  PositionComponent compileMapLayer({
    required RenderableTiledMap tileMap,
    List<String>? layerNames,
    Paint? paint,
    Vector2? destTileSize,
    bool bakeAtSourceResolution = true,
  }) {
    layerNames ??= [];
    paint ??= Paint();

    final sourceWidth = tileMap.map.tileWidth;
    final sourceHeight = tileMap.map.tileHeight;
    final destWidth = destTileSize?.x.toInt() ?? sourceWidth;
    final destHeight = destTileSize?.y.toInt() ?? sourceHeight;
    final bakeWidth = bakeAtSourceResolution ? sourceWidth : destWidth;
    final bakeHeight = bakeAtSourceResolution ? sourceHeight : destHeight;

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    // The layers are already built at destTileSize by TiledComponent.load,
    // so baking at another size means drawing them scaled.
    canvas.scale(bakeWidth / destWidth, bakeHeight / destHeight);

    final layerNameSet = layerNames.toSet();
    for (final rl in tileMap.renderableLayers) {
      if (layerNameSet.contains(rl.layer.name)) {
        rl.render(canvas, null);
      }
    }

    final picture = recorder.endRecording();

    final image = picture.toImageSync(
      tileMap.map.width * bakeWidth,
      tileMap.map.height * bakeHeight,
    );
    picture.dispose();

    return _ImageComponent(
      image,
      paint,
      destWidth / bakeWidth,
      destHeight / bakeHeight,
    );
  }
}

class _ImageComponent extends PositionComponent {
  _ImageComponent(this.image, this.paint, this.renderScaleX, this.renderScaleY);

  final Image image;
  final Paint paint;

  /// Scale applied when drawing [image], which brings an image baked at the
  /// source resolution back to the size of the tiles in the game. Both are 1
  /// when the image was baked at that size already.
  final double renderScaleX;
  final double renderScaleY;

  @override
  void render(Canvas canvas) {
    if (renderScaleX == 1 && renderScaleY == 1) {
      canvas.drawImage(image, Offset.zero, paint);
      return;
    }
    canvas.save();
    canvas.scale(renderScaleX, renderScaleY);
    canvas.drawImage(image, Offset.zero, paint);
    canvas.restore();
  }
}
