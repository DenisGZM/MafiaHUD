import 'package:flutter/material.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

class EditableTextWidget extends StatelessWidget {
  final int index;
  final TextEditingController _controller;
  EditableTextWidget(this.index, this._controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onSecondaryContainer),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.only(bottom: 20),
        border: InputBorder.none,
        filled: false,
      ),
      onTapOutside: (event) { FocusManager.instance.primaryFocus?.unfocus(); WindowManagerPlus.current.invokeMethodToWindow(0, 'updateName', {index: _controller.text}); },
      onEditingComplete: () { FocusManager.instance.primaryFocus?.unfocus(); WindowManagerPlus.current.invokeMethodToWindow(0, 'updateName', {index: _controller.text}); },
    );
  }
}

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
        onDoubleTap: onDoubleTap ?? () async => (await WindowManagerPlus.current.isMaximized()) ? WindowManagerPlus.current.restore() : WindowManagerPlus.current.maximize(),
        child: child ?? Container());
  }
}

class MoveWindow extends StatelessWidget {
  final Widget? child;
  final VoidCallback? onDoubleTap;
  MoveWindow({Key? key, this.child, this.onDoubleTap}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    if (child == null) return _MoveWindow(onDoubleTap: onDoubleTap);
    return _MoveWindow(
      onDoubleTap: onDoubleTap,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: child!)]),
    );
  }
}


class ContainerWithShadow extends StatelessWidget {
  final double height;
  final double width;
  final ColorScheme? colorScheme;
  final child;
  ContainerWithShadow({Key? key, required this.height, required this.width, required this.child, this.colorScheme}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(blurRadius: 5, spreadRadius: 0.5)],
        border: BoxBorder.all(
          color: colorScheme != null ? colorScheme!.onPrimary : Theme.of(context).colorScheme.onPrimary,
          width: 0.8
        ),
        color: colorScheme != null ? colorScheme!.primary : Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(100)),
      child: child,
      key: key);
  }
} 