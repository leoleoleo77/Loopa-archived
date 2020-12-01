import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:record_mp3/record_mp3.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_button/animated_button.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  String dropdownValue = 'LOOP_1';

  String temp1 = "LOOP_1";
  String temp2 = "LOOP_2";

  int loopDelay = 50;

  int loopSelector = 1;

  bool isRecording = false;

  //for some reason after the first loop, the timer counts down twice before looping
  //so i made this variable to track when the first loop is done, so i can manually
  //fix the count down.
  bool firstLoopIsDone = false;

  //AudioPlayer audioPlayer1 = AudioPlayer();
  AudioPlayer audioPlayer1 = AudioPlayer();
  AudioPlayer audioPlayer2 = AudioPlayer();

  Stopwatch timer1 = Stopwatch();
  Stopwatch timer2 = Stopwatch();


  double volumeValue = 100;

  //creates a stopwatch that counts the recording's session duration
  //Stopwatch stopwatch = new Stopwatch();

  //the variable is which the stopwatch's duration is stored
  List<int> stopwatchDuration = List(4);
  //menuState states the state of the menu, if the menu is open then it's true
  //otherwise it's false. it changes when the drop-down button is pressed.
  bool menuState = false;

  //appPhase is used to track the phase of the app (if it's recording or looping)
  //see LoopFunction
  List<int> appPhase = [1, 1];

  //continuePlaying is used to control the looping of the audio
  //when true, the looper is running, and when its false, it doesn't
  List<bool> continuePlaying = [false, false, false, false];

  //statusText is useless for now
  String statusText = "";

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  //This is where the UI is made
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        //appBar: AppBar(
          //: Colors.red,
        //),
        body: Container(
          color: Colors.red,
          alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(top: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget> [
                  FractionallySizedBox(
                    widthFactor: 0.95,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 500),
                      height: !menuState? 50 : 320,
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Stack(
                        children: [
 //------------------------------VOLUME SLIDER------------------------------//
                          Padding(
                            padding: const EdgeInsets.only(bottom: 80.0),
                            child: AnimatedOpacity(
                              opacity: menuState ? 1.0 : 0.0,
                              duration: Duration(milliseconds: 500),
                              child: Align(
                                alignment: Alignment.bottomLeft,
                                child: Container(
                                  height: 50,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: Text("MIN",
                                              style:
                                                TextStyle(
                                                  color: Colors.grey[300],
                                                  fontSize: 11.0,
                                                ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 10,
                                        child: SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            activeTrackColor: Colors.grey[300],
                                            inactiveTrackColor: Colors.black,
                                            thumbColor: Colors.grey,
                                            overlayColor: Colors.red.withAlpha(32),
                                            overlayShape: RoundSliderOverlayShape(overlayRadius: 2.0),
                                            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7.0),
                                            trackHeight: 3.0,
                                          ),
                                          child: Slider(
                                            value: volumeValue,
                                            min: 0,
                                            max: 100,
                                            //divisions: 10,
                                            onChanged: (double value) {
                                              setState(() {
                                                volumeValue = value;
                                                //audioPlayer.setVolume(volumeValue);
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: FractionallySizedBox(
                                          widthFactor: 0.7,
                                          child: Text("MAX",
                                            style:
                                            TextStyle(
                                              color: Colors.grey[300],
                                              fontSize: 11.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 60.0),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: AnimatedOpacity(
                                opacity: menuState ? 1.0 : 0.0,
                                duration: Duration(milliseconds: 500),
                                child: Divider(
                                  color: Colors.white,
                                  thickness: 0.5,
                                  indent: 90,
                                  endIndent: 90,
                                ),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget> [
  //----------------------------RECORDING - PLAYING LIGHTS--------------------//
                              Expanded(
                                flex: 100,
                                child: Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 5.0),
                                    child: FractionallySizedBox(
                                      widthFactor: 0.8,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Text("REC", style: TextStyle(fontSize: 11.0, color: Colors.grey[300]),),
                                              CircleAvatar(
                                                backgroundColor: isRecording? Colors.redAccent[700] : Color.fromRGBO(51, 0, 0, 1),
                                                radius: 15,
                                              ),
                                            ],
                                          ),
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Text("PLAY", style: TextStyle(fontSize: 11.0, color: Colors.grey[300]),),
                                              CircleAvatar(
                                                backgroundColor: appPhase[loopSelector - 1] == 3? Colors.lightGreenAccent[400] : Colors.green[900],
                                                radius: 15,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
 //----------------------------DROP DOWN BUTTON-----------------------------//
                              Expanded(
                                flex: 100,
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    height: 40,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 20.0),
                                      child: FractionallySizedBox(
                                        widthFactor: 0.5,
                                        child: OverflowBox(
                                          maxHeight: 45,
                                          child: RaisedButton(
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: OverflowBox(
                                              maxHeight: 0,
                                              child: Icon(
                                                !menuState?
                                                  Icons.keyboard_arrow_down_rounded:
                                                  Icons.keyboard_arrow_up_rounded,
                                                color: Colors.grey[300],
                                              ),
                                            ),
                                            color: Colors.grey[850],
                                            onPressed: () {
                                              setState(() {
                                                menuState = !menuState;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
 //--------------------------LOOP SELECTOR----------------------//
                              Expanded(
                                flex: 100,
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    height: 50,
                                    child: OverflowBox(
                                      maxWidth: 150,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 30.0),
                                        child: FractionallySizedBox(
                                          widthFactor: 0.8,
                                          heightFactor: 0.8,
                                          child: Container(
                                            color: Colors.black87,
                                            child: Align(
                                              alignment: Alignment.center,
                                              child: DropdownButton<String>(
                                                value: dropdownValue,
                                                elevation: 16,
                                                iconSize: 0,
                                                dropdownColor: Colors.black,
                                                style:  GoogleFonts.pressStart2p(
                                                  fontSize: 13,
                                                  color: /*playing?*/ Colors.lightGreenAccent[400] /*: Colors.redAccent[700]*/,
                                                ),
                                                underline: Container(
                                                  height: 0,
                                                ),
                                                onChanged: (String newValue) {
                                                  setState(() {
                                                    dropdownValue = newValue;
                                                  });
                                                  ChangeLoop();
                                                },
                                                items: <String>[temp1 , temp2]
                                                    .map<DropdownMenuItem<String>>((String value) {
                                                  return DropdownMenuItem<String>(
                                                    value: value,
                                                    child: Text(value),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

   //-----------------------MAIN BUTTON-------------------------------------//

                  Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      padding: EdgeInsets.only(bottom: 10.0),
                      duration: Duration(milliseconds: 500),
                      height: !menuState? 585 : 315,
                      child: FractionallySizedBox(
                        widthFactor: 0.95,
                        child: RaisedButton(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            color: Colors.grey[850],
                            //color: Colors.grey[850],
                            //height: 200,
                            onPressed: () {
                              LoopFunction();
                            },
                            onLongPress: () {
                              DeleteLoop();
                              _displaySnackBar(context);
                            },
                            child: Text("$loopSelector"),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ),
      ),
    );
  }

  _displaySnackBar(BuildContext context) {
    final snackBar = SnackBar(
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 1),
      margin: EdgeInsets.all(20),
      content:
        Row(
          children: <Widget>[
            Icon(
              Icons.delete
            ),
            Text(
              "Loop Deleted"
            )
          ],
        ),
    );
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }


  //LoopFunction is called when the main button is pressed
  //it's function depends on the  appPhase's value
  //if the appPhase equals to 1 then when pressed, the app will start recording
  //if the appPhase equals to 2 then when pressed, the app will stop recording,
  //and start playing the recorded audio is a loop
  //if the appPhase equals to 3 then when pressed, the app will stop looping the
  //audio, and reset the appPhase value to 1
  void LoopFunction() {
    if (appPhase[loopSelector - 1] == 1) {
      CurrentTimer().start();
      startRecord();
      setState(() {
        isRecording = true;
        appPhase[loopSelector - 1] ++;
      });
    } else if (appPhase[loopSelector - 1] == 2)  {
      CurrentTimer().stop();
      stopRecord();
      stopwatchDuration[loopSelector - 1] = CurrentTimer().elapsedMilliseconds;
      continuePlaying[loopSelector - 1] = true;
      play(continuePlaying[loopSelector - 1]);
      setState(() {
        isRecording = false;
        appPhase[loopSelector - 1] ++;
      });
    } else if (appPhase[loopSelector - 1] == 3) {
      //CurrentTimer().reset();
      CurrentPlayer().stop();
      continuePlaying[loopSelector - 1] = false;
      setState(() {
        appPhase[loopSelector - 1] = 2;
      });
    }
  }

  void DeleteLoop() {
    HapticFeedback.vibrate();
    CurrentTimer().reset();
    CurrentPlayer().stop();
    continuePlaying[loopSelector - 1] = false;
    setState(() {
      appPhase[loopSelector - 1] = 1;
    });
}
  void ChangeLoop() {
    if (dropdownValue == temp1) {
      loopSelector = 1;
    } else if (dropdownValue == temp2){
      loopSelector = 2;
    }
  }

  Stopwatch CurrentTimer() {
    if (loopSelector == 1) {
      return timer1;
    } else if (loopSelector == 2) {
      return timer2;
    }
  }

  AudioPlayer CurrentPlayer() {
    if (loopSelector == 1) {
      return audioPlayer1;
    } else if (loopSelector == 2) {
      return audioPlayer2;
    }
  }

  //Probably checks for permissions
  Future<bool> checkPermission() async {
    if (!await Permission.microphone.isGranted) {
      PermissionStatus status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  //Starts the recording function
  void startRecord() async {
    bool hasPermission = await checkPermission();
    if (hasPermission) {
      statusText = "Recording...";
      recordFilePath[loopSelector - 1] = await getFilePath();
      RecordMp3.instance.start(recordFilePath[loopSelector - 1], (type) {
        statusText = "Record error--->$type";
        setState(() {});
      });
    } else {
      statusText = "No microphone permission";
    }
    setState(() {});
  }

  //Pauses the record (stop record =/= pause record) (not currently used)
  void pauseRecord() {
    if (RecordMp3.instance.status == RecordStatus.PAUSE) {
      bool s = RecordMp3.instance.resume();
      if (s) {
        statusText = "Recording...";
        setState(() {});
      }
    } else {
      bool s = RecordMp3.instance.pause();
      if (s) {
        statusText = "Recording pause...";
        setState(() {});
      }
    }
  }

  //stops the recording
  void stopRecord() {
    bool s = RecordMp3.instance.stop();
    if (s) {
      statusText = "Record complete";
      setState(() {});
    }
  }

  //resumes the recording (used generally with pauseRecord i think)
  void resumeRecord() {
    bool s = RecordMp3.instance.resume();
    if (s) {
      statusText = "Recording...";
      setState(() {});
    }
  }

  List<String> recordFilePath = List(4);

  //DoContinuePlaying is a way to check if the looping should continue or not
  //It's called in the function play, and it's "parameter", continuePlaying's
  //value is changed at the LoopFunction
  void DoContinuePlaying1() {
    if (continuePlaying[0]) {
      firstLoopIsDone = true;
      play1(continuePlaying[0]);
    }
  }

  void DoContinuePlaying2() {
    if (continuePlaying[1]) {
      firstLoopIsDone = true;
      play2(continuePlaying[1]);
    }
  }

  void play(bool continueLooping) {
    if (loopSelector == 1) {
      play1(continueLooping);
    } else if (loopSelector == 2) {
      play2(continueLooping);
    }
  }
  //The play function plays audio, and loops it.
  void play1(bool continueLooping) {
    AudioPlayer player = audioPlayer1;
    if (recordFilePath[0] != null && File(recordFilePath[0]).existsSync()) {
      if (continueLooping) {
        player.play(recordFilePath[0], isLocal: true);
        Timer(
          Duration(
            milliseconds: (!firstLoopIsDone? stopwatchDuration[0] - loopDelay : 0 - loopDelay)
          ),
            DoContinuePlaying1
        );
      }
    }
  }

  void play2(bool continueLooping) {
    AudioPlayer player = audioPlayer2;
    if (recordFilePath[1] != null && File(recordFilePath[1]).existsSync()) {
      if (continueLooping) {
        player.play(recordFilePath[1], isLocal: true);
        Timer(
            Duration(
                milliseconds: (!firstLoopIsDone? stopwatchDuration[1] - loopDelay : 0 - loopDelay)
            ),
            DoContinuePlaying2
        );
      }
    }
  }


  //getFilePath creates files paths to store the recorded audio
  Future<String> getFilePath() async {
    Directory storageDirectory = await getApplicationDocumentsDirectory();
    String sdPath = storageDirectory.path + "/record";
    var d = Directory(sdPath);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    return sdPath + "/test_$loopSelector.mp3";
  }
}



