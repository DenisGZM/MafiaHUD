import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import 'controls.dart';
import 'hud.dart';


Future<int> main(List<String> args) async {
  if ( kDebugMode ) print(args);

  WidgetsFlutterBinding.ensureInitialized();
  int windowId = args.isEmpty ? 0 : int.tryParse(args[0]) ?? 0;
  if ( kDebugMode ) print('Window ID: $windowId');
  await WindowManagerPlus.ensureInitialized(windowId);

  WindowOptions hudOptions = const WindowOptions(
    size: Size(1920, 1080),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );

  WindowOptions controlsOptions = const WindowOptions(
    size: Size(1200, 1200),
    center: true,
    backgroundColor: Color.fromARGB(255, 255, 251, 37),
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    windowButtonVisibility: true,
  );

  if ( windowId == 0 ) {
    WindowManagerPlus.current.waitUntilReadyToShow(hudOptions, () async {
      await WindowManagerPlus.current.show();
    });
  } else {
    WindowManagerPlus.current.waitUntilReadyToShow(controlsOptions, () async {
      await WindowManagerPlus.current.show();
      await WindowManagerPlus.current.focus();
    });
  }

  if (WindowManagerPlus.current.id == 0) {
    WindowManagerPlus? controlsWindow = await WindowManagerPlus.createWindow([]);
    if ( controlsWindow == null ) {
      if ( kDebugMode ) print('Failed to create controls window');
      return -1;
    }
    runApp(HudApp());
  } else {
    if ( kDebugMode ) print('Running controls\n');
    runApp(ControlsApp(WindowManagerPlus.current));
  }

  return 0; // Return value is not used in Flutter apps, but required for main function.
}
