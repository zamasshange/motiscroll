import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/models.dart';

const coverPalettes = <Field, List<Color>>{
  Field.sports: [
    Color(0xFFE7A394),
    Color(0xFFC4524A),
    Color(0xFF1C3144),
    Color(0xFF7E2E3A),
  ],
  Field.business: [
    Color(0xFFD7C4A2),
    Color(0xFF8EA4B8),
    Color(0xFF1B2836),
    Color(0xFF3E5C78),
  ],
  Field.science: [
    Color(0xFFB7DDD6),
    Color(0xFF3E8F88),
    Color(0xFF102E36),
    Color(0xFF3C4F86),
  ],
  Field.arts: [
    Color(0xFFF0C2B4),
    Color(0xFFC46B7A),
    Color(0xFF2A1C32),
    Color(0xFF6E3A5C),
  ],
  Field.leadership: [
    Color(0xFFC9D0E4),
    Color(0xFF8A7348),
    Color(0xFF1A2238),
    Color(0xFF31456E),
  ],
  Field.resilience: [
    Color(0xFFD7B7A6),
    Color(0xFFC46A4A),
    Color(0xFF102E2C),
    Color(0xFF2F6A5E),
  ],
  Field.other: [
    Color(0xFFE7C3B0),
    Color(0xFFE07A4A),
    Color(0xFF17191E),
    Color(0xFF3A4150),
  ],
};

class CoverPainter extends CustomPainter {
  const CoverPainter({
    required this.field,
    required this.seed,
    required this.subtle,
  });

  final Field field;
  final String seed;
  final bool subtle;

  @override
  void paint(Canvas canvas, Size size) {
    final palette = coverPalettes[field] ?? coverPalettes[Field.other]!;
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = palette[2]);
    final random = math.Random(hashString('$field:$seed'));
    for (var index = 0; index < 4; index++) {
      final color = palette[index];
      final center = Offset(
        (random.nextDouble() * 0.9 - 0.15) * size.width,
        (random.nextDouble() * 0.9 - 0.15) * size.height,
      );
      final radius = size.shortestSide * (0.5 + random.nextDouble() * 0.4);
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius,
          [color.withValues(alpha: 0.95), color.withValues(alpha: 0)],
          [0, 1],
        )
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          size.shortestSide * 0.14,
        );
      canvas.drawCircle(center, radius, paint);
    }

    final grain = math.Random(hashString('$seed:grain'));
    final grainPaint = Paint()..color = const Color(0x18FFFFFF);
    for (var index = 0; index < 80; index++) {
      canvas.drawRect(
        Rect.fromLTWH(
          grain.nextDouble() * size.width,
          grain.nextDouble() * size.height,
          1.2,
          1.2,
        ),
        grainPaint,
      );
    }

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          size.center(Offset.zero),
          size.longestSide * 0.72,
          const [Color(0x00000000), Color(0x99000000)],
          const [0.5, 1],
        ),
    );
    if (subtle) {
      canvas.drawRect(rect, Paint()..color = const Color(0xD90B0B0D));
    }
  }

  @override
  bool shouldRepaint(CoverPainter oldDelegate) {
    return oldDelegate.field != field ||
        oldDelegate.seed != seed ||
        oldDelegate.subtle != subtle;
  }
}

class _ImagePainter extends CustomPainter {
  const _ImagePainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_ImagePainter oldDelegate) => oldDelegate.image != image;
}

class CoverCache {
  CoverCache._();

  static final images = <String, ui.Image>{};
  static final order = <String>[];
  static final inflight = <String, Future<ui.Image>>{};

  static ui.Image? peek(String key) => images[key];

  static Future<ui.Image> obtain({
    required String key,
    required Field field,
    required String seed,
    required bool subtle,
    required Size size,
  }) {
    final cached = images[key];
    if (cached != null) return Future.value(cached);
    return inflight.putIfAbsent(key, () async {
      try {
        final image = await _raster(
          field: field,
          seed: seed,
          subtle: subtle,
          size: size,
        );
        images[key] = image;
        order.remove(key);
        order.add(key);
        while (order.length > 24) {
          images.remove(order.removeAt(0))?.dispose();
        }
        return image;
      } finally {
        inflight.remove(key);
      }
    });
  }

  static Future<ui.Image> _raster({
    required Field field,
    required String seed,
    required bool subtle,
    required Size size,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    CoverPainter(field: field, seed: seed, subtle: subtle).paint(canvas, size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      math.max(1, size.width.ceil()),
      math.max(1, size.height.ceil()),
    );
    picture.dispose();
    return image;
  }
}

class GeneratedCover extends StatefulWidget {
  const GeneratedCover({
    super.key,
    required this.field,
    required this.seed,
    this.subtle = false,
    this.borderRadius,
  });

  final Field field;
  final String seed;
  final bool subtle;
  final BorderRadius? borderRadius;

  @override
  State<GeneratedCover> createState() => _GeneratedCoverState();
}

class _GeneratedCoverState extends State<GeneratedCover> {
  String? _loading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        Widget painted = const SizedBox.expand();
        if (size.width.isFinite &&
            size.height.isFinite &&
            size.width > 8 &&
            size.height > 8) {
          final bucket = Size(
            math.max(8, (size.width / 8).round() * 8).toDouble(),
            math.max(8, (size.height / 8).round() * 8).toDouble(),
          );
          final longest = math.max(bucket.width, bucket.height);
          final scale = longest > 480 ? 480 / longest : 1.0;
          final raster = Size(bucket.width * scale, bucket.height * scale);
          final key =
              '${widget.field.name}|${widget.seed}|${raster.width.round()}|${raster.height.round()}|${widget.subtle}';
          final image = CoverCache.peek(key);
          if (image == null && _loading != key) {
            _loading = key;
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _load(key, raster),
            );
          }
          painted = RepaintBoundary(
            child: CustomPaint(
              painter: image == null
                  ? CoverPainter(
                      field: widget.field,
                      seed: widget.seed,
                      subtle: widget.subtle,
                    )
                  : _ImagePainter(image),
              child: const SizedBox.expand(),
            ),
          );
        }
        final radius = widget.borderRadius;
        if (radius == null) return painted;
        return ClipRRect(borderRadius: radius, child: painted);
      },
    );
  }

  Future<void> _load(String key, Size size) async {
    try {
      await CoverCache.obtain(
        key: key,
        field: widget.field,
        seed: widget.seed,
        subtle: widget.subtle,
        size: size,
      );
      if (mounted) setState(() {});
    } on Object {
      _loading = null;
    }
  }
}
