import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/sudoku_localizations.dart';
import 'package:logger/logger.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sudoku/constant.dart';
import 'package:sudoku/effect/sound_effect.dart';
import 'package:sudoku/page/sudoku_pause_cover.dart';
import 'package:sudoku/state/sudoku_state.dart';
import 'package:sudoku/util/localization_util.dart';
import 'package:sudoku_dart/sudoku_dart.dart';
import 'package:url_launcher/url_launcher_string.dart';

final Logger log = Logger();

final ButtonStyle flatButtonStyle = TextButton.styleFrom(
  foregroundColor: Colors.black54,
  shadowColor: Colors.green,
  minimumSize: Size(88, 36),
  padding: EdgeInsets.symmetric(horizontal: 16.0),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(3.0)),
  ),
);

final ButtonStyle primaryFlatButtonStyle = TextButton.styleFrom(
  foregroundColor: Colors.white,
  backgroundColor: Colors.lightBlue,
  shadowColor: Colors.green,
  minimumSize: Size(88, 36),
  padding: EdgeInsets.symmetric(horizontal: 16.0),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(3.0)),
  ),
);

const Image ideaPng = Image(
  image: AssetImage("assets/image/idea.png"),
  width: 25,
  height: 25,
);
const Image lifePng = Image(
  image: AssetImage("assets/image/heart.png"),
  width: 25,
  height: 25,
);

class SudokuGamePage extends StatefulWidget {
  SudokuGamePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _SudokuGamePageState createState() => _SudokuGamePageState();
}

class _SudokuGamePageState extends State<SudokuGamePage>
    with WidgetsBindingObserver {
  int _chooseSudokuBox = 0;
  bool _markOpen = false;
  bool _manualPause = false;

  SudokuState get _state => ScopedModel.of<SudokuState>(context);

  _aboutDialogAction(BuildContext context) {
    Widget appIcon = GestureDetector(
        child: Image(
            image: AssetImage("assets/image/sudoku_logo.png"),
            width: 45,
            height: 45),
        onDoubleTap: () {
          WidgetBuilder columnWidget = (BuildContext context) {
            return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image(image: AssetImage("assets/image/sudoku_logo.png")),
                  CupertinoButton(
                    child: Text("Sudoku"),
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  )
                ]);
          };
          showDialog(context: context, builder: columnWidget);
        });
    return showAboutDialog(
        applicationIcon: appIcon,
        context: context,
        children: <Widget>[
          GestureDetector(
            child: Text(
              "MADE BY:",
              style: TextStyle(color: Colors.green),
            ),
            onTap: () async {
              if (await canLaunchUrlString(Constant.githubRepository1)) {
                if (Platform.isAndroid) {
                  await launchUrlString(Constant.githubRepository1,
                      mode: LaunchMode.platformDefault);
                } else {
                  await launchUrlString(Constant.githubRepository1,
                      mode: LaunchMode.externalApplication);
                }
              } else {
                log.e("cant open it: ${Constant.githubRepository1}");
              }
            },
          ),
          Container(
              margin: EdgeInsets.fromLTRB(0, 10, 0, 5),
              padding: EdgeInsets.all(0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Flutter Sudoku", style: TextStyle(fontSize: 12)),
                    Text(Constant.githubRepository2,
                        style: TextStyle(fontSize: 12))
                  ]))
        ]);
  }

  bool _isOnlyReadGrid(int index) => (_state.sudoku?.puzzle[index] ?? 0) != -1;

  void _gameStackCount() {
    if (_state.isComplete) {
      _pauseTimer();
      _state.updateStatus(SudokuGameStatus.success);
      return _gameOver();
    }
  }

  void _gameOver() async {
    bool isWinner = _state.status == SudokuGameStatus.success;
    String title, conclusion;
    Function playSoundEffect;

    final String elapsedTimeText =
        AppLocalizations.of(context)!.elapsedTimeText;
    final String winnerConclusionText =
        AppLocalizations.of(context)!.winnerConclusionText;
    final String failureConclusionText =
        AppLocalizations.of(context)!.failureConclusionText;
    final String levelLabel =
        LocalizationUtils.localizationLevelName(context, _state.level!);

    if (isWinner) {
      title = "Well Done!";
      conclusion = winnerConclusionText.replaceFirst("%level%", levelLabel);
      playSoundEffect = SoundEffect.solveVictory;
    } else {
      title = "Failure";
      conclusion = failureConclusionText.replaceFirst("%level%", levelLabel);
      playSoundEffect = SoundEffect.gameOver;
    }

    // шоуны виджет хуудас дээр тоглоом руу чиглүүлэх
    PageRouteBuilder gameOverPageRouteBuilder = PageRouteBuilder(
        opaque: false,
        pageBuilder: (BuildContext context, animation, _) {
          // дууны эффект: ялалт эсвэл бүтэлгүйтэл
          playSoundEffect();
          // шоу виджет дээр тоглоом
          Widget gameOverWidget = Scaffold(
              backgroundColor: Colors.white.withOpacity(0.85),
              body: Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                          flex: 1,
                          child: Align(
                              alignment: Alignment.center,
                              child: Text(title,
                                  style: TextStyle(
                                      color: isWinner
                                          ? Colors.black
                                          : Colors.redAccent,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold)))),
                      Expanded(
                          flex: 2,
                          child: Column(children: [
                            Container(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  25.0, 0.0, 25.0, 0.0),
                              child: Text(conclusion,
                                  style: TextStyle(fontSize: 16, height: 1.5)),
                            ),
                            Container(
                                margin: EdgeInsets.fromLTRB(0, 15, 0, 10),
                                child: Text(
                                    "$elapsedTimeText : ${_state.timer}'s",
                                    style: TextStyle(color: Colors.green))),
                            Container(
                                padding: EdgeInsets.all(10),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Offstage(
                                          offstage: _state.status ==
                                              SudokuGameStatus.success,
                                          child: IconButton(
                                              icon: Icon(Icons.tv),
                                              onPressed: null)),
                                      IconButton(
                                          icon: Icon(Icons.thumb_up),
                                          onPressed: null),
                                      IconButton(
                                          icon: Icon(Icons.exit_to_app),
                                          onPressed: () {
                                            Navigator.pop(context, "exit");
                                          })
                                    ]))
                          ]))
                    ],
                  )));

          return ScaleTransition(
              scale: Tween(begin: 3.0, end: 1.0).animate(animation),
              child: gameOverWidget);
        });
    String signal = await Navigator.of(context).push(gameOverPageRouteBuilder);
    switch (signal) {
      case "ad":
        // @TODO нэмэлт амьдралын логик кодчилол өгдөг
        // Зар сурталчилгааны видео үзэх / энэ програмын талаар сэтгэгдэл бичих гэх мэт хэрэглэгчдэд нэмэлт амьдрал өгөх ямар нэг зүйл хийж чадах уу?
        break;
      case "exit":
      default:
        Navigator.pop(context);
        break;
    }
  }

  // fill zone [ 1 - 9 ]
  Widget _fillZone(BuildContext context) {
    List<Widget> fillTools = List.generate(9, (index) {
      int num = index + 1;
      bool hasNumStock = _state.hasNumStock(num);
      var fillOnPressed;
      if (!hasNumStock) {
        fillOnPressed = null;
      } else {
        fillOnPressed = () async {
          log.d("input : $num");
          if (_isOnlyReadGrid(_chooseSudokuBox)) {
            return;
          }
          if (_state.status != SudokuGameStatus.gaming) {
            return;
          }
          if (_markOpen) {
            log.d("fill in notes");
            _state.switchMark(_chooseSudokuBox, num);
          } else {
            _state.switchRecord(_chooseSudokuBox, num);
            if (_state.record[_chooseSudokuBox] != -1 &&
                _state.sudoku!.solution[_chooseSudokuBox] != num) {
              _state.lifeLoss();
              if (_state.life <= 0) {
                return _gameOver();
              }

              String wrongInputAlertText =
                  AppLocalizations.of(context)!.wrongInputAlertText;
              wrongInputAlertText = wrongInputAlertText.replaceFirst(
                  "%attempts%", "${_state.life}");
              String gotItText = AppLocalizations.of(context)!.gotItText;

              showCupertinoDialog(
                  context: context,
                  builder: (context) {
                    // дуу чимээний алдаа
                    SoundEffect.stuffError();
                    return CupertinoAlertDialog(
                      title: Text("Oopsie..."),
                      content: Text(wrongInputAlertText),
                      actions: [
                        CupertinoDialogAction(
                          child: Text(gotItText),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        )
                      ],
                    );
                  });

              return;
            }
            _gameStackCount();
          }
        };
      }

      Color recordFontColor = hasNumStock ? Colors.black : Colors.white;
      Color recordBgColor = hasNumStock ? Colors.black12 : Colors.white24;

      Color markFontColor = hasNumStock ? Colors.white : Colors.white;
      Color markBgColor = hasNumStock ? Colors.black : Colors.white24;

      return Expanded(
          flex: 1,
          child: Container(
              margin: EdgeInsets.all(2),
              decoration: BoxDecoration(border: BorderDirectional()),
              child: CupertinoButton(
                  color: _markOpen ? markBgColor : recordBgColor,
                  padding: EdgeInsets.all(1),
                  child: Text('${index + 1}',
                      style: TextStyle(
                          color: _markOpen ? markFontColor : recordFontColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  onPressed: fillOnPressed)));
    });

    fillTools.add(Expanded(
        flex: 1,
        child: Container(
            child: CupertinoButton(
                padding: EdgeInsets.all(8),
                child: Image(
                    image: AssetImage("assets/image/icon_eraser.png"),
                    width: 40,
                    height: 40),
                onPressed: () {
                  log.d("""
                  when ${_chooseSudokuBox + 1} is not a puzzle , then clean the choose \n
                  clear ${_chooseSudokuBox + 1} selection , if it is not a fixed value
                  """);
                  if (_isOnlyReadGrid(_chooseSudokuBox)) {
                    // зөвхөн унших зүйл, алгасах - зөвхөн унших сүлжээ
                    return;
                  }
                  if (_state.status != SudokuGameStatus.gaming) {
                    // тоглохгүй, алгасах - тоглоом явагдаж байх үед биш
                    return;
                  }
                  _state.cleanMark(_chooseSudokuBox);
                  _state.cleanRecord(_chooseSudokuBox);
                }))));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
              height: 40,
              width: MediaQuery.of(context).size.width,
              child: Row(children: fillTools))),
    );
  }

  Widget _toolZone(BuildContext context) {
    // түр зогсоох товчлуур товших функц
    var pauseOnPressed = () {
      if (_state.status != SudokuGameStatus.gaming) {
        return;
      }

      // Гарын авлагын түр зогсолтыг тэмдэглэ
      setState(() {
        _manualPause = true;
      });

      _pause();
      Navigator.push(
          context,
          PageRouteBuilder(
              opaque: false,
              pageBuilder: (BuildContext context, _, __) {
                return SudokuPauseCoverPage();
              })).then((_) {
        _gaming();

        // Гараар түр зогсоохыг буцаах
        setState(() {
          _manualPause = false;
        });
      });
    };

    // зөвлөмж товч товших функц
    var tipsOnPressed;
    if (_state.hint > 0) {
      tipsOnPressed = () {
        // дараагийн үүрэнд хариулах зөвлөмжүүд
        log.d("top tips button");
        int hint = _state.hint;
        if (hint <= 0) {
          return;
        }
        List<int> puzzle = _state.sudoku!.puzzle;
        List<int> solution = _state.sudoku!.solution;
        List<int> record = _state.record;
        // санамсаргүй цэгийн зөвлөмжүүд
        int randomBeginPoint = new Random().nextInt(puzzle.length);
        for (int i = 0; i < puzzle.length; i++) {
          int index = (i + randomBeginPoint) % puzzle.length;
          if (puzzle[index] == -1 && record[index] == -1) {
            SoundEffect.answerTips();
            _state.setRecord(index, solution[index]);
            _state.hintLoss();
            _chooseSudokuBox = index;
            _gameStackCount();
            return;
          }
        }
      };
    }

    // тэмдэг товчлуурын функц
    var markOnPressed = () {
      log.d("enable mark function");
      setState(() {
        _markOpen = !_markOpen;
      });
    };
    // i18n текстийн эхлэлийг тодорхойлно
    var exitGameText = AppLocalizations.of(context)!.exitGameText;
    var cancelText = AppLocalizations.of(context)!.cancelText;
    var pauseText = AppLocalizations.of(context)!.pauseText;
    var tipsText = AppLocalizations.of(context)!.tipsText;
    var enableMarkText = AppLocalizations.of(context)!.enableMarkText;
    var closeMarkText = AppLocalizations.of(context)!.closeMarkText;
    var exitGameContentText = AppLocalizations.of(context)!.exitGameContentText;
    // i18n текстийн төгсгөлийг тодорхойлно
    var exitGameOnPressed = () async {
      await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
                title: Text(exitGameText,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                content: Text(exitGameContentText),
                actions: [
                  TextButton(
                    child: Text(exitGameText),
                    style: flatButtonStyle,
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                  ),
                  TextButton(
                    child: Text(cancelText),
                    style: primaryFlatButtonStyle,
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  ),
                ]);
          }).then((val) {
        bool confirm = val;
        if (confirm == true) {
          // тоглоомоос гарах
          ScopedModel.of<SudokuState>(context).initialize();
          Navigator.pop(context);
        }
      });
    };
    return Container(
        decoration: BoxDecoration(color: Colors.green[100]),
        height: 192.3,
        padding: EdgeInsets.all(5),
        child: Row(children: <Widget>[
          // тоглоомыг түр зогсоох
          Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: CupertinoButton(
                      padding: EdgeInsets.all(5),
                      onPressed: pauseOnPressed,
                      child: Text(pauseText, style: TextStyle(fontSize: 20))))),
          // tips
          Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.center,
                  child: CupertinoButton(
                      padding: EdgeInsets.all(5),
                      onPressed: tipsOnPressed,
                      child: Text(tipsText, style: TextStyle(fontSize: 20))))),
          // mark
          Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.center,
                  child: CupertinoButton(
                      padding: EdgeInsets.all(5),
                      onPressed: markOnPressed,
                      child: Text(
                          "${_markOpen ? closeMarkText : enableMarkText}",
                          style: TextStyle(fontSize: 20))))),

          Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.centerRight,
                  child: CupertinoButton(
                      padding: EdgeInsets.all(5),
                      onPressed: exitGameOnPressed,
                      child:
                          Text(exitGameText, style: TextStyle(fontSize: 20)))))
        ]));
  }

  Widget _willPopWidget(
      BuildContext context, Widget child, WillPopCallback onWillPop) {
    return new WillPopScope(child: child, onWillPop: onWillPop);
  }

  Color _gridInWellBgColor(int index) {
    Color gridWellBackgroundColor;
    // same zones
    List<int> zoneIndexes =
        Matrix.getZoneIndexes(zone: Matrix.getZone(index: index));
    // same rows
    List<int> rowIndexes = Matrix.getRowIndexes(Matrix.getRow(index));
    // same columns
    List<int> colIndexes = Matrix.getColIndexes(Matrix.getCol(index));

    Set indexSet = Set();
    indexSet.addAll(zoneIndexes);
    indexSet.addAll(rowIndexes);
    indexSet.addAll(colIndexes);

    if (index == _chooseSudokuBox) {
      gridWellBackgroundColor = Color.fromARGB(255, 0x70, 0xF3, 0xFF);
    } else if (indexSet.contains(_chooseSudokuBox)) {
      gridWellBackgroundColor = Color.fromARGB(255, 0x44, 0xCE, 0xF6);
    } else {
      if (Matrix.getZone(index: index).isOdd) {
        gridWellBackgroundColor = Colors.white;
      } else {
        gridWellBackgroundColor = Color.fromARGB(255, 0xCC, 0xCC, 0xCC);
      }
    }
    return gridWellBackgroundColor;
  }

  Widget _gridInWellWidget(
      BuildContext context, int index, int num, GestureTapCallback onTap) {
    Sudoku sudoku = _state.sudoku!;
    List<int> puzzle = sudoku.puzzle;
    List<int> solution = sudoku.solution;
    List<int> record = _state.record;
    bool readOnly = true;
    bool isWrong = false;
    int num = puzzle[index];
    if (puzzle[index] == -1) {
      num = record[index];
      readOnly = false;

      if (record[index] != -1 && record[index] != solution[index]) {
        isWrong = true;
      }
    }
    return InkWell(
        highlightColor: Colors.green,
        customBorder: Border.all(color: Colors.green),
        child: Center(
          child: Container(
            alignment: Alignment.center,
            margin: EdgeInsets.all(1),
            decoration: BoxDecoration(
                color: _gridInWellBgColor(index),
                border: Border.all(color: Colors.black12)),
            child: Text(
              '${num == -1 ? '' : num}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 25,
                  fontWeight: readOnly ? FontWeight.w800 : FontWeight.normal,
                  color: readOnly
                      ? Colors.blueGrey
                      : (isWrong
                          ? Colors.red
                          : Color.fromARGB(255, 0x3B, 0x2E, 0x7E))),
            ),
          ),
        ),
        onTap: onTap);
  }

  Widget _markGridWidget(
      BuildContext context, int index, GestureTapCallback onTap) {
    Widget markGrid = InkWell(
        highlightColor: Colors.green,
        customBorder: Border.all(color: Colors.blue),
        onTap: onTap,
        child: Container(
            alignment: Alignment.center,
            margin: EdgeInsets.all(1),
            decoration: BoxDecoration(
                color: _gridInWellBgColor(index),
                border: Border.all(color: Colors.black12)),
            child: GridView.builder(
                padding: EdgeInsets.zero,
                physics: NeverScrollableScrollPhysics(),
                itemCount: 9,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3),
                itemBuilder: (BuildContext context, int _index) {
                  String markNum =
                      '${_state.mark[index][_index + 1] ? _index + 1 : ""}';
                  return Text(markNum,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _chooseSudokuBox == index
                              ? Colors.white
                              : Color.fromARGB(255, 0x16, 0x69, 0xA9),
                          fontSize: 12));
                })));

    return markGrid;
  }

  _wellOnTapBuilder(index) {
    // log.d("_wellOnTapBuilder build $index ...");
    return () {
      setState(() {
        _chooseSudokuBox = index;
      });
      if (_state.sudoku!.puzzle[index] != -1) {
        return;
      }
      log.d('choose position : $index');
    };
  }

  Widget _bodyWidget(BuildContext context) {
    if (_state.sudoku == null) {
      return Container(
          color: Colors.white,
          alignment: Alignment.center,
          child: Center(
              child: Text('Sudoku Exiting...',
                  style: TextStyle(color: Colors.black),
                  textDirection: TextDirection.ltr)));
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          /// life
          Container(
            height: 80,
            padding: EdgeInsets.all(10.0),
//                color: Colors.red,
            child: Row(children: <Widget>[
              Expanded(
                  flex: 1,
                  child: Row(children: <Widget>[
                    lifePng,
                    Text(" x ${_state.life}", style: TextStyle(fontSize: 18))
                  ])),
              // indicator
              Expanded(
                flex: 2,
                child: Container(
                    alignment: AlignmentDirectional.center,
                    child: Text(
                        "${LocalizationUtils.localizationLevelName(context, _state.level!)} - ${_state.timer}")),
              ),
              // tips
              Expanded(
                  flex: 1,
                  child: Container(
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                        ideaPng,
                        Text(" x ${_state.hint}",
                            style: TextStyle(fontSize: 18))
                      ])))
            ]),
          ),

          GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: 81,
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 9),
              itemBuilder: ((BuildContext context, int index) {
                int num = -1;
                if (_state.sudoku?.puzzle.length == 81) {
                  num = _state.sudoku!.puzzle[index];
                }

                bool isUserMark = _state.sudoku!.puzzle[index] == -1 &&
                    _state.mark[index].any((element) => element);

                if (isUserMark) {
                  return _markGridWidget(
                      context, index, _wellOnTapBuilder(index));
                }

                return _gridInWellWidget(
                    context, index, num, _wellOnTapBuilder(index));
              })),

          /// хэрэглэгчийн оруулах бүс
          /// fillZone ашиглан тоогоор дүүргэх нүдийг сонгох эсвэл тэмдэглэл тэмдэглэх
          /// Тоглоомыг түр зогсоох / гарахын тулд toolZone ашиглана уу
          Container(margin: EdgeInsets.fromLTRB(0, 5, 0, 5)),
          _fillZone(context),
          _toolZone(context)
        ],
      ),
    );
  }

  @override
  void deactivate() {
    log.d("on deactivate");
    WidgetsBinding.instance.removeObserver(this);
    super.deactivate();
  }

  @override
  void dispose() {
    log.d("on dispose");
    _pauseTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gaming();
  }

  @override
  void didChangeDependencies() {
    log.d("didChangeDependencies");
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(SudokuGamePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    log.d("on did update widget");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        log.d("is paused app lifecycle state");
        _pause();
        break;
      case AppLifecycleState.resumed:
        log.d("is resumed app lifecycle state");
        if (!_manualPause) {
          _gaming();
        }
        break;
      default:
        break;
    }
  }

  Timer? _timer;

  void _gaming() {
    if (_state.status == SudokuGameStatus.pause) {
      log.d("on _gaming");
      _state.updateStatus(SudokuGameStatus.gaming);
      _state.persistent();
      _beginTimer();
    }
  }

  void _pause() {
    if (_state.status == SudokuGameStatus.gaming) {
      log.d("on _pause");
      _state.updateStatus(SudokuGameStatus.pause);
      _state.persistent();
      _pauseTimer();
    }
  }

  void _beginTimer() {
    log.d("timer begin");
    if (_timer == null) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_state.status == SudokuGameStatus.gaming) {
          _state.tick();
          return;
        }
        timer.cancel();
      });
    }
  }

  void _pauseTimer() {
    if (_timer != null) {
      if (_timer!.isActive) {
        _timer!.cancel();
      }
    }
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    log.d("on build");
    Scaffold scaffold = Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: [
        IconButton(
          icon: Icon(Icons.info_outline),
          onPressed: () {
            return _aboutDialogAction(context);
          },
        )
      ]),
      body: _willPopWidget(
          context,
          ScopedModelDescendant<SudokuState>(
              builder: (context, child, model) => _bodyWidget(context)),
          () async {
        _pause();
        return true;
      }),
    );

    return scaffold;
  }
}
