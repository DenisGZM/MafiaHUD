import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager_plus/window_manager_plus.dart';
import 'util.dart';


int cardWidth = 180;
int cardHeight = 250;

final ColorScheme civilianScheme = ColorScheme.fromSeed(
  seedColor: Colors.yellowAccent,
  brightness: Brightness.dark,
  contrastLevel: 0.5,
  primaryContainer: Color.fromARGB(255, 207, 161, 11));

final ColorScheme sheriffScheme = ColorScheme.fromSeed(
  seedColor: const Color.fromARGB(255, 39, 68, 44),
  brightness: Brightness.dark,
  primary: Color.fromARGB(255, 114, 201, 128));

final ColorScheme gunScheme = ColorScheme.fromSeed(
  seedColor: const Color.fromARGB(255, 27, 27, 27),
  brightness: Brightness.dark,
  primary: Color.fromARGB(255, 136, 136, 136));

final ColorScheme donScheme = ColorScheme.fromSeed(
  seedColor: const Color.fromARGB(255, 24, 0, 31),
  brightness: Brightness.dark,
  primary: Color.fromARGB(255, 127, 0, 158));

class HudApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Mafia HUD',
      home: OverlayScreen(),
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.yellowAccent,
          brightness: Brightness.dark,
          contrastLevel: 0.5,
          primaryContainer: Color.fromARGB(255, 207, 161, 11)),
        textTheme: TextTheme(
          bodyMedium: GoogleFonts.rubik(fontSize: 16),
          titleMedium: GoogleFonts.rubik(fontSize: 20),
          displaySmall: GoogleFonts.rubik(fontSize: 10),
          displayMedium: GoogleFonts.rubik(fontSize: 16),
          displayLarge: GoogleFonts.rubik(fontSize: 22)
        ))
    );
  }
}

class OverlayScreen extends StatefulWidget {
  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> with WindowListener {
  Map<String, ColorScheme> roleSchemes = {
    'civ': civilianScheme,
    'star': sheriffScheme,
    'don': donScheme,
    'gun': gunScheme,
  };
  final int imageCount = 10;
  List<Uint8List> imagesBytes = List<Uint8List>.filled(10, Uint8List(0));
  List<String> images = List<String>.generate(10, (int index) {
    Directory dir = Directory('players');
    if ( !dir.existsSync() ) {
      return 'default';
    }
    File imgFile = File('${dir.path}/${index+1}.png');
    return imgFile.existsSync()
           ? '${dir.path}/${index+1}.png'
           : 'default';
  });
  List<String> roles = List<String>.filled(10, 'civ');
  List<String> state = List<String>.filled(10, 'sit');

  List<String> nicknames = List<String>.generate(10, (int index) => 'Player ${index+1}');
  List<double> nickfont = List<double>.filled(10, 16);

  // TODO: dynamic table info
  late List<int> nominatations;
  late List<int> kills;
  late List<int> donChecks;
  late List<int> sheriffChecks;

  // Для анимации
  List<bool> isMovedDown = List<bool>.filled(10, false);
  List<bool> isGrayscale = List<bool>.filled(10, false);


  @override
  void initState() {
    super.initState();
    WindowManagerPlus.current.addListener(this);
  }

  // Handle events from control window
  @override
  Future<void> onEventFromWindow(String eventName, int fromWindowId, arguments) async {
    print('[WindowManager] onWindowEvent: $eventName from $fromWindowId with args: $arguments');
    if (eventName == 'updateRoles') {
      setState(() {
        arguments.forEach((key, value) {
          if (key < roles.length) {
            roles[key] = value;
          }
        });
      });
      return;
    }
    if (eventName == 'updateName') {
      setState(() {
        arguments.forEach((key, value) {
          nicknames[key] = value;
        });
      });
      return;
    }
    if (eventName == 'updateState') {
      setState(() {
        arguments.forEach((key, value) {
          state[key] = value;
          isMovedDown[key] = value != 'sit' ? true : false;
          isGrayscale[key] = value != 'sit' ? true : false;
        });
      });
    }
    if (eventName == 'updateFont') {
      setState(() {
        arguments.forEach((key, value) {
          nickfont[key] += value;
        });
      });
      return;
    }
    if (eventName == 'resetRoles') {
      setState(() {
        roles = List<String>.filled(10, 'civ');
      });
      return;
    }
    if (eventName == 'resetStates') {
      setState(() {
        isGrayscale = List.filled(10, false);
        isMovedDown = List.filled(10, false);
        state = List<String>.filled(10, 'sit');
      });
      return;
    }
    if (eventName == 'updateImage') {
      setState(() {
        arguments.forEach((key, value) {
          File imgFile = File(value);
          if ( imgFile.existsSync() ) {
            images[key] = value;
            imagesBytes[key] = imgFile.readAsBytesSync();
          }
        });
        // imageCache.clear();
        // imageCache.clearLiveImages();
      });
    }
  }

  // Widget getters
  Widget getRole(int index) {
    if (roles[index] != 'civ') {
      return ContainerWithShadow(
        colorScheme: roleSchemes[roles[index]],
        height: 40,
        width: 40,
        child: Image.asset('assets/${roles[index]}.png', fit: BoxFit.none, width: 30, height: 30)
      );
    }
    return Container();
  }

  Widget getState(int index) {
    if (state[index] != 'sit') {
      return ContainerWithShadow(
        height: 40,
        width: 40,
        child: Image.asset('assets/${state[index]}.png', fit: BoxFit.none, width: 30, height: 30)
      );
    }
    return Container();
  }

  Widget getImage(int index) {
    if (images[index] == 'default') {
      return Image.asset('assets/default.png',
        height: cardHeight.toDouble(),
        width: cardWidth.toDouble(),
        fit: BoxFit.cover);
    }
    if (imagesBytes[index].isEmpty) {
      imagesBytes[index] = File(images[index]).readAsBytesSync();
    }
    return Image.memory(imagesBytes[index],
      height: cardHeight.toDouble(),
      width: cardWidth.toDouble(),
      fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        SizedBox(height: 40, child: MoveWindow(
          child: Container(
            color: kDebugMode ? Color.fromARGB(87, 133, 133, 133) : Colors.transparent
          )
        )),
        // TODO: Enable table info
        // Column(children: [
        //   TableSeparatedInfo(['Table', 'Game']),
        // ]),
        SizedBox(height: 150, child: Container(color: kDebugMode ? Color.fromARGB(158, 138, 219, 100) : Colors.transparent)),
        Expanded(flex: 1, child: Container(color:  Colors.transparent)),
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(imageCount, (index) {
                return Container(
                  // Внешний контейнер для управления смещением только выбранной картинки
                  margin: EdgeInsets.symmetric(horizontal: 6),
                  child: 
                  Stack(children: [
                  AnimatedPadding(
                    duration: Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.only(top: isMovedDown[index] ? 25 : 0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.primaryContainer, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ColorFiltered(
                          colorFilter: isGrayscale[index]
                              ? const ColorFilter.matrix(<double>[
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0, 0, 0, 1, 0,
                                ])
                              : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                          child: SizedBox(
                            width: cardWidth.toDouble(),
                            height: cardHeight.toDouble(),
                            child: Stack(
                              children: [
                                getImage(index),
                                Positioned(top: cardHeight - 30, child: 
                                  SizedBox(child: Container(
                                    alignment: Alignment.center,
                                    height: 30,
                                    width: cardWidth.toDouble(),
                                    color: Theme.of(context).colorScheme.primary,
                                    child: Row(children: [
                                      FittedBox(fit: BoxFit.fill, child: Container(
                                        width: 30,
                                        height: 30,
                                        alignment: Alignment.center,
                                        color: Theme.of(context).colorScheme.primaryContainer,
                                        child: Text('${index+1}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 22, color: Theme.of(context).colorScheme.onPrimaryContainer)))
                                      ),
                                      Container(width: cardWidth - 30, child: Text(nicknames[index], textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: nickfont[index]), overflow: TextOverflow.clip, maxLines: 1))
                                    ])
                                  ))
                                ),
                                Positioned(left: 7, top: 7, child: getRole(index)),
                                Positioned(right: 7, top: 7, child: getState(index)),
                              ],
                            ),
                          )
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: cardHeight+30)
                ])
                );
              }),
            ),
          ),
        ),
      ]),
    );
  }
}


class IncrementText extends StatefulWidget {
  final String text;
  const IncrementText(this.text, {Key? key}) : super(key: key);

  @override
  State<IncrementText> createState() => _IncrementTextState();
}

class _IncrementTextState extends State<IncrementText> {
  int increment = 1;
  void increase() { setState(() { increment++; }); }
  void decrease() { setState(() { increment--; }); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => increase(),
      onSecondaryTap: () => decrease(),
      child: Text('${widget.text} $increment', style:
        Theme.of(context).textTheme.titleMedium!.copyWith(
          color: Theme.of(context).colorScheme.onPrimary))
    );
  }
}

class TableSeparatedInfo extends StatefulWidget {
  final List<String> Texts;
  const TableSeparatedInfo(this.Texts, {Key? key}) : super(key: key);

  @override
  State<TableSeparatedInfo> createState() => _TableSeparatedInfoState();
}

class _TableSeparatedInfoState extends State<TableSeparatedInfo> {
  late List<bool> isHidden;
  int separateIndex = 0;

  @override
  void initState() {
    super.initState();
    isHidden = List<bool>.filled(widget.Texts.length, false);
  }

  void toggleVisibility(int index) {
    setState(() {
      int visibleCount = isHidden.fold(0, (count, hidden) => count + (hidden ? 0 : 1));
      if (visibleCount == 1) {
        return; // Не скрываем последний элемент
      }
      isHidden[index] = !isHidden[index];
      while (separateIndex < isHidden.length - 1 && isHidden[separateIndex]) {
        separateIndex++;
      }
    });
  }

  void resetVisibility() {
    setState(() {
      isHidden = List<bool>.filled(widget.Texts.length, false);
      separateIndex = 0;
    });
  }

  Widget getWidget(int index) {
    Widget SeparatorWidget = index > separateIndex ?
        Image.asset('assets/pipe.png', height: 30, fit: BoxFit.fill, color: Theme.of(context).colorScheme.onPrimary) :
        Container(color: Colors.transparent);
    if (!isHidden[index]) {
      return Row(children: [
        SeparatorWidget,
        IncrementText(widget.Texts[index]),
      ]);
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        margin: EdgeInsets.all(10),
        padding: EdgeInsets.fromLTRB(10,5,10,5),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Theme.of(context).colorScheme.primary),
        child: Row(children: List.generate(widget.Texts.length, (index) {
          return GestureDetector(
            onLongPress: () => toggleVisibility(index),
            onSecondaryLongPress: () => resetVisibility(),
            child: getWidget(index)
          );
        })
        )
      ),
    ]);
  }
}