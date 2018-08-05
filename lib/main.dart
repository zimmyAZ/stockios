import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(new stockios());

class stockios extends StatelessWidget {

  @override

  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Stockio',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Stockio'),
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
  bool _dataloaded = false;
  String new_ticker;
  double new_buy;
  List<String>ticker = ['TSLA', 'AAPL', 'MSFT', 'NVDA'];
  List<String>buying = ['100.12', '250.76', '25.67', '150.00'];
  List<double>current = [103.00, 260.13, 34.34, 151.45];

  List<double>change_dollar = [];
  List<double>change_percent = [];

  double total_buying = 0.0;
  double total_dollar = 0.0;
  double total_percent = 0.0;

  List<DataRow> rows_total = [];
  List<DataRow> rows = [];

  final List<DataColumn> cols = [
    new DataColumn(
      label: const Text('Ticker'),
    ),
    new DataColumn(
      label: const Text('Current'),
    ),
    new DataColumn(
      label: const Text('Dollar'),
    ),
  ];

  final List<DataColumn> cols_total = [
    new DataColumn(
      label: const Text('Total Dollar'),
    ),
    new DataColumn(
      label: const Text('Total Percent'),
    ),
  ];

  _getweb(get_ticker) async {
    String temp_price;
    List<double>temp_prices = [];
    print('Getting webdata.');
    print('https://www.nasdaq.com/symbol/$get_ticker');
    var contents = await http.read('https://www.nasdaq.com/symbol/$get_ticker');
    var webdata_list = contents.split('</div>');
    print('Handling web data.');
    print(webdata_list.length);
    for (var i = 0; i < webdata_list.length; i++) {
      if (webdata_list[i].contains('qwidget_lastsale')) {
        var webdata_amount = webdata_list[i].split('>');
        temp_price = webdata_amount[2].replaceAll('\$', '');
        print('$get_ticker : $temp_price');
        print('Adding Ticker.');
        temp_prices.add(double.parse(temp_price));
      }
    }
    setState(() {
      print(temp_prices.toString());
      current = temp_prices;
    });
  }

  _rungetweb() async{
    print(ticker.length);
    for(int i = 0; i < ticker.length; i++) {
      _getweb(ticker[i]);
    }
  }

  _loadSettings() async{
    List<String>temp_tickers = [];
    List<String>temp_buys = [];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs = await SharedPreferences.getInstance();
    if (prefs.getStringList('tickers').contains('Blank')){
      print('Loaded default values.');
      prefs.setStringList('tickers', ['GOOGL', 'AAPL', 'MSFT', 'NVDA']);
      prefs.setStringList('buys', ['100.12', '250.76', '25.67', '150.00']);
    }
    temp_tickers = prefs.getStringList('tickers');
    temp_buys = prefs.getStringList('buys');
    setState(() {
      print('Loading variables.');
      ticker = temp_tickers;
      print(ticker);
      buying = temp_buys;
      print(buying);
    });
  }

  _saveSettings(String newticker, String newbuy) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      ticker.add(newticker);
      buying.add(newbuy);
      _getweb(newticker);
      text_colors.add(Colors.green);
    });
    prefs.setStringList('tickers', ticker);
    prefs.setStringList('buys', buying);
  }

  _gettotaldata() async {
    double temp_total_buying = 0.0;
    double temp_total_percent = 0.0;
    double temp_total_dollar = 0.0;
    print(buying.length);
    for(var i = 0; i < buying.length; i++){
      print(buying[i]);
      temp_total_buying += double.parse(buying[i]);
      temp_total_dollar += current[i];
      print(temp_total_buying);
      double dollar = current[i] - double.parse(buying[i]);
      double percent = ((current[i] - double.parse(buying[i]))/double.parse(buying[i]))*100;
      temp_total_percent = ((temp_total_dollar - temp_total_buying)/temp_total_buying)*100;
      setState((){
        change_dollar.add(dollar);
        change_percent.add(percent);
      });
    }
    setState((){
      print('Setting total.');
      print(temp_total_buying);
      print(temp_total_percent);
      print(temp_total_dollar);
      total_buying = temp_total_buying;
      total_percent = temp_total_percent;
      total_dollar = temp_total_dollar;
    });
  }

  _gettabledata() async {
    List<DataRow> temp_rows = [];
    List<DataRow> temp_rows_total = [];

    for (var i = 0; i < current.length; i++) {
      temp_rows.add(new DataRow(
          cells: [
            new DataCell(new Text(ticker[i])),
            new DataCell(new Text(current[i].toStringAsFixed(2),
                style: new TextStyle(color: text_colors[i]))),
            new DataCell(new Text(change_dollar[i].toStringAsFixed(2),
                style: new TextStyle(color: text_colors[i]))),
            //            new DataCell(new Text(change_percent[i].toStringAsFixed(2)))
          ]
      ));
    }
    temp_rows_total.add(new DataRow(
        cells: [
          new DataCell(new Text(total_dollar.toStringAsFixed(2))),
          new DataCell(new Text(total_percent.toStringAsFixed(2))),
          //            new DataCell(new Text(change_percent[i].toStringAsFixed(2)))
        ]
    ));
    setState((){
      rows = temp_rows;
      rows_total = temp_rows_total;
    });
  }

  final List<Color> text_colors = [Colors.green, Colors.red, Colors.red, Colors.green];

  @override
  void initState() {
    print('_loadSettings');
    _loadSettings();
    print('_rungetweb');
    _rungetweb();
    print('_loadtotaldata');
    _gettotaldata();
    print('_loadtabledata');
    _gettabledata();
  }

  @override
  Widget build(BuildContext context) {

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
                  onChanged: (String text) {
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
                      _saveSettings(new_ticker, new_buy.toString());
                    });
                    print('Resetting new ticker data.');
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
