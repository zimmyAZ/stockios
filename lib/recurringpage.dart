import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'budgetpage.dart';
import 'recurringpage.dart';
import 'stockpage.dart';

class recurring_item {
  String _name;
  double _amount;
  String _date_started;
  int _repeat_day;

  recurring_item(this._name, this._amount, this._date_started, this._repeat_day);
}

class recurring_chart {
  String day;
  int number;
  charts.Color _color;

  recurring_chart(this.day, this.number, Color _color)
      : this._color = new charts.Color(
      r: _color.red, g: _color.green, b: _color.blue, a: _color.alpha);
}

class RecurringPage extends StatefulWidget {
  RecurringPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyRecurringState createState() => new _MyRecurringState();
}

class _MyRecurringState extends State<RecurringPage> {

  List<recurring_item> recurring_list = [];
  List<recurring_chart> recurring_chart_data = [];
  int _currentIndex = 2;

  List<DataColumn> recurring_cols = [];
  List<DataRow> recurring_rows = [];

  List<DataColumn> next_cols = [];
  List<DataRow> next_rows = [];

  _load_dummy() {
    List<String> dummy_names = ['Spotify', 'WoW', 'HumbleBundle'];
    List<double> dummy_amounts = [15.00, 15.00, 12.00];
    List<String> dummy_dates_started = ['7-9-16', '12-20-17', '8-12-18'];
    List<int> dummy_repeat_days = [20, 15, 12];

    print('No data found, loading dummy data.');
    List<recurring_item> temp_recurring_list = [];
    for (int i = 0; i < dummy_names.length; i++) {
      temp_recurring_list.add(new recurring_item(dummy_names[i], dummy_amounts[i], dummy_dates_started[i], dummy_repeat_days[i]));
    }
    setState(() {
      recurring_list = temp_recurring_list;
    });
  }

  _load_saved() async {
    print(DateTime.now().day);

    bool ready = false;
    print('Loading locally saved data.');
    List<String> temp_names = [];
    List<String> temp_amounts = [];
    List<String> temp_dates_started = [];
    List<String> temp_repeat_days = [];

    List<recurring_item> temp_recurring_list = [];

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs = await SharedPreferences.getInstance();
    if ((prefs.getStringList('recurring_names') != null)) {
      temp_names = prefs.getStringList('recurring_names');
      temp_amounts = prefs.getStringList('recurring_amounts');
      temp_dates_started = prefs.getStringList('recurring_dates_started');
      temp_repeat_days = prefs.getStringList('recurring_repeat_days');

      for (int i = 0; i < temp_names.length; i++) {
        temp_recurring_list.add(new recurring_item(temp_names[i], double.parse(temp_amounts[i]), temp_dates_started[i], int.parse(temp_repeat_days[i])));
      }
      setState(() {
        recurring_list = temp_recurring_list;
      });
      ready = true;
    }
    else {
      _load_dummy();
      ready = true;
    }
    print('Waiting for loading of local data...');
    while(true){
      if(ready == true){
        break;
      }
    }
    print('Done waiting...');
    _sort();
    _load_table();
    _load_chart();
  }

  _load_table() {
    int today = DateTime.now().day;
    int month = DateTime.now().month;
    String next_name = 'Blank';
    double next_amount = 0.00;
    int next_day = 0;

    List<DataColumn> temp_recurring_cols = [
      new DataColumn(label: Text('Name')),
      new DataColumn(label: Text('Amount')),
      new DataColumn(label: Text('Day'))
    ];
    List<DataRow> temp_recurring_rows = [];
    for(var i = 0; i < recurring_list.length; i++){
      temp_recurring_rows.add(new DataRow(cells: [
       new DataCell(new Text(recurring_list[i]._name)),
       new DataCell(new Text('\$ ${recurring_list[i]._amount.toStringAsFixed(2)}')),
       new DataCell(new Text(recurring_list[i]._repeat_day.toString()))
      ]));
    }
    for(var j = 0; j < recurring_list.length; j++){
      if(recurring_list[j]._repeat_day >= today){
        next_name = recurring_list[j]._name;
        next_amount = recurring_list[j]._amount;
        next_day = recurring_list[j]._repeat_day;
        break;
      }
    }
    List<DataColumn> temp_next_cols = [
      new DataColumn(label: Text('${next_name}')),
      new DataColumn(label: Text('\$ ${next_amount}')),
      new DataColumn(label: Text('${month}/${next_day}'))
    ];
    setState(() {
      next_cols = temp_next_cols;
      next_rows = [];
      recurring_cols = temp_recurring_cols;
      recurring_rows = temp_recurring_rows;
    });
  }

  _load_chart() {
    for(var i = 1; i < 31; i++){
      var count = 0;
      for(var j = 0; j < recurring_list.length; j++){
        if(recurring_list[j]._repeat_day == i) {
          count += 1;
        }
      }

      setState(() {
        recurring_chart_data.add(new recurring_chart(i.toString(), count, Colors.red));
      });
      print('Creating object ${i} with ${count} number of payments');
    }

    var _recurring_chart_data = [
      new charts.Series(
        id: 'Spending Bar',
        domainFn: (recurring_chart clickData, _) => clickData.day,
        measureFn: (recurring_chart clickData, _) =>
            clickData.number,
        colorFn: (recurring_chart clickData, _) =>
        clickData._color,
        data: recurring_chart_data,
      ),
    ];

    var chart_recurring_bar = new charts.BarChart(
      _recurring_chart_data,
      animate: true,
      vertical: true,
      domainAxis: new charts.OrdinalAxisSpec(
          renderSpec: new charts.SmallTickRendererSpec(

            labelStyle: new charts.TextStyleSpec(
                fontSize: 7, // size in Pts.
                color: charts.MaterialPalette.black))),
      defaultRenderer: new charts.BarRendererConfig(
      cornerStrategy: const charts.ConstCornerStrategy(30)),
    );

    var chartWidget_spending_bar = new Padding(
      padding: new EdgeInsets.all(6.0),
      child: new SizedBox(
        height: 150.0,
        child: chart_recurring_bar,
      ),
    );

    var chart_card = new Card(
      margin: EdgeInsets.all(4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(title: Center(child: Text('Month Overview'))),
          chartWidget_spending_bar
        ])
    );
    return chart_card;
  }

  _save_new_item(String name, String amount, String date, String day) async {
    recurring_list.add(new recurring_item(name, double.parse(amount), date, int.parse(day)));
    await _save_to_device();
    _sort();
    _load_table();
  }

  _save_to_device() async {
    List<String> temp_names = [];
    List<String> temp_amounts = [];
    List<String> temp_dates_started = [];
    List<String> temp_repeat_days = [];

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs = await SharedPreferences.getInstance();

    for(var i = 0; i < recurring_list.length; i++) {
      temp_names.add(recurring_list[i]._name);
      temp_amounts.add(recurring_list[i]._amount.toStringAsFixed(2));
      temp_dates_started.add(recurring_list[i]._date_started);
      temp_repeat_days..add(recurring_list[i]._repeat_day.toString());
    }
    prefs.setStringList('recurring_names', temp_names);
    prefs.setStringList('recurring_amounts', temp_amounts);
    prefs.setStringList('recurring_dates_started', temp_dates_started);
    prefs.setStringList('recurring_repeat_days', temp_repeat_days);
  }

  _sort() {
    List<recurring_item> sorted_objects = recurring_list;
    sorted_objects.sort((a, b) =>
        (a._repeat_day).compareTo(b._repeat_day));

    setState(() {
      recurring_list = sorted_objects;
    });
  }

  void onTabTapped(int index) {
    if (index == 0) {
      Navigator.push(context, new MaterialPageRoute(
          builder: (context) => new BudgetPage()));
    }
    if (index == 1) {
      Navigator.push(context, new MaterialPageRoute(
          builder: (context) => new StockPage()));
    }
    if (index == 2) {
      print('Do Nothing.');
    }
    setState(() {
      _currentIndex = index;
    });
  }

  _top_app_bar() {
    final appBar = AppBar(
      title: const Text('Recurring Charges'),
      backgroundColor: Colors.red,
//      actions: <Widget>[
//        new IconButton(icon: new Icon(Icons.refresh), onPressed: _refresh)
//      ],
    );
    return appBar;
  }

  _table_card() {
    final table_card = new Card(
      margin: EdgeInsets.all(4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(title: Center(child: Text('Subscription Overview'))),
          Material(child: new DataTable(columns: recurring_cols, rows: recurring_rows), color: Colors.white),
      ])
    );
    return table_card;
  }

  _next_card() {
    var next_card = new Card(
      margin: EdgeInsets.all(4.0),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(title: Center(child: Text('Next Charge'))),
            Material(child: new DataTable(columns: next_cols, rows: next_rows), color: Colors.white),
          ])
    );
    return next_card;
  }

  _body() {
    final body = Container(
      width: MediaQuery
          .of(context)
          .size
          .width,
      padding: EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.black45,
          Colors.black45,
        ]),
      ),
      child: ListView(
        scrollDirection: Axis.vertical,
        children: <Widget>[_table_card(), _load_chart(), _next_card()],
      ),
    );
    return body;
  }

  _add_button() {
    String new_name = 'Blank';
    String new_amount = '0.00';
    String new_date = 'Blank';
    String new_day = '1';

    final add_button = new FloatingActionButton(
      tooltip: 'Add',
      child: Icon(Icons.add),
      backgroundColor: Colors.red,
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
                        labelText: "Service Name"
                    ),
                    onChanged: (String text) {
                      new_name = text;
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
                        labelText: "Cost"
                    ),
                    onChanged: (String text) {
                      new_amount = text;
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
                        labelText: "Start Date"
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
                        labelText: "Charge Day"
                    ),
                    onChanged: (String text) {
                      new_day = text;
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
                  _save_new_item(new_name, new_amount, new_date, new_day);
                  Navigator.pop(context);
                },
              )
            ],
          )
      ),
    );
    return add_button;
  }

  _bottom_app_bar() {
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

  @override
  void initState() {
    _load_saved();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _top_app_bar(),
      bottomNavigationBar: _bottom_app_bar(),
      floatingActionButton: _add_button(),
      body: _body(),
    );
  }
}

