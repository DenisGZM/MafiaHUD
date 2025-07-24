import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:window_manager_plus/window_manager_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'util.dart';

int cardWidth = 180;
int cardHeight = 250;

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

class ControlsApp extends StatelessWidget {
  final WindowManagerPlus controller;

  const ControlsApp(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controls Window',
      home: ControlsScreen(controller),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(
          seedColor:  Colors.amber,
          brightness: Brightness.light,
          dynamicSchemeVariant: DynamicSchemeVariant.neutral,
          secondaryContainer: Color.fromARGB(255, 240, 219, 128),
          tertiaryContainer: Color.fromARGB(255, 207, 137, 6)
        ),
        useMaterial3: true,
        textTheme: TextTheme(
          bodyMedium: GoogleFonts.sanchez(fontSize: 16),
          displaySmall: GoogleFonts.rubik(fontSize: 10),
          displayMedium: GoogleFonts.rubik(fontSize: 16),
          displayLarge: GoogleFonts.rubik(fontSize: 22))
      ),
      color: Colors.blue,
    );
  }
}

class ControlsScreen extends StatefulWidget {
  final WindowManagerPlus controller;

  const ControlsScreen(this.controller, {Key? key}) : super(key: key);

  @override
  State<ControlsScreen> createState() => _ControlsScreenState();
}

class _ControlsScreenState extends State<ControlsScreen> {
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
  List<String> activeRoles = List.filled(10, 'civ');
  List<String> activeStates = List.filled(10, 'sit');
  List<TextEditingController> nameControllers = List<TextEditingController>.generate(10, (int index) => TextEditingController(text: 'Player ${index+1}'));

  Widget getImage(int index) {
    if (images[index] == 'default') {
      return Image.asset('assets/default.png',
        height: 30,
        width: 30,
        fit: BoxFit.cover);
    }
    return Image.memory(File(images[index]).readAsBytesSync(),
      height: 30,
      width: 30,
      fit: BoxFit.cover);
  }

  Widget PlayerRole(int index, String role) {
    return GestureDetector(
      onTap: () {
        setState(() {
          activeRoles[index] = role;
        });
        WindowManagerPlus.current.invokeMethodToWindow(0, 'updateRoles', { index: role });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
          boxShadow: [BoxShadow(blurRadius: 5, spreadRadius: 1,
                                color: activeRoles[index] == role
                                ? Color.fromARGB(255, 255, 17, 0)
                                : Colors.white)],
          border: BoxBorder.all(
            color: Theme.of(context).colorScheme.onSecondary,
            width: 0.8
          ),
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(100)),
          child: Image.asset('assets/$role.png', width: 30, height: 30, fit: BoxFit.none)
        )
      )
    );
  }

  Widget PlayerState(int index, String state) {
    return GestureDetector(
      onTap: () {
        setState(() {
          activeStates[index] = state;
        });
        WindowManagerPlus.current.invokeMethodToWindow(0, 'updateState', { index: state });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
          boxShadow: [BoxShadow(blurRadius: 5, spreadRadius: 1,
                                color: activeStates[index] == state
                                ? Color.fromARGB(255, 255, 17, 0)
                                : Colors.white)],
          border: BoxBorder.all(
            color: Theme.of(context).colorScheme.onSecondary,
            width: 0.8
          ),
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(100)),
          child: Image.asset('assets/$state.png', width: 30, height: 30, fit: BoxFit.none)
        )
      )
    );
  }

  Future<void> pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      img.Image? decodedImg = img.decodeImage(imageFile.readAsBytesSync());
      if ( decodedImg == null ) { 
        print('Error decoding image');
        return;
      }
      final encodedImg = img.encodePng(decodedImg);
      final dir = Directory('players'); 
      dir.createSync();
      File('${dir.path}/${index+1}.png').writeAsBytesSync(encodedImg);
      setState(() {
        images[index] = '${dir.path}/${index+1}.png';
      });
      WindowManagerPlus.current.invokeMethodToWindow(0, 'updateImage', {index: images[index]});
    }
    return;
  }

  void swapDir(int index, bool isUp) {
    int direction = isUp ? -1 : 1;
    final dir = Directory('players'); 
    File curFile = File('${dir.path}/${index+1}.png');
    File swapFile = File('${dir.path}/${index+direction+1}.png');
    Uint8List tmpBuffer = curFile.readAsBytesSync();
    curFile.writeAsBytesSync(swapFile.readAsBytesSync());
    swapFile.writeAsBytesSync(tmpBuffer);

    setState(() {
      var nick = nameControllers[index];
      nameControllers[index] = nameControllers[index+direction];
      nameControllers[index+direction] = nick;
    });

    WindowManagerPlus.current.invokeMethodToWindow(0, 'resetRoles', {});
    WindowManagerPlus.current.invokeMethodToWindow(0, 'resetStates', {});
    WindowManagerPlus.current.invokeMethodToWindow(0, 'updateName', {index: nameControllers[index].text, index+direction: nameControllers[index+direction].text,});
    WindowManagerPlus.current.invokeMethodToWindow(0, 'updateImage', {index: '${dir.path}/${index+1}.png', index+direction: '${dir.path}/${index+direction+1}.png', });
  }

  bool allowArrow(int index, bool isUp) {
    int direction = isUp ? -1 : 1;
    if ( isUp && index > 0 && images[index] != 'default' && images[index+direction] != 'default' ) {
      return true;
    }
    if ( !isUp && index < 9 && images[index] != 'default' && images[index+direction] != 'default' ) {
      return true;
    }
    return false;
  }

  Widget getArrow(int index, bool isUp) {
    if (allowArrow(index, isUp)) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => swapDir(index, isUp),
            child: Image.asset(isUp ? 'assets/up.png' : 'assets/down.png', color: Colors.black, height: 10, width: 10),
        )
      );
    }
    return Container();
  }

  Widget PlayerInfo(int index) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(50), right: Radius.circular(50)),
        border: BoxBorder.all(color: Colors.black, width: 0.3)
      ),
      child: Row(spacing:15, children: [
        Column(children: [
          getArrow(index, true),
          Text('${index+1}', style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 20)),
          getArrow(index, false),
        ]),
        GestureDetector(
          onDoubleTap: () => pickImage(index),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: getImage(index)
          )
        ),
        PlayerRole(index, 'civ'),
        PlayerRole(index, 'star'),
        PlayerRole(index, 'gun'),
        PlayerRole(index, 'don'),
        Container(width: 200, height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: BoxBorder.all(color: Theme.of(context).colorScheme.onTertiaryContainer, width: 2),
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.all(Radius.circular(15))
          ),
          // decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(5)), color: Theme.of(context).colorScheme.secondaryContainer),
          child: EditableTextWidget(index, nameControllers[index])
        ),
        GestureDetector(
          onTap: () {
            WindowManagerPlus.current.invokeMethodToWindow(0, 'updateFont', { index: 0.5});
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Image.asset('assets/plus.png', width: 30, height: 30)
          )
        ),
        GestureDetector(
          onTap: () {
            WindowManagerPlus.current.invokeMethodToWindow(0, 'updateFont', { index: -0.5});
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Image.asset('assets/minus.png', width: 30, height: 30)
          )
        ),
        PlayerState(index, 'sit'),
        PlayerState(index, 'voted'),
        PlayerState(index, 'shoot'),
        PlayerState(index, 'disqual'),
      ])
    );
  }

  Widget PlayerList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Column(
        spacing: 5,
        children: List.generate(10, (index) => PlayerInfo(index))
      ),
      Padding(
        padding: EdgeInsets.only(top: 20, left: 130),
        // child: FittedBox(
        child: Row(
          spacing: 20,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  activeRoles = List.filled(10, 'civ');
                });
                WindowManagerPlus.current.invokeMethodToWindow(0, 'resetRoles', {});
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  width: 120, height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Theme.of(context).colorScheme.onTertiaryContainer, width: 2),
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.all(Radius.circular(15))
                  ),
                  child: Text('Reset roles', style: TextStyle(color: Theme.of(context).colorScheme.onSecondary))
                )
              )
            ),
            SizedBox(width: 35),
            GestureDetector(
              onTap: () {
                WindowManagerPlus.current.invokeMethodToWindow(0, 'updateName', {for (var v in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]) v: nameControllers[v].text});
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  // margin: EdgeInsets.all(50),
                  width: 180, height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Theme.of(context).colorScheme.onTertiaryContainer, width: 2),
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.all(Radius.circular(15))
                  ),
                  child: Padding(padding: EdgeInsets.only(left: 20), child: Row(
                    spacing: 10,
                    children: [
                    Text('Apply names', textAlign: TextAlign.right, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                    Image.asset('assets/submit.png', width: 30, height: 30)
                  ])
                  )
                )
              )
            ),
            SizedBox(width: 85),
            GestureDetector(
              onTap: () {
                setState(() {
                  activeStates = List.filled(10, 'sit');
                });
                WindowManagerPlus.current.invokeMethodToWindow(0, 'resetStates', {});
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  width: 120, height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Theme.of(context).colorScheme.onTertiaryContainer, width: 2),
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.all(Radius.circular(15))
                  ),
                  child: Text('Reset states', style: TextStyle(color: Theme.of(context).colorScheme.onSecondary))
                )
              )
            ),
          ]
        )
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: Center(
        child: Row(children: [
          Column(children: [
            Container(
              margin: EdgeInsets.only(left: 25, top: 10, bottom: 0, right: 25),
              height: 40,
              alignment: Alignment.center,
              child: Text('Player Info', style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontSize: 25, fontWeight: FontWeight.bold))),
            Container(
              margin: EdgeInsets.all(25),
              child:  PlayerList()),
          ]),
          Container(
            // Game info
          )
        ],)
      )
    );
  }
}

class HudApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Mafia HUD',
      home: ImageRowScreen(),
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
      onEditingComplete: () => WindowManagerPlus.current.invokeMethodToWindow(0, 'updateName', {index: _controller.text}),
    );
  }
}


class ImageRowScreen extends StatefulWidget {
  @override
  State<ImageRowScreen> createState() => _ImageRowScreenState();
}

class _ImageRowScreenState extends State<ImageRowScreen> with WindowListener {
  @override
  void initState() {
    super.initState();
    WindowManagerPlus.current.addListener(this);
  }

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
          images[key] = imgFile.existsSync()
                        ? value
                        : images[key];
        });
        imageCache.clear();
        imageCache.clearLiveImages();
      });
    }
  }

  final int imageCount = 10;
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

  Widget getRole(int index) {
    if (roles[index] != 'civ') {
      return ContainerWithShadow(
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
    return Image.memory(File(images[index]).readAsBytesSync(),
      height: cardHeight.toDouble(),
      width: cardWidth.toDouble(),
      fit: BoxFit.cover);
  }

  void _animateImage(int index) {
    setState(() {
      isMovedDown[index] = !isMovedDown[index];
      isGrayscale[index] = !isGrayscale[index];
    });
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
                        border: Border.all(color: Theme.of(context).colorScheme.primaryContainer, width: 1.5),
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