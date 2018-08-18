import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'budgetpage.dart';
import 'recurringpage.dart';

class totals{
  final String _ticker;
  final double _amount;
  final int _quantity;

  totals(this._ticker, this._amount, this._quantity);
}

class StockPage extends StatefulWidget {

  StockPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyStockState createState() => new _MyStockState();
}

class _MyStockState extends State<StockPage> with SingleTickerProviderStateMixin{
  int _currentIndex = 1;

  bool _dataloaded = false;

  TabController tabController;

  List total_invest = [];
  List total_performance = [];

  String new_ticker;
  double new_buy;
  String new_date;
  String new_broker;

  List<String>ticker = ['AAPL', 'MSFT', 'TSLA'];
  List<String>webtickers = [];
  List<String>buying = ['200', '150', '300'];
  List<double>current = [];
  List<String>dates = ['7/7/17', '7/7/17', '7/7/17'];
  List<String>brokers = ['Vanguard', 'Fidelity', 'RobinHood'];

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

  List<totals> perf = [];
  List<totals> invest = [];

  var chartWidget_invest_bar;
  var chartWidget_invest_pie;

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

  Future _getweb(String get_ticker, bool single) async {
    String temp_price;
    var contents = await http.read('https://www.thestreet.com/quote/$get_ticker.html');
    var webdata_list = contents.split('<div');
    try {
      for (var i = 0; i < webdata_list.length; i++) {
        if (webdata_list[i].contains('id="currentPrice" ')) {
          var webdata_amount = webdata_list[i].split('>');
          temp_price = webdata_amount[1].replaceAll(' ', '');
          temp_price = webdata_amount[1].replaceAll('</div', '');
          temp_prices.add(double.parse(temp_price));
          temp_compact.add([get_ticker, double.parse(temp_price)]);
        }
      }
    }
    catch(e){
      print(e);
      print('Issues with $get_ticker');
    }
    setState(() {
      if(single == true){
        setState(() {
          current.add(double.parse(temp_price));
        });
      }
      print('Compact : ${temp_compact.toString()}');
      compact = temp_compact;
      _singlestate = true;
    });
    webdata_list = [];
    temp_price = '';
  }

  Future _rungetweb() async{
    int counter = 0;
    List<double> temp_current = [];
    for(int i = 0; i < webtickers.length; i++) {
      await _getweb(webtickers[i], false);
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
    List<String>temp_dates = [];
    List<String>temp_brokers = [];

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs = await SharedPreferences.getInstance();

    temp_tickers = prefs.getStringList('tickers');
    temp_buys = prefs.getStringList('buys');
    temp_dates = prefs.getStringList('dates');
    temp_brokers = prefs.getStringList('brokers');

    print('Starting Compact');
    for(int i = 0; i < temp_tickers.length; i++){
      if(temp_web.isEmpty){
        print('Empty');
        temp_web.add(temp_tickers[i]);
      }
      else{
        for(int j = 0; j < temp_web.length; j++){
          if(temp_web.contains(temp_tickers[i])){
          }
          else{
            print('Add ${temp_tickers[i]}');
            temp_web.add(temp_tickers[i]);
          }
        }
      }
    }
    setState(() {
      print('Loading variables.');

      ticker = temp_tickers;
      buying = temp_buys;
      dates = temp_dates;
      brokers = temp_brokers;

      webtickers = temp_web;
      _loadstate = true;
    });
    temp_tickers = [];
    temp_buys = [];
    temp_web = [];
    temp_dates = [];
  }

  _saveSettings(String newticker, String newbuy, String newdate, String newbroker) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      ticker.add(newticker);
      buying.add(newbuy);
      dates.add(newdate);
      brokers.add(newbroker);
    });
    await _getweb(newticker, true);
    while(true) {
      if (_singlestate == true) {
        break;
      }
    }
    await _get_color_data();
    await _get_total_data();
    await _get_table_data();

    setState(() {
      _singlestate = false;
    });
    prefs.setStringList('tickers', ticker);
    prefs.setStringList('buys', buying);
    prefs.setStringList('dates', dates);
    prefs.setStringList('brokers', brokers);
  }

  _get_total_performance(){
    print('Getting total performance data.');
    for(int i = 0; i < compact.length; i++){
      var line = compact[i];
      int temp_total_number = 0;
      double temp_total_perform = 0.0;
      for(int j = 0; j < ticker.length; j++){
        if(ticker[j] == line[0]){
          temp_total_number += 1;
          temp_total_perform += change_dollar[j];
        }
      }
      setState((){
        total_performance.add([line[0], temp_total_perform, temp_total_number]);
      });
    }
    print(total_performance.toString());
  }

  _get_total_investment(){
    print('Getting total investment data.');
    for(int i = 0; i < compact.length; i++){
      var line = compact[i];
      int temp_total_number = 0;
      double temp_total_invest = 0.0;
      for(int j = 0; j < ticker.length; j++){
        if(ticker[j] == line[0]){
          temp_total_number += 1;
          temp_total_invest += current[j];
        }
      }
      setState((){
        total_invest.add([line[0], temp_total_invest, temp_total_number]);
      });
    }
    print(total_invest.toString());
  }

  _set_charts(){
    print('Getting chart data.');

    List<totals> temp_perf = [];
    List<totals> temp_invest = [];

    for (var i = 0; i < total_performance.length; i++) {
      var line = total_performance[i];
      temp_perf.add(new totals(line[0], line[1], line[2]));
    }
    for (var j = 0; j < total_invest.length; j++) {
      var line = total_invest[j];
      print(line[0]);
      print(line[1]);
      temp_invest.add(new totals(line[0], line[1], line[2]));
    }
    setState((){
      invest = temp_invest;
      perf = temp_perf;
    });

    var series_invest_bar = [
      new charts.Series(
        id: 'Investment Bar',
        domainFn: (totals clickData, _) => clickData._ticker,
        measureFn: (totals clickData, _) => clickData._amount,
        data: invest,
      ),
    ];

    var series_invest_pie = [
      new charts.Series(
        id: 'Invest Pie',
        domainFn: (totals clickData, _) => clickData._ticker,
        measureFn: (totals clickData, _) => clickData._amount,
        data: invest,
      ),
    ];

    var chart_invest_bar = new charts.BarChart(
      series_invest_bar,
      animate: true,
      defaultRenderer: new charts.BarRendererConfig(
          cornerStrategy: const charts.ConstCornerStrategy(30)),
    );

    var chart_invest_pie = new charts.PieChart(
        series_invest_pie,
        animate: true,
        defaultRenderer: new charts.ArcRendererConfig(
            arcWidth: 60,
            arcRendererDecorators: [new charts.ArcLabelDecorator()])
    );

    setState((){
      print('Created investment bar chart.');
      chartWidget_invest_bar = new Padding(
        padding: new EdgeInsets.all(32.0),
        child: new SizedBox(
          height: 400.0,
          child: chart_invest_bar,
        ),
      );

      print('Created investment pie chart.');
      chartWidget_invest_pie = new Padding(
        padding: new EdgeInsets.all(4.0),
        child: new SizedBox(
          height: 300.0,
          child: chart_invest_pie,
        ),
      );
    });
  }

  _setSettings() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('tickers', ['VXUS', 'VXUS', 'VXUS', 'VXUS', 'VXUS', 'VO', 'VO', 'VO', 'VTI', 'VTI', 'VTI', 'VTI', 'VNQ', 'VNQ', 'VNQ', 'NVDA', 'NVDA', 'AMD']);
    prefs.setStringList('buys', ['54.97', '55.02', '55.58', '55.58', '56.70', '142.96', '153.40', '161.63', '137.04', '137.55', '137.55', '146.91', '80.50', '82.92', '82.92', '241.70', '241.70', '16.36']);
    prefs.setStringList('dates', ['9/12/2017', '10/4/2017', '10/30/2017', '10/30/2017', '5/1/2018', '8/30/2017', '5/1/2018', '7/29/2018', '12/4/2017', '3/5/2018', '3/5/2018', '8/6/2018', '6/25/2018', '7/6/2018', '7/6/2018', '7/3/2018', '7/3/2018', '7/9/2018']);
    prefs.setStringList('brokers', ['Vanguard', 'Vanguard', 'Vanguard', 'Vanguard', 'Vanguard', 'Vanguard', 'Vanguard', 'Vanguard', 'Vanguard', 'Vanguard', 'Vanguard', 'Vanguard', 'Vanguard', 'Vanguard', 'Vanguard', 'RobinHood', 'RobinHood', 'RobinHood']);

  }

  _showdetails(String curticker, String buy, String curcurrent, String date, String broker, int position) {
    showDialog(context: context,
        child: new AlertDialog(
            title: new Center(child: Text("$curticker Details")),
            content: new Container(
                width: 260.0,
                height: 150.0,
                decoration: new BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: const Color(0xFFFFFF),
                  borderRadius: new BorderRadius.all(new Radius.circular(10.0)),
                ),
                child: new Column(children: <Widget>[
                  new Row(children: <Widget>[
                    new Expanded(child: new Text('Ticker :', textAlign: TextAlign.left)),
                    new Expanded(child: new Text('$curticker', textAlign: TextAlign.right))
                  ],
                  ),
                  new Row(children: <Widget>[
                    new Expanded(child: new Text('Buy :', textAlign: TextAlign.start)),
                    new Expanded(child: new Text('\$$buy', textAlign: TextAlign.end))
                  ],
                  ),
                  new Row(children: <Widget>[
                    new Expanded(child: new Text('Current :', textAlign: TextAlign.left)),
                    new Expanded(child: new Text('\$$curcurrent', textAlign: TextAlign.right))
                  ],
                  ),
                  new Row(children: <Widget>[
                    new Expanded(child: new Text('Date :', textAlign: TextAlign.left)),
                    new Expanded(child: new Text('$date', textAlign: TextAlign.right))
                  ],
                  ),
                  new Row(children: <Widget>[
                    new Expanded(child: new Text('Broker :', textAlign: TextAlign.left)),
                    new Expanded(child: new Text('$broker', textAlign: TextAlign.right))
                  ],
                  ),
                  new Row(children: <Widget>[
                    new Expanded(child: new Padding(padding: EdgeInsets.all(5.0), child: new RaisedButton(
                      child: new Text("Delete", textAlign: TextAlign.left),
                      color: Colors.red,
                      onPressed: () {
                        setState((){
                          ticker.removeAt(position);
                          buying.removeAt(position);
                          dates.removeAt(position);
                          current.removeAt(position);
                          brokers.removeAt(position);
                        });
                        _refresh();
                        Navigator.pop(context);
                      },
                    ))),
                    new Expanded(child: new Padding(padding: EdgeInsets.all(5.0), child: new RaisedButton(
                      child: new Text("Close", textAlign: TextAlign.right),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    )))
                  ],
                  ),
                ]
                )
            )
        )
    );
  }

  void onTabTapped(int index) {
    if (index == 0) {
      Navigator.push(context, new MaterialPageRoute(
          builder: (context) => new BudgetPage()));
    }
    if (index == 1) {
      print("nothing");
    }
    if (index == 2) {
      Navigator.push(context, new MaterialPageRoute(
          builder: (context) => new RecurringPage()));
    }
    setState(() {
      _currentIndex = index;
    });
  }

  _bottom_app_bar(){
    final bottom_menu = new BottomNavigationBar(
      onTap: onTabTapped, // new
      currentIndex: _currentIndex, // new
      items: [
        new BottomNavigationBarItem(
          icon: Icon(Icons.credit_card),
          title: Text('Budget'),
        ),
        new BottomNavigationBarItem(
          icon: Icon(Icons.show_chart),
          title: Text('Stocks'),
        ),
        new BottomNavigationBarItem(
          icon: Icon(Icons.refresh),
          title: Text('Recurring'),
        )
      ],
    );
    return bottom_menu;
  }

  _add_button() {
    final add_button = new FloatingActionButton(
      tooltip: 'Add',
      child: Icon(Icons.add),
      onPressed: () => showDialog(
          context: context,
          child: new AlertDialog(
            title: new Center(child: Text("Add new ticker")),
            content: new Container(
                width: 260.0,
                height: 250.0,
                decoration: new BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: const Color(0xFFFFFF),
                  borderRadius: new BorderRadius.all(new Radius.circular(10.0)),
                ),
                child: new Column(children: <Widget>[
                  new Expanded(child: new Padding(padding: EdgeInsets.all(10.0), child: new TextField(
                    decoration: new InputDecoration(
                        border: new OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                            const Radius.circular(10.0),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey[300],
                        labelText: "Ticker"
                    ),
                    onChanged: (String text) {
                      new_ticker = text;
                    },
                  ))),
                  new Expanded(child: new Padding(padding: EdgeInsets.all(10.0), child: new TextField(
                    decoration: new InputDecoration(
                        border: new OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                            const Radius.circular(10.0),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey[300],
                        labelText: "Buy Price"
                    ),
                    onChanged: (String text) {
                      new_buy = double.parse(text);
                    },
                  ))),
                  new Expanded(child: new Padding(padding: EdgeInsets.all(10.0), child: new TextField(
                    decoration: new InputDecoration(
                        border: new OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                            const Radius.circular(10.0),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey[300],
                        labelText: "Buy Date"
                    ),
                    onChanged: (String text) {
                      new_date = text;
                    },
                  ))),
                  new Expanded(child: new Padding(padding: EdgeInsets.all(10.0), child: new TextField(
                    decoration: new InputDecoration(
                        border: new OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                            const Radius.circular(10.0),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey[300],
                        labelText: "Broker"
                    ),
                    onChanged: (String text) {
                      new_broker = text;
                    },
                  ))),
                ])),
            actions: <Widget>[
              new FlatButton(
                child: new Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              new FlatButton(
                child: new Text("Add"),
                onPressed: () {
                  _saveSettings(new_ticker, new_buy.toString(), new_date, new_broker);
                  print('Resetting new ticker data.');
                  Navigator.pop(context);
                },
              )
            ],
          )
      ),
    );
    return add_button;
  }

  Future _get_total_data() async {
    double temp_total_buying = 0.0;
    double temp_total_percent = 0.0;
    double temp_total_dollar = 0.0;

    for(int i = 0; i < buying.length; i++){
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

  Future _get_table_data() async {
    List<DataRow> temp_rows = [];
    List<DataRow> temp_rows_total = [];
    print(ticker.length);
    print(buying.length);
    print(dates.length);
    print(brokers.length);
    for (var i = 0; i < ticker.length; i++) {
      temp_rows.add(new DataRow(
          cells: [
            new DataCell(new Center(child: Text(ticker[i])),
                showEditIcon: false,
                onTap: () {
                  _showdetails(ticker[i], buying[i], current[i].toString(), dates[i], brokers[i], i);
                  print('${ticker[i]}, ${buying[i]}, ${dates[i]}, ${brokers[i]}');
                }
            ),
            new DataCell(new Center(child:Text('\$${current[i].toStringAsFixed(2)}',
                style: new TextStyle(color: text_colors[i],)),),
                showEditIcon: false,
                onTap: () {
                  print(i);
                  _showdetails(ticker[i], buying[i], current[i].toString(), dates[i], brokers[i], i);
                  print('${ticker[i]}, ${buying[i]}, ${dates[i]}, ${brokers[i]}');
                }
            ),
            new DataCell(new Text('\$${change_dollar[i].toStringAsFixed(2)}',
              style: new TextStyle(color: text_colors[i]),),
                showEditIcon: false,
                onTap: () {
                  _showdetails(ticker[i], buying[i], current[i].toString(), dates[i], brokers[i], i);
                  print('${ticker[i]}, ${buying[i]}, ${dates[i]}, ${brokers[i]}');
                }
            )
          ]
      ));
    }
    temp_rows_total.add(new DataRow(
        cells: [
          new DataCell(new Text('\$${total_dollar.toStringAsFixed(2)}')),
          new DataCell(new Text('\$${total_percent.toStringAsFixed(2)}')),
          new DataCell(new Text('\$${total_change_dollar.toStringAsFixed(2)}')),
          //            new DataCell(new Text(change_percent[i].toStringAsFixed(2)))
        ]
    ));
    setState((){
      rows = temp_rows;
      rows_total = temp_rows_total;
    });
  }

  Future _get_color_data() async {
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

  _reset() {
    setState(() {
      print('Resetting all variables.');
      total_invest = [];
      total_performance = [];
      new_ticker = '';
      new_buy = 0.0;
      new_date = '';
      new_broker = '';
      ticker = [];
      webtickers = [];
      buying = [];
      current = [];
      dates = [];
      brokers = [];
      compact = [];
      temp_compact = [];
      text_colors = [];
      temp_prices = [];
      change_dollar = [];
      change_percent = [];
      total_buying = 0.0;
      total_dollar = 0.0;
      total_percent = 0.0;
      total_change_dollar = 0.0;
      rows_total = [];
      rows = [];
      _loadstate = false;
      _webstate = false;
      _singlestate = false;
      perf = [];
      invest = [];
      chartWidget_invest_bar = [];
      chartWidget_invest_pie = [];
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
    await _get_color_data();
    await _get_total_data();
    await _get_table_data();
    _get_total_investment();
    _get_total_performance();
    _set_charts();
    setState(() {
      _loadstate = false;
      _webstate = false;
    });
    print(rows.toString());
  }

  _refresh() async {
    _reset();
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
    await _get_color_data();
    await _get_total_data();
    await _get_table_data();
    _get_total_investment();
    _get_total_performance();
    _set_charts();
    setState(() {
      _loadstate = false;
      _webstate = false;
    });
  }

  @override
  void initState() {
//    _setSettings();
    _load();
    tabController = new TabController(length: 3,vsync: this);
  }

  @override
  void dispose(){
    super.dispose();
    tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final main_card = Card(
        margin: EdgeInsets.all(4.0),
        child: new Material(
          child: new DataTable(columns: cols, rows: rows),
          color: Colors.white70,
        )
    );

    final total_card = Card(
        margin: EdgeInsets.all(4.0),
        child: new Material(
          child: new DataTable(columns: cols_total, rows: rows_total),
        )
    );

    final invest_bar_card = Card(
        margin: EdgeInsets.all(4.0),
        child: new Container(
            child:
            chartWidget_invest_bar
        )
    );

    final invest_pie_card = Card(
        margin: EdgeInsets.all(4.0),
        child: new Container(
            child:
            chartWidget_invest_pie
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
      padding: EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.black54,
          Colors.black54,
        ]),
      ),
      child: ListView(
        scrollDirection: Axis.vertical,
        children: <Widget>[main_card, total_card, invest_bar_card, invest_pie_card],
      ),
    );

    return Scaffold(
      appBar: appBar,
      bottomNavigationBar: _bottom_app_bar(),
      floatingActionButton: _add_button(),
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
//Get logo
//Change color theme
//Create for desktop (MacOS only first)
//Buy www.stockios.com in amazon
//Setup login to save data in AWS
//Get ads cause why not