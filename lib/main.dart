import 'package:flutter/material.dart';
import 'package:gsheets/gsheets.dart';
import 'package:tuple/tuple.dart';

const _credentials = r'''
{
}
''';

const _spreadsheetId = '';

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
  int _counter = 0;
  int _ind = 3;
  String _question = "tes";
  String _answer = "ans";

  Future<Tuple2<String, String>> _getQandA() async {
    var ss = await widget.gsheets.spreadsheet(_spreadsheetId);
    var sheet = ss.worksheetByIndex(0);
    var question = await sheet!.values.value(column: 1, row: _ind);
    var answer = await sheet.values.value(column: 2, row: _ind);
    return Future<Tuple2<String, String>>.value(Tuple2<String, String>(question, answer));
  }

  void _incrementCounter() async {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
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
              var widgets = <Widget>[];
              if (snapshot.connectionState != ConnectionState.done) {
                widgets.add(const CircularProgressIndicator());
              } else if (snapshot.hasError) {
                widgets.add(Text(snapshot.error.toString()));
              } else if (snapshot.hasData) {
                widgets.addAll(<Widget>[
                  Text(snapshot.data!.item1, style: Theme.of(context).textTheme.headline4),
                  Text(snapshot.data!.item2, style: Theme.of(context).textTheme.headline4)
                ]);
              } else {
                widgets.add(const Text("データ取得に失敗しました"));
              }
              return Column(mainAxisAlignment: MainAxisAlignment.center, children: widgets);
            }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
