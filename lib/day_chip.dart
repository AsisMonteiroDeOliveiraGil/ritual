import 'package:flutter/material.dart';

class DayChip extends StatefulWidget {
  final String dayLabel;
  final String dayNumber;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;
  final double width;

  const DayChip({
    super.key,
    required this.dayLabel,
    required this.dayNumber,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
    this.width = 64,
  });

  @override
  State<DayChip> createState() => _DayChipState();
}

class _DayChipState extends State<DayChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.isToday) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant DayChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldAnimate = widget.isToday;
    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldAnimate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected
        ? const Color(0xFFC63C54)
        : widget.isToday
            ? const Color(0xFF2F2F33)
            : const Color(0xFF2A2A2A);
    final textColor =
        widget.isSelected ? Colors.white : const Color(0xFFE6E6E6);
    final showAnimatedBorder = widget.isToday;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            foregroundPainter: showAnimatedBorder
                ? _AnimatedGradientBorderPainter(
                    progress: _controller.value,
                    radius: 18,
                  )
                : null,
            child: child,
          );
        },
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(vertical: 10),
          margin: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.dayLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.dayNumber,
                style: TextStyle(
                  fontSize: 18,
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedGradientBorderPainter extends CustomPainter {
  final double progress;
  final double radius;

  _AnimatedGradientBorderPainter({
    required this.progress,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.5;
    final rect = Offset.zero & size;
    final inset = stroke / 2;
    final drawRect = rect.deflate(inset);
    final drawRadius = radius - inset;
    final drawRRect =
        RRect.fromRectAndRadius(drawRect, Radius.circular(drawRadius));

    final gradient = SweepGradient(
      colors: const [
        Color(0xFFC63C54),
        Color(0xFF000000),
        Color(0xFFC63C54),
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: GradientRotation(progress * 6.28318530718),
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;

    canvas.drawRRect(drawRRect, paint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedGradientBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
