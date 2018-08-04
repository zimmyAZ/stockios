import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(new stockios());

class stockios extends StatelessWidget {

  @override

  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {

  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String new_ticker;
  double new_buy;
  var ticker;
  var buying;
  var current = [150.92, 230.74, 24.50, 151.10];
  var change_dollar = [];
  var change_percent = [];
  double total_buying = 0.0;
  double total_dollar = 0.0;
  double total_percent = 0.0;
  var _tickermemory = [];
  var _buymemory = [];
  SharedPreferences prefs;

  void _loadSettings() async{
//      SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    print(prefs.getStringList('tickers'));
    if (prefs.getStringList('tickers') == null) {
      print('Loaded default values.');
      prefs.setStringList('tickers', ['GOOGL', 'APPL', 'MSFT', 'NVDA']);
      prefs.setStringList('buys', ['100.12', '250.76', '25.67', '150.00']);
    };
    setState(() {
      print('Loading variables.');
      ticker = prefs.getStringList('tickers');
      buying = prefs.getStringList('buys');
    });
  }

  void _saveSettings() {
    prefs.setStringList('tickers', ticker);
    prefs.setStringList('buys', buying);
  }

  final List<Color> text_colors = [Colors.green, Colors.red, Colors.red, Colors.green];

  @override
  Widget build(BuildContext context) {
    _loadSettings();
    void gettotals(){
      total_buying = 0.0;
      total_percent = 0.0;
      total_dollar = 0.0;
      for(var i = 0; i < buying.length; i++){
        total_buying += double.parse(buying[i]);
        total_dollar += current[i];
        print(total_buying);
        double dollar = current[i] - double.parse(buying[i]);
        double percent = ((current[i] - double.parse(buying[i]))/double.parse(buying[i]))*100;
        total_percent = ((total_dollar - total_buying)/total_buying)*100;
        setState((){
          change_dollar.add(dollar);
          change_percent.add(percent);
        });
      }

      setState((){
        print('Setting total.');
        total_buying;
        total_percent;
        total_dollar;
      });
    }
    final cols = [
      new DataColumn(
        label: const Text('Ticker'),
      ),
      new DataColumn(
        label: const Text('Current'),
      ),
      new DataColumn(
        label: const Text('Dollar'),
      ),
//      new DataColumn(
//        label: const Text('Percent'),
//      ),
    ];

    final cols_total = [
      new DataColumn(
        label: const Text('Total Dollar'),
      ),
      new DataColumn(
        label: const Text('Total Percent'),
      ),

//      new DataColumn(
//        label: const Text('Percent'),
//      ),
    ];

    final List<DataRow> rows = [];
    for(var i = 0; i < ticker.length; i++){
      rows.add(new DataRow(
          cells: [
            new DataCell(new Text(ticker[i])),
            new DataCell(new Text(current[i].toStringAsFixed(2), style: new TextStyle(color: text_colors[i]))),
            new DataCell(new Text(change_dollar[i].toStringAsFixed(2), style: new TextStyle(color: text_colors[i]))),
//            new DataCell(new Text(change_percent[i].toStringAsFixed(2)))
          ]
      ));
    }

    final List<DataRow> rows_total = [];
    rows_total.add(new DataRow(
        cells: [
          new DataCell(new Text(total_dollar.toStringAsFixed(2))),
          new DataCell(new Text(total_percent.toStringAsFixed(2))),
//            new DataCell(new Text(change_percent[i].toStringAsFixed(2)))
        ]
    ));

    final main_card = Card(
        margin: EdgeInsets.all(4.0),
        color: Colors.greenAccent,
        child: new Material(
          child: new DataTable(columns: cols, rows: rows),
        )
    );

    final total_card = Card(
        margin: EdgeInsets.all(4.0),
        color: Colors.greenAccent,
        child: new Material(
          child: new DataTable(columns: cols_total, rows: rows_total),
        )
    );

    final appBar = AppBar(
      title: const Text('Stock Monitor'),
      backgroundColor: Colors.blueGrey,
    );

    final body = Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.black45,
          Colors.black45,
        ]),
      ),
      child: ListView(
        scrollDirection: Axis.vertical,
        children: <Widget>[main_card, total_card],
      ),
    );

    gettotals();

    return Scaffold(
      appBar: appBar,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add', // used by assistive technologies
        child: Icon(Icons.add),
        onPressed: () => showDialog(
            context: context,
            child: new AlertDialog(
              title: new Text("Add new ticker"),
              content: new Column(children: <Widget>[
                new TextField(
                  decoration: new InputDecoration(
                      labelText: "Ticker"
                  ),
                  onChanged: (String text) {
                    new_ticker = text;
                  },
                ),
                new TextField(
                  decoration: new InputDecoration(
                      labelText: "Buy Price"
                  ),
                  onChanged: ( text) {
                    new_buy = double.parse(text);
                  },
                ),
              ],),
              actions: <Widget>[
                new FlatButton(
                  child: new Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                new FlatButton(
                  child: new Text("Add"),
                  onPressed: () {
                    setState(() {
                      ticker.add(new_ticker);
                      buying.add(new_buy.toStringAsFixed(2));
                      current.add(200.00);
                      text_colors.add(Colors.green);
                    });
                    gettotals();
                    print('Resetting new ticker data.');
                    new_ticker = '';
                    new_buy = 0.0;
                    _saveSettings();
                    Navigator.pop(context);
                  },
                )
              ],
            )
        ),
      ),
      body: body,
    );

  }
}
