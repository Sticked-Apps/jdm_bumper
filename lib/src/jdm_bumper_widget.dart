import 'dart:math';

import 'package:flutter/material.dart';

const _tileSizeDefault = 150.0;
const _stepSizeDefault = 100;

class JdmBumper extends StatelessWidget {
  const JdmBumper({
    Key? key,
    required this.stickerBuilders,
    this.tileSize = _tileSizeDefault,
    this.stepSize = _stepSizeDefault,
    this.reverse = true,
    this.layers = 1,
    this.onFinished,
  }) : super(key: key);

  final Set<WidgetBuilder> stickerBuilders;
  final double tileSize;
  final int stepSize;
  final bool reverse;
  final int layers;
  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => _JdmBumper(
          tileSize: tileSize,
          stepSize: stepSize,
          reverse: reverse,
          size: Size(
            constraints.maxWidth,
            constraints.maxHeight,
          ),
          stickerBuilders: stickerBuilders,
          layers: layers,
          onFinished: onFinished,
        ),
      );
}

class _JdmBumper extends StatefulWidget {
  const _JdmBumper({
    Key? key,
    required this.tileSize,
    required this.stepSize,
    required this.reverse,
    required this.size,
    required this.stickerBuilders,
    required this.layers,
    this.onFinished,
  }) : super(key: key);

  final double tileSize;
  final int stepSize;
  final bool reverse;
  final Size size;
  final Set<WidgetBuilder> stickerBuilders;
  final int layers;
  final VoidCallback? onFinished;

  @override
  State<_JdmBumper> createState() => _JdmBumperState();
}

class _JdmBumperState extends State<_JdmBumper> {
  final List<Widget> tiles = [];

  var isReversed = false;

  @override
  void initState() {
    super.initState();

    final tileSize = widget.tileSize;
    final stepSize = widget.stepSize;

    final width = widget.size.width.ceil();
    final height = widget.size.height.ceil();
    final offsets = <Offset>[];

    final delta = (tileSize - stepSize) / 4;
    final random = Random();

    for (int i = 0; i < widget.layers; i++) {
      for (int x = -tileSize ~/ 2; x < width; x += stepSize) {
        for (int y = -tileSize ~/ 2; y < height; y += stepSize) {
          offsets.add(
            Offset(
              x.toDouble(),
              y.toDouble(),
            ).translate(
              (random.nextBool() ? 1 : -1) * random.nextDouble() * delta,
              (random.nextBool() ? 1 : -1) * random.nextDouble() * delta,
            ),
          );
        }
      }
    }
    offsets.shuffle();

    tiles.addAll(
      offsets.map(
        (offset) => _PositionedTile.generate(
          offset: offset,
          size: tileSize.toDouble(),
          builders: widget.stickerBuilders,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => isReversed
      ? TweenAnimationBuilder(
          tween: IntTween(begin: tiles.length, end: 0),
          duration: const Duration(seconds: 1),
          curve: Curves.fastOutSlowIn,
          builder: (context, value, _) => Stack(
            children: tiles.take(value).toList(),
          ),
          onEnd: widget.onFinished,
        )
      : TweenAnimationBuilder(
          tween: IntTween(begin: 0, end: tiles.length),
          duration: const Duration(seconds: 2),
          curve: Curves.easeInQuad,
          builder: (context, value, _) => Stack(
            children: tiles.take(value).toList(),
          ),
          onEnd: () => Future.delayed(
            const Duration(seconds: 1),
            widget.reverse ? () => setState(() => isReversed = true) : widget.onFinished?.call,
          ),
        );
}

class _PositionedTile extends StatelessWidget {
  final Offset offset;
  final double size;
  final WidgetBuilder builder;

  const _PositionedTile._(this.offset, this.builder, this.size);

  factory _PositionedTile.generate({
    required Offset offset,
    required double size,
    required Set<WidgetBuilder> builders,
  }) =>
      _PositionedTile._(
        offset,
        builders.randomElement(),
        size,
      );

  @override
  Widget build(BuildContext context) => Positioned(
        left: offset.dx,
        top: offset.dy,
        child: SizedBox(
          width: size,
          height: size,
          child: builder(context),
        ),
      );
}

extension<T> on Set<T> {
  T randomElement() => elementAt(Random().nextInt(length));
}
