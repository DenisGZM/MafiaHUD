import 'package:flutter/material.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

class _MoveWindow extends StatelessWidget {
  _MoveWindow({Key? key, this.child, this.onDoubleTap}) : super(key: key);
  final Widget? child;
  final VoidCallback? onDoubleTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (details) {
          WindowManagerPlus.current.startDragging();
        },
        onDoubleTap: this.onDoubleTap ?? () async => (await WindowManagerPlus.current.isMaximized()) ? WindowManagerPlus.current.restore() : WindowManagerPlus.current.maximize(),
        child: this.child ?? Container());
  }
}

class MoveWindow extends StatelessWidget {
  final Widget? child;
  final VoidCallback? onDoubleTap;
  MoveWindow({Key? key, this.child, this.onDoubleTap}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    if (child == null) return _MoveWindow(onDoubleTap: this.onDoubleTap);
    return _MoveWindow(
      onDoubleTap: this.onDoubleTap,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: this.child!)]),
    );
  }
}


class ContainerWithShadow extends StatelessWidget {
  final double height;
  final double width;
  final Color? color;
  final child;
  ContainerWithShadow({Key? key, required this.height, required this.width, required this.child, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(blurRadius: 5, spreadRadius: 0.5)],
        border: BoxBorder.all(
          color: color != null ? color! : Theme.of(context).colorScheme.onPrimary,
          width: 0.8
        ),
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(100)),
      child: child,
      key: key);
  }
} 