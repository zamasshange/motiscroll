import 'package:flutter/material.dart';

enum ShareMark { whatsapp, instagram, facebook, tiktok, x }

class ShareBrandMark extends StatelessWidget {
  const ShareBrandMark(this.mark, {super.key, this.size = 28});

  final ShareMark mark;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ShareMarkPainter(mark),
    );
  }
}

class _ShareMarkPainter extends CustomPainter {
  _ShareMarkPainter(this.mark);

  final ShareMark mark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.width * 0.28);
    switch (mark) {
      case ShareMark.whatsapp:
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, radius),
          Paint()..color = const Color(0xFF25D366),
        );
        final bubble = Paint()..color = const Color(0xFFFFFFFF);
        canvas.drawCircle(size.center(Offset.zero), size.width * 0.28, bubble);
        final tail = Path()
          ..moveTo(size.width * 0.38, size.height * 0.62)
          ..lineTo(size.width * 0.30, size.height * 0.78)
          ..lineTo(size.width * 0.52, size.height * 0.64)
          ..close();
        canvas.drawPath(tail, bubble);
      case ShareMark.instagram:
        final shader = const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFFFEDA75),
            Color(0xFFFA7E1E),
            Color(0xFFD62976),
            Color(0xFF962FBF),
          ],
        ).createShader(rect);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, radius),
          Paint()..shader = shader,
        );
        final ring = Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.07;
        canvas.drawCircle(size.center(Offset.zero), size.width * 0.22, ring);
        canvas.drawCircle(
          Offset(size.width * 0.68, size.height * 0.30),
          size.width * 0.045,
          Paint()..color = const Color(0xFFFFFFFF),
        );
      case ShareMark.facebook:
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, radius),
          Paint()..color = const Color(0xFF1877F2),
        );
        final text = TextPainter(
          text: TextSpan(
            text: 'f',
            style: TextStyle(
              color: const Color(0xFFFFFFFF),
              fontSize: size.width * 0.62,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(
          canvas,
          Offset(
            (size.width - text.width) / 2,
            (size.height - text.height) / 2 - size.height * 0.02,
          ),
        );
      case ShareMark.tiktok:
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, radius),
          Paint()..color = const Color(0xFF111111),
        );
        final note = TextPainter(
          text: TextSpan(
            text: '♪',
            style: TextStyle(
              color: const Color(0xFF25F4EE),
              fontSize: size.width * 0.46,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        note.paint(canvas, Offset(size.width * 0.22, size.height * 0.24));
        final note2 = TextPainter(
          text: TextSpan(
            text: '♪',
            style: TextStyle(
              color: const Color(0xFFFE2C55),
              fontSize: size.width * 0.46,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        note2.paint(canvas, Offset(size.width * 0.36, size.height * 0.28));
      case ShareMark.x:
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, radius),
          Paint()..color = const Color(0xFF111111),
        );
        final x = TextPainter(
          text: TextSpan(
            text: '𝕏',
            style: TextStyle(
              color: const Color(0xFFFFFFFF),
              fontSize: size.width * 0.52,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        x.paint(
          canvas,
          Offset((size.width - x.width) / 2, (size.height - x.height) / 2),
        );
    }
  }

  @override
  bool shouldRepaint(covariant _ShareMarkPainter oldDelegate) {
    return oldDelegate.mark != mark;
  }
}
