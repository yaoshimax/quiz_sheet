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
  int _ind = -1;
  Future<Tuple2<String, String>> _getQandA() async {
    var ss = await widget.gsheets.spreadsheet(_spreadsheetId);
    var sheet = ss.worksheetByIndex(0);
    var rows = await sheet!.values.allRows(fromRow: 2);
    var size = rows.length;
    var candidateIndex = <int>[];
    var now = DateTime.now();
    for (int i = 0; i < size; i++) {
      if (i == _ind) continue;
      print(rows[i][3]);
      var currentDate = dateFromGsheets(rows[i][3]);
      if (currentDate.isAfter(now)) {
        candidateIndex.add(i);
      }
    }
    if (candidateIndex.isEmpty) {
      return Future.error("all not detected");
    }
    candidateIndex.shuffle();
    _ind = candidateIndex[0];
    var question = rows[_ind][0];
    var answer = rows[_ind][1];
    return Future<Tuple2<String, String>>.value(Tuple2<String, String>(question, answer));
  }

  void _ok(int ind) async {
    var ss = await widget.gsheets.spreadsheet(_spreadsheetId);
    var sheet = ss.worksheetByIndex(0);
    var targetCell = await sheet!.cells.cell(column: 3, row: ind + 2);
    var now = DateTime.now();
    await targetCell.post(now);
    setState(() {
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
    var _height = MediaQuery.of(context).size.height;
    var _width = MediaQuery.of(context).size.width;
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Column(
            // Column is also a layout widget. It takes a list of children and
            // arranges them vertically. By default, it sizes itself to fit its
            // children horizontally, and tries to be as tall as its parent.
            //
            // Invoke "debug painting" (press "p" in the console, choose the
            // "Toggle Debug Paint" action from the Flutter Inspector in Android
            // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
            // to see the wireframe for each widget.
            //
            // Column has various properties to control how it sizes itself and
            // how it positions its children. Here we use mainAxisAlignment to
            // center the children vertically; the main axis here is the vertical
            // axis because Columns are vertical (the cross axis would be
            // horizontal).
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FutureBuilder(
                  future: _getQandA(),
                  builder: (BuildContext context, AsyncSnapshot<Tuple2<String, String>> snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text(snapshot.error.toString());
                    } else if (snapshot.hasData) {
                      return FlipCard(
                          direction: FlipDirection.HORIZONTAL,
                          front: Container(
                              width: _width * 0.8,
                              height: _height * 0.8,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white70,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(width: 1),
                              ),
                              child: Text(snapshot.data!.item1, style: Theme.of(context).textTheme.headline5)),
                          back: Container(
                              width: _width * 0.8,
                              height: _height * 0.8,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white70,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(width: 1),
                              ),
                              child: Text(snapshot.data!.item2, style: Theme.of(context).textTheme.headline5)));
                    } else {
                      return const Text("データ取得に失敗しました");
                    }
                  }),
            ],
          ),
        ),
        floatingActionButton: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'ng',
              onPressed: () => _ok(_ind),
              tooltip: 'Increment',
              child: const Icon(Icons.done),
            ),
            const SizedBox(width: 10),
            FloatingActionButton(
              heroTag: 'ng',
              onPressed: () => _ok(_ind),
              tooltip: 'Increment',
              child: const Icon(Icons.not_interested_sharp),
            ),
          ],
        )
        // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
