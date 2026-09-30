import 'dart:math';
import 'package:flutter/material.dart';

class JoyEntrance extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final double beginY;
  final Duration duration;

  const JoyEntrance({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.beginY = 22,
    this.duration = const Duration(milliseconds: 520),
  });

  @override
  State<JoyEntrance> createState() => _JoyEntranceState();
}

class _JoyEntranceState extends State<JoyEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final backCurve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slide = Tween<double>(
      begin: widget.beginY,
      end: 0,
    ).animate(backCurve);

    _scale = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(backCurve);

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (!mounted) return;
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, _slide.value),
            child: Transform.scale(
              scale: _scale.value,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class JoyPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  const JoyPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  });

  @override
  State<JoyPressable> createState() => _JoyPressableState();
}

class _JoyPressableState extends State<JoyPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted) return;

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
        _setPressed(false);
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class JoyFloat extends StatefulWidget {
  final Widget child;
  final double distance;
  final int durationMs;
  final int delayMs;

  const JoyFloat({
    super.key,
    required this.child,
    this.distance = 8,
    this.durationMs = 1800,
    this.delayMs = 0,
  });

  @override
  State<JoyFloat> createState() => _JoyFloatState();
}

class _JoyFloatState extends State<JoyFloat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (!mounted) return;
      _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final dy = sin(_controller.value * pi) * widget.distance;

        return Transform.translate(
          offset: Offset(0, -dy),
          child: child,
        );
      },
    );
  }
}

class JoyPulse extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final int durationMs;

  const JoyPulse({
    super.key,
    required this.child,
    this.minScale = 0.98,
    this.maxScale = 1.04,
    this.durationMs = 1500,
  });

  @override
  State<JoyPulse> createState() => _JoyPulseState();
}

class _JoyPulseState extends State<JoyPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    )..repeat(reverse: true);

    _scale = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: widget.child,
    );
  }
}

class JoyShine extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;

  const JoyShine({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  });

  @override
  State<JoyShine> createState() => _JoyShineState();
}

class _JoyShineState extends State<JoyShine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final progress = _controller.value;
                  final dx = -220 + (progress * 520);

                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: Transform.rotate(
                      angle: -0.55,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 70,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.20),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class JoyShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final int durationMs;

  const JoyShimmerText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow,
    this.durationMs = 2200,
  });

  @override
  State<JoyShimmerText> createState() => _JoyShimmerTextState();
}

class _JoyShimmerTextState extends State<JoyShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.style.color ?? Colors.white;

    return AnimatedBuilder(
      animation: _controller,
      child: Text(
        widget.text,
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
        style: widget.style.copyWith(
          color: Colors.white,
        ),
      ),
      builder: (context, child) {
        final value = _controller.value;

        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                baseColor.withValues(alpha: 0.88),
                Colors.white,
                baseColor.withValues(alpha: 0.88),
              ],
              stops: const [
                0.25,
                0.50,
                0.75,
              ],
              begin: Alignment(-1.8 + (value * 3.6), -0.4),
              end: Alignment(-0.8 + (value * 3.6), 0.4),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}