import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Reads depth tiles from the bundled MBTiles SQLite file.
///
/// MBTiles uses TMS tile row order (y=0 at bottom), which matches
/// what gdal2tiles produced — no flip needed here since we query by TMS y.
class MbTileProvider extends TileProvider {
  final Database _db;
  MbTileProvider(this._db);

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return _MbTileImage(coordinates, _db);
  }
}

class _MbTileImage extends ImageProvider<_MbTileImage> {
  final TileCoordinates coordinates;
  final Database db;

  const _MbTileImage(this.coordinates, this.db);

  @override
  Future<_MbTileImage> obtainKey(ImageConfiguration configuration) async =>
      this;

  @override
  ImageStreamCompleter loadImage(
      _MbTileImage key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(_loadTile(key, decode));
  }

  Future<ImageInfo> _loadTile(
      _MbTileImage key, ImageDecoderCallback decode) async {
    final z = key.coordinates.z;
    final x = key.coordinates.x;
    // MBTiles TMS: y=0 at bottom. Convert XYZ y to TMS y.
    final y = (1 << z) - 1 - key.coordinates.y;

    final rows = await key.db.rawQuery(
      'SELECT tile_data FROM tiles WHERE zoom_level=? AND tile_column=? AND tile_row=?',
      [z, x, y],
    );

    if (rows.isEmpty) {
      // Return a 1x1 transparent PNG for missing tiles
      final bytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, // IDAT chunk
        0x54, 0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x02,
        0x00, 0x01, 0xE2, 0x21, 0xBC, 0x33, 0x00, 0x00, // IEND chunk
        0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
        0x60, 0x82,
      ]);
      final buffer = await ImmutableBuffer.fromUint8List(bytes);
      final codec = await decode(buffer);
      final frame = await codec.getNextFrame();
      return ImageInfo(image: frame.image);
    }

    final blob = rows.first['tile_data'] as Uint8List;
    final buffer = await ImmutableBuffer.fromUint8List(blob);
    final codec = await decode(buffer);
    final frame = await codec.getNextFrame();
    return ImageInfo(image: frame.image);
  }

  @override
  bool operator ==(Object other) =>
      other is _MbTileImage && coordinates == other.coordinates;

  @override
  int get hashCode => coordinates.hashCode;
}

/// Manages opening the bundled MBTiles database once and reusing it.
/// Public so other layers (e.g. EnhancedDepthLayer) can share the same DB.
class MbTilesDb {
  static Database? _db;
  static bool _loading = false;

  static Future<Database?> get() async {
    if (_db != null) return _db;
    if (_loading) {
      // Wait for it
      while (_loading) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _db;
    }
    _loading = true;
    try {
      final dir = await getApplicationSupportDirectory();
      final dest = p.join(dir.path, 'depth_gebco.mbtiles');

      final assetData = await rootBundle.load('assets/depth_gebco.mbtiles');
      final destFile = File(dest);
      // Re-copy if missing or size differs (catches updated asset bundles)
      if (!destFile.existsSync() ||
          destFile.lengthSync() != assetData.lengthInBytes) {
        await destFile.writeAsBytes(assetData.buffer.asUint8List());
      }

      _db = await openDatabase(dest, readOnly: true);
    } catch (_) {
      // DB failed to open — layer will silently show nothing
    } finally {
      _loading = false;
    }
    return _db;
  }
}

/// GEBCO bathymetric tile layer — reads from bundled MBTiles asset (offline).
///
/// Covers the Arabian Gulf / Persian Gulf region (lon 30–65°E, lat 10–40°N).
/// Toggle via [MapLayerManager.showDepthSoundings].
class DepthSoundingsLayer extends StatefulWidget {
  final double opacity;

  const DepthSoundingsLayer({super.key, this.opacity = 0.6});

  @override
  State<DepthSoundingsLayer> createState() => _DepthSoundingsLayerState();
}

class _DepthSoundingsLayerState extends State<DepthSoundingsLayer> {
  Database? _db;

  @override
  void initState() {
    super.initState();
    MbTilesDb.get().then((db) {
      if (mounted) setState(() => _db = db);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_db == null) return const SizedBox.shrink();

    return Opacity(
      opacity: widget.opacity,
      child: TileLayer(
        urlTemplate: 'mbtiles://{z}/{x}/{y}',
        tileProvider: MbTileProvider(_db!),
        minZoom: 4,
        maxZoom: 18,
        maxNativeZoom: 12,
        errorTileCallback: (tile, error, stackTrace) {},
      ),
    );
  }
}
