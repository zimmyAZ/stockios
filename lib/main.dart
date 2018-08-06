import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

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
  List<String>ticker = [];
  List<String>webtickers = [];
  List<String>buying = [];
  List<double>current = [];
  List compact = [];
  List temp_compact = [];
  List<Color> text_colors = [];

  List<double>temp_prices = [];

  List<double>change_dollar = [];
  List<double>change_percent = [];

  double total_buying = 0.0;
  double total_dollar = 0.0;
  double total_percent = 0.0;
  double total_change_dollar = 0.0;

  List<DataRow> rows_total = [];
  List<DataRow> rows = [];

  bool _loadstate = false;
  bool _webstate = false;
  bool _singlestate = false;

  final List<DataColumn> cols = [
    new DataColumn(
      label: const Text('Ticker'),
    ),
    new DataColumn(
      label: const Text('Current'),
    ),
    new DataColumn(
      label: const Text('Gain / Loss'),
    ),
  ];

  final List<DataColumn> cols_total = [
    new DataColumn(
      label: const Text('Total'),
    ),
    new DataColumn(
      label: const Text('Change %'),
    ),
    new DataColumn(
      label: const Text('Change'),
    ),
  ];

  Future _getweb(get_ticker) async {
    String temp_price;
    var contents = await http.read('https://www.nasdaq.com/symbol/$get_ticker');
    var webdata_list = contents.split('</div>');;
    try {
      for (var i = 0; i < webdata_list.length; i++) {
        if (webdata_list[i].contains('qwidget_lastsale')) {
          var webdata_amount = webdata_list[i].split('>');
          print('$get_ticker');
          temp_price = webdata_amount[2].replaceAll('\$', '');
          temp_prices.add(double.parse(temp_price));
          temp_compact.add([get_ticker, double.parse(temp_price)]);
          print(temp_compact);
        }
      }
    }
    catch(e){
      print(e);
      print('Issues with $get_ticker');
    }
    setState(() {
      print('Compact : ${temp_compact.toString()}');
      compact = temp_compact;
      _singlestate = true;
    });
  }

  Future _rungetweb() async{
    int counter = 0;
    List<double> temp_current = [];
    for(int i = 0; i < webtickers.length; i++) {
      await _getweb(webtickers[i]);
      counter ++;
    }
    for(int j = 0; j < ticker.length; j++){
      for(int a = 0; a < compact.length; a++){
        if(compact[a].contains(ticker[j])){
          var line = compact[a];
          print('Getting price ${line[1]}');
          temp_current.add(line[1]);
        }
      }
    }
    if(counter == webtickers.length){
      setState(() {
        current = temp_current;
        _webstate = true;
      });
    }
  }

  Future _loadSettings() async{
    List<String>temp_tickers = [];
    List<String>temp_buys = [];
    List<String>temp_web = [];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs = await SharedPreferences.getInstance();
    temp_tickers = prefs.getStringList('tickers');
    temp_buys = prefs.getStringList('buys');
    print(temp_tickers.length);
    print('Starting Compact');
    for(int i = 0; i < temp_tickers.length; i++){
      if(temp_web.isEmpty){
        print('Empty');
        temp_web.add(temp_tickers[i]);
      }
      else{
        for(int j = 0; j < temp_web.length; j++){
          if(temp_web.contains(temp_tickers[i])){
            print('Dupe');
          }
          else{
            print('Add ${temp_tickers[i]}');
            temp_web.add(temp_tickers[i]);
          }
        }
      }
    }
    print(temp_web.length);
    setState(() {
      print('Loading variables.');
      ticker = temp_tickers;
      buying = temp_buys;
      webtickers = temp_web;
      _loadstate = true;
    });
  }

  _saveSettings(String newticker, String newbuy) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      ticker.add(newticker);
      buying.add(newbuy);
      });
    await _getweb(newticker);
    while(true) {
      if (_singlestate == true) {
        break;
      }
    }
    print(text_colors.length);
    await _getcolordata();
    print(text_colors.length);
    await _gettotaldata();
    await _gettabledata();

    setState(() {
      _singlestate = false;
    });
    prefs.setStringList('tickers', ticker);
    prefs.setStringList('buys', buying);
  }

  _setSettings() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('tickers', ['AAPL', 'MSFT', 'MSFT']);
    prefs.setStringList('buys', ['100', '150', '20']);
  }

  Future _gettotaldata() async {
    double temp_total_buying = 0.0;
    double temp_total_percent = 0.0;
    double temp_total_dollar = 0.0;
    for(var i = 0; i < buying.length; i++){
      temp_total_buying += double.parse(buying[i]);
      temp_total_dollar += current[i];
      double dollar = current[i] - double.parse(buying[i]);
      double percent = ((current[i] - double.parse(buying[i]))/double.parse(buying[i]))*100;
      temp_total_percent = ((temp_total_dollar - temp_total_buying)/temp_total_buying)*100;
      setState((){
        change_dollar.add(dollar);
        change_percent.add(percent);
      });
    }
    for(int i = 0; i < change_dollar.length; i++){
    }
    setState((){
      print('Setting total.');
      total_change_dollar = temp_total_dollar - temp_total_buying;
      total_buying = temp_total_buying;
      total_percent = temp_total_percent;
      total_dollar = temp_total_dollar;
    });
  }

  Future _gettabledata() async {
    List<DataRow> temp_rows = [];
    List<DataRow> temp_rows_total = [];

    for (var i = 0; i < ticker.length; i++) {
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
          new DataCell(new Text(total_change_dollar.toStringAsFixed(2))),
          //            new DataCell(new Text(change_percent[i].toStringAsFixed(2)))
        ]
    ));
    setState((){
      rows = temp_rows;
      rows_total = temp_rows_total;
    });
  }

  Future _getcolordata() async {
    Color temp_color;
    List<Color> temp_colors = [];
    for(int i = 0; i < buying.length; i++){
      if(double.parse(buying[i]) > current[i]){
        temp_color = Colors.red;
        temp_colors.add(temp_color);
      }
      if(double.parse(buying[i]) <= current[i]){
        temp_color = Colors.green;
        temp_colors.add(temp_color);
      }
    }
    setState((){
      text_colors = temp_colors;
    });
  }

  _load() async {
    await _loadSettings();
    while(true){
      if (_loadstate == true){
        break;
      }
    }
    await _rungetweb();
    while(true){
      if (_webstate == true){
        break;
      }
    }
    await _getcolordata();
    await _gettotaldata();
    await _gettabledata();
    setState(() {
      _loadstate = false;
      _webstate = false;
    });
  }

  _refresh() async {
    print(ticker.length);
    await _loadSettings();
    while(true){
      if (_loadstate == true){
        break;
      }
    }
    print(ticker.length);
    await _rungetweb();
    while(true){
      if (_webstate == true){
        break;
      }
    }
    await _getcolordata();
    await _gettotaldata();
    await _gettabledata();
    setState(() {
      _loadstate = false;
      _webstate = false;
    });
  }

  @override
  void initState() {
//    _setSettings();
    _load();
  }

  @override
  Widget build(BuildContext context) {

    final main_card = Card(
        margin: EdgeInsets.all(4.0),
        child: new Material(
          child: new DataTable(columns: cols, rows: rows),
          color: Colors.white70
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
      actions: <Widget>[
        new IconButton(icon: new Icon(Icons.refresh), onPressed: _refresh)
      ],
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
                    _saveSettings(new_ticker, new_buy.toString());
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

//I need to add a function that specifies the colors to be used for run table data.
//Might need to find a new URL for getting stock data
//Create method for cleaning up memory cause i think its getting really full towards the end
//Add delete option
//Show more data like Purchase data / Place of purchase
//Add some charts, everyone loves charts
//Add to App Store 
