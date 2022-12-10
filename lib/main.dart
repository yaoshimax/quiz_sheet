import 'package:flutter/material.dart';
import 'package:gsheets/gsheets.dart';
import 'package:tuple/tuple.dart';
import 'package:flip_card/flip_card.dart';
import 'package:google_fonts/google_fonts.dart';

const _credentials = r'''
{
}
''';

const _spreadsheetId = '';

// https://github.com/a-marenkov/gsheets/issues/31
const double gsDateBase = 2209161600 / 86400;
const double gsDateFactor = 86400000;

double dateToGsheets(DateTime dateTime, {bool localTime = true}) {
  final offset = dateTime.millisecondsSinceEpoch / gsDateFactor;
  final shift = localTime ? dateTime.timeZoneOffset.inHours / 24 : 0;
  return gsDateBase + offset + shift;
}

DateTime dateFromGsheets(String value, {bool localTime = true}) {
  final date = double.parse(value);
  final millis = (date - gsDateBase) * gsDateFactor;
  return DateTime.fromMillisecondsSinceEpoch(millis.toInt(), isUtc: localTime);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final gsheets = GSheets(_credentials);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.sawarabiGothicTextTheme(Theme.of(context).textTheme),
      ),
      home: MyHomePage(title: 'QuizSheet', gsheets: gsheets),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title, required this.gsheets}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final GSheets gsheets;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final durations = <Duration>[
    const Duration(hours: 1),
    const Duration(hours: 3),
    const Duration(hours: 10),
    const Duration(days: 1),
    const Duration(days: 3),
    const Duration(days: 10),
    const Duration(days: 30),
    const Duration(days: 90),
    const Duration(days: 180),
    const Duration(days: 365),
  ];

  int _ind = -1;
  bool _ok = false;

  Future<Tuple2<String, String>> _getQandA() async {
    if (_ind != -1) {
      if (_ok) {
        var ss = await widget.gsheets.spreadsheet(_spreadsheetId);
        var sheet = ss.worksheetByIndex(0);
        var correctCell = await sheet!.cells.cell(column: 3, row: _ind + 2);

        var targetCell = await sheet.cells.cell(column: 4, row: _ind + 2);
        var thresholdCell = await sheet.cells.cell(column: 5, row: _ind + 2);
        var i = 0;
        if (thresholdCell.value.isNotEmpty && targetCell.value.isNotEmpty) {
          var before = dateFromGsheets(targetCell.value);
          var after = dateFromGsheets(thresholdCell.value);
          var dur = after.difference(before);
          for (i = 0; i < durations.length; i++) {
            if (dur * 1.1 <= durations[i]) {
              break;
            }
          }
        }
        var now = DateTime.now();
        var next = now.add(durations[i]);
        await correctCell.post(now);
        await targetCell.post(now);
        await thresholdCell.post(next);
      } else {
        var ss = await widget.gsheets.spreadsheet(_spreadsheetId);
        var sheet = ss.worksheetByIndex(0);
        var targetCell = await sheet!.cells.cell(column: 4, row: _ind + 2);
        var thresholdCell = await sheet.cells.cell(column: 5, row: _ind + 2);
        var i = 0;
        if (thresholdCell.value.isNotEmpty && targetCell.value.isNotEmpty) {
          var before = dateFromGsheets(targetCell.value);
          var after = dateFromGsheets(thresholdCell.value);
          var dur = after.difference(before);
          for (i = 0; i < durations.length; i++) {
            if (dur * 0.9 <= durations[i]) {
              break;
            }
          }
        }
        var now = DateTime.now();
        var next = now.add(durations[i]);
        await targetCell.post(now);
        await thresholdCell.post(next);
      }
    }
    var ss = await widget.gsheets.spreadsheet(_spreadsheetId);
    var sheet = ss.worksheetByIndex(0);
    var rows = await sheet!.values.allRows(fromRow: 2);
    var size = rows.length;
    var candidateIndex = <int>[];
    var now = DateTime.now();
    for (int i = 0; i < size; i++) {
      if (i == _ind) continue;
      if (rows[i].length < 5) {
        candidateIndex.add(i);
      } else {
        var currentDate = dateFromGsheets(rows[i][4]);
        if (currentDate.isBefore(now)) {
          candidateIndex.add(i);
        }
      }
    }
    if (candidateIndex.isEmpty) {
      return Future.error("all quiz not detected");
    }
    candidateIndex.shuffle();
    _ind = candidateIndex[0];
    var question = rows[_ind][0];
    var answer = rows[_ind][1];
    return Future<Tuple2<String, String>>.value(Tuple2<String, String>(question, answer));
  }

  void _update(bool ok) {
    setState(() {
      _ok = ok;
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: FutureBuilder(
            future: _getQandA(),
            builder: (BuildContext context, AsyncSnapshot<Tuple2<String, String>> snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Column(mainAxisAlignment: MainAxisAlignment.center, children: const <Widget>[CircularProgressIndicator()]);
              } else if (snapshot.hasError) {
                return Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[Text(snapshot.error.toString())]);
              } else if (snapshot.hasData) {
                return Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                  FlipCard(
                      direction: FlipDirection.HORIZONTAL,
                      front: Container(
                          width: width * 0.8,
                          height: height * 0.8,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white70,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(width: 1),
                          ),
                          child: Text(snapshot.data!.item1, style: Theme.of(context).textTheme.headline5)),
                      back: Container(
                          width: width * 0.8,
                          height: height * 0.8,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white70,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(width: 1),
                          ),
                          child: Text(snapshot.data!.item2, style: Theme.of(context).textTheme.headline5))),
                  const SizedBox(height: 5),
                  Container(
                    alignment: Alignment.bottomRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => _update(true),
                          style: TextButton.styleFrom(primary: Colors.white70, backgroundColor: Colors.blue, fixedSize: Size(width * 0.2, 50)),
                          child: const Text("覚えてる"),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () => _update(false),
                          style: TextButton.styleFrom(primary: Colors.white70, backgroundColor: Colors.blue, fixedSize: Size(width * 0.2, 50)),
                          child: const Text("忘れた"),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                ]);
              } else {
                return Column(mainAxisAlignment: MainAxisAlignment.center, children: const <Widget>[Text("データ取得に失敗しました")]);
              }
            }),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
