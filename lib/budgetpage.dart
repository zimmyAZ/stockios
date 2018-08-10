import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'homepage.dart';

class totals{
  final String _ticker;
  final double _amount;
  final int _quantity;

  totals(this._ticker, this._amount, this._quantity);
}

class BudgetPage extends StatefulWidget {

  BudgetPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyBudgetState createState() => new _MyBudgetState();
}

class _MyBudgetState extends State<BudgetPage>{
  bool load_done_1 = false;
  bool load_done_2 = false;

  int _currentIndex = 1;
  List<String> expenses;
  List<String> amounts;
  String new_expense = '';
  String new_amount = '';
  List<DataRow> expense_rows = [];


  final List<DataColumn> cols_expenses = [
    new DataColumn(
      label: new Center(child: new Text('Expense')),
    ),
    new DataColumn(
      label: new Center(child: new Text('Amount')),
    ),
  ];

  _set_settings() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs = await SharedPreferences.getInstance();
    prefs.setStringList('expenses', ['Vanguard']);
    prefs.setStringList('expense_amounts', ['200']);
  }

  _load_settings() async{
    List<String> temp_expense;
    List<String> temp_amounts;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs = await SharedPreferences.getInstance();

    temp_expense = prefs.getStringList('expenses');
    temp_amounts = prefs.getStringList('expense_amounts');
    print(temp_expense);
    print(temp_amounts);

    setState(() {
      expenses = temp_expense;
      amounts = temp_amounts;
      load_done_1 = true;
    });

  }

  void onTabTapped(int index) {
    if(index == 0){
      Navigator.push(context, new MaterialPageRoute(
          builder: (context) => new MyHomePage()));
    }
    if(index == 1){
      print('Do Nothing.');
    }
    setState(() {
      _currentIndex = index;
    });
  }

  _add_button() {
    final add_button = new FloatingActionButton(
      tooltip: 'Add',
      child: Icon(Icons.add),
      backgroundColor: Colors.green,
      onPressed: () => showDialog(
          context: context,
          child: new AlertDialog(
            title: new Center(child: Text("Add new expense")),
            content: new Container(
                width: 260.0,
                height: 130.0,
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
                        labelText: "Name"
                    ),
                    onChanged: (String text) {
                      setState(() {
                        new_expense = text;
                      });
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
                        labelText: "Amount"
                    ),
                    onChanged: (String text) {
                      setState(() {
                        new_amount = text;
                      });
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
                  _save_expense(new_expense, new_amount);
                  print('Resetting new expense data.');
                  Navigator.pop(context);
                },
              )
            ],
          )
      ),
    );
    return add_button;
  }

  _bottom_app_bar(){
    final bottom_menu = new BottomNavigationBar(
      onTap: onTabTapped, // new
      currentIndex: _currentIndex, // new
      items: [
        new BottomNavigationBarItem(
          icon: Icon(Icons.show_chart),
          title: Text('Stocks'),
        ),
        new BottomNavigationBarItem(
          icon: Icon(Icons.credit_card),
          title: Text('Budget'),
        ),
        new BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          title: Text('Settings'),
        )
      ],
    );
    return bottom_menu;
  }

  _save_expense(String name, String amount) async {

    setState(() {
      print(expenses.toString());
      print(amounts.toString());
      expenses.add(name);
      amounts.add(amount);
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs = await SharedPreferences.getInstance();

    prefs.setStringList('expenses', expenses);
    prefs.setStringList('expense_amounts', amounts);

    _get_expense_table();
  }

  _get_expense_table() {
    List<DataRow> temp_rows = [];
    print(expenses.length);
    print(amounts.length);
    for (var i = 0; i < expenses.length; i++) {
      temp_rows.add(new DataRow(
          cells: [
            new DataCell(new Center(child: Text(expenses[i])),
                showEditIcon: false,
                onTap: () {
                  print('${expenses[i]}, ${amounts[i]}');
                }
            ),
            new DataCell(new Center(child:Text('\$${amounts[i]}')),
                showEditIcon: false,
                onTap: () {
                  print('${expenses[i]}, ${amounts[i]}');
                }
            ),
          ]
      ));
    }
    setState((){
      expense_rows = temp_rows;
    });
  }

  _load(){
    print('Loading data.');
    _load_settings();
    while(true){
      if(load_done_1 == true){
        break;
      }
    }
    print('Getting expense table data');
    _get_expense_table();
  }

  @override
  void initState() {
    _set_settings();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: const Text('Budget Monitor'),
      backgroundColor: Colors.green,
//      actions: <Widget>[
//        new IconButton(icon: new Icon(Icons.refresh), onPressed: _refresh)
//      ],
    );

    final expense_card = Card(
        margin: EdgeInsets.all(4.0),
        child: new Material(
          child: new DataTable(columns: cols_expenses, rows: expense_rows),
        )
    );

    final body = Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.black45,
          Colors.black45,
        ]),
      ),
      child: ListView(
        scrollDirection: Axis.vertical,
        children: <Widget>[expense_card],
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