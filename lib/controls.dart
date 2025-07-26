import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:window_manager_plus/window_manager_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'util.dart';


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