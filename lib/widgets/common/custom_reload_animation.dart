import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:convert';

class CustomReloadAnimation extends StatefulWidget {
  final double size;
  final bool isAnimating;
  final VoidCallback? onTap;
  final Color? color;

  const CustomReloadAnimation({
    Key? key,
    this.size = 40.0,
    this.isAnimating = false,
    this.onTap,
    this.color,
  }) : super(key: key);

  @override
  State<CustomReloadAnimation> createState() => _CustomReloadAnimationState();
}

class _CustomReloadAnimationState extends State<CustomReloadAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(CustomReloadAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _controller.repeat();
    } else if (!widget.isAnimating && oldWidget.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Your provided Lottie JSON data
  static const String _lottieJson = '''
{
  "v": "5.5.2",
  "fr": 60,
  "ip": 0,
  "op": 60,
  "w": 512,
  "h": 512,
  "nm": "Loading",
  "ddd": 0,
  "assets": [],
  "layers": [
    {
      "ddd": 0,
      "ind": 1,
      "ty": 4,
      "nm": "Circle",
      "td": 1,
      "sr": 1,
      "ks": {
        "o": { "a": 0, "k": 100, "ix": 11 },
        "r": {
          "a": 1,
          "k": [
            { "t": 0, "s": [0], "h": 1 },
            { "t": 60, "s": [360], "h": 1 }
          ],
          "ix": 10
        },
        "p": { "a": 0, "k": [256, 256, 0], "ix": 2 },
        "a": { "a": 0, "k": [0, 0, 0], "ix": 1 },
        "s": { "a": 0, "k": [100, 100, 100], "ix": 6 }
      },
      "ao": 0,
      "shapes": [
        {
          "ty": "gr",
          "it": [
            {
              "ty": "el",
              "p": { "a": 0, "k": [0, 0], "ix": 3 },
              "s": { "a": 0, "k": [40, 40], "ix": 4 }
            },
            {
              "ty": "st",
              "c": { "a": 0, "k": [0.149, 0.447, 0.878, 1] },
              "o": { "a": 0, "k": 100 },
              "w": { "a": 0, "k": 6 },
              "lc": 2,
              "lj": 1
            },
            { "ty": "tr", "p": { "a": 0, "k": [0, 0] } }
          ]
        }
      ]
    }
  ]
}
''';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.size,
        height: widget.size,
        child: widget.isAnimating
            ? Lottie.memory(
                utf8.encode(_lottieJson),
                controller: _controller,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
                delegates: LottieDelegates(
                  values: [
                    // Customize the color if provided
                    if (widget.color != null)
                      ValueDelegate.strokeColor(
                        const ['Circle', 'Group 1', 'Ellipse 1'],
                        value: widget.color!,
                      ),
                  ],
                ),
              )
            : Icon(
                Icons.refresh,
                size: widget.size * 0.6,
                color: widget.color ?? Theme.of(context).iconTheme.color,
              ),
      ),
    );
  }
}

// Alternative simpler reload widget for when Lottie isn't available
class SimpleReloadAnimation extends StatefulWidget {
  final double size;
  final bool isAnimating;
  final VoidCallback? onTap;
  final Color? color;

  const SimpleReloadAnimation({
    Key? key,
    this.size = 40.0,
    this.isAnimating = false,
    this.onTap,
    this.color,
  }) : super(key: key);

  @override
  State<SimpleReloadAnimation> createState() => _SimpleReloadAnimationState();
}

class _SimpleReloadAnimationState extends State<SimpleReloadAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    if (widget.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(SimpleReloadAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _controller.repeat();
    } else if (!widget.isAnimating && oldWidget.isAnimating) {
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
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _controller.value * 2 * 3.14159,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color ?? Theme.of(context).primaryColor,
                    width: 3,
                  ),
                  gradient: widget.isAnimating
                      ? SweepGradient(
                          colors: [
                            (widget.color ?? Theme.of(context).primaryColor)
                                .withOpacity(0.1),
                            widget.color ?? Theme.of(context).primaryColor,
                          ],
                          stops: const [0.0, 0.8],
                        )
                      : null,
                ),
                child: Center(
                  child: Icon(
                    Icons.refresh,
                    size: widget.size * 0.4,
                    color: widget.color ?? Theme.of(context).primaryColor,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}