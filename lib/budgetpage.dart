import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'homepage.dart';

class expense_item {
  String _name;
  String _amount;

  expense_item(this._name, this._amount);
}

class BudgetPage extends StatefulWidget {

  BudgetPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyBudgetState createState() => new _MyBudgetState();
}

class _MyBudgetState extends State<BudgetPage> {
  bool load_done_1 = false;
  bool load_done_2 = false;

  List<expense_item> table_objects;

  int _currentIndex = 0;
  List<String> expenses = ['Rent', 'Food'];
  List<String> amounts = ['900', '200'];
  String new_expense = '';
  String new_amount = '';
  String new_salary;
  String new_spending;

  List<DataRow> expense_rows = [];
  List<DataRow> total_rows = [];
  List<DataRow> salary_rows = [];

  String salary = '10000.00';
  String monthly_salary = '${(10000/12).toStringAsFixed(2)}';
  String total = '';
  String extra = '';

  var chartWidget_spending_bar;
  var chartWidget_spending_pie;

  final List<DataColumn> cols_expenses = [
    new DataColumn(
      label: new Center(child: new Text('Expense')),
    ),
    new DataColumn(
      label: new Center(child: new Text('Amount')),
    ),
  ];

  final List<DataColumn> cols_salary = [
    new DataColumn(
      label: new Center(child: new Text('Yearly Salary')),
    ),
    new DataColumn(
      label: new Center(child: new Text('Monthly Salary')),
    ),
  ];

  final List<DataColumn> cols_totals = [
    new DataColumn(
      label: new Center(child: new Text('Total Extra')),
    ),
    new DataColumn(
      label: new Center(child: new Text('Total Spent')),
    ),
  ];

  _create_table_object(){
    List<expense_item> temp_table_objects = [];
    for(var i = 0; i < expenses.length; i++){
      temp_table_objects.add(new expense_item(expenses[i], amounts[i]));
    }
    setState(() {
      table_objects = temp_table_objects;
    });
  }

  Future _set_settings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs = await SharedPreferences.getInstance();
    prefs.setStringList('expenses', ['Vanguard']);
    prefs.setStringList('expense_amounts', ['200']);
    prefs.setString('monthly_salary', 3400.toStringAsFixed(2));
  }

  Future _load_settings() async {
    List<String> temp_expense;
    List<String> temp_amounts;
    String temp_monthly;
    String temp_yearly;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs = await SharedPreferences.getInstance();
    if((prefs.getStringList('expenses') != null)){
      temp_expense = prefs.getStringList('expenses');
      temp_amounts = prefs.getStringList('expense_amounts');
      temp_monthly = prefs.getString('monthly_salary');
      temp_yearly = ('${(double.parse(temp_monthly) * 12).toStringAsFixed(2)}');
    }
    else{
      temp_expense = expenses;
      temp_amounts = amounts;
      temp_monthly = monthly_salary;
      temp_yearly = salary;
    }
    setState(() {
      expenses = temp_expense;
      amounts = temp_amounts;
      monthly_salary = temp_monthly;
      salary = temp_yearly;
      load_done_1 = true;
    });
  }

  void onTabTapped(int index) {
    if (index == 0) {
      print('Do Nothing.');
    }
    if (index == 1) {
      Navigator.push(context, new MaterialPageRoute(
          builder: (context) => new MyHomePage()));
    }
    if (index == 3) {
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
      onPressed: () =>
          showDialog(
              context: context,
              child: new AlertDialog(
                title: new Center(child: Text("Add new expense")),
                content: new Container(
                    width: 260.0,
                    height: 130.0,
                    decoration: new BoxDecoration(
                      shape: BoxShape.rectangle,
                      color: const Color(0xFFFFFF),
                      borderRadius: new BorderRadius.all(
                          new Radius.circular(10.0)),
                    ),
                    child: new Column(children: <Widget>[
                      new Expanded(child: new Padding(
                          padding: EdgeInsets.all(10.0), child: new TextField(
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
                      new Expanded(child: new Padding(
                          padding: EdgeInsets.all(10.0), child: new TextField(
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
          icon: Icon(Icons.settings),
          title: Text('Settings'),
        )
      ],
    );
    return bottom_menu;
  }

  _save_expense(String name, String amount) async {
    setState(() {
      expenses.add(name);
      amounts.add(amount);
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs = await SharedPreferences.getInstance();

    prefs.setStringList('expenses', expenses);
    prefs.setStringList('expense_amounts', amounts);

    _create_table_object();
    _get_expense_table();
    _get_total_table();
    _create_charts();
  }

  _save_salary(String amount) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs = await SharedPreferences.getInstance();

    prefs.setString('monthly_salary', monthly_salary);
  }

  _delete_expense(int index) async{
    List<String> temp_name_list = [];
    List<String> temp_amount_list = [];

    for(var i = 0; i < table_objects.length; i++){
      temp_name_list.add(table_objects[i]._name);
      temp_amount_list.add(table_objects[i]._amount);
    }
    temp_name_list.removeAt(index);
    temp_amount_list.removeAt(index);
    setState(() {
      print('Removing ${table_objects[index]._name}');
      table_objects.removeAt(index);
      expenses = temp_name_list;
      amounts = temp_amount_list;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs = await SharedPreferences.getInstance();

    prefs.setStringList('expenses', temp_name_list);
    prefs.setStringList('expense_amounts', temp_amount_list);

    _get_expense_table();
    _get_total_table();
    _create_charts();

  }

  _expense_dialog(String name, int index) {
    showDialog(
        context: context,
        child: new AlertDialog(
          title: new Center(child: Text("Change ${name} amount")),
          content: new Container(
              width: 260.0,
              height: 70.0,
              decoration: new BoxDecoration(
                shape: BoxShape.rectangle,
                color: const Color(0xFFFFFF),
                borderRadius: new BorderRadius.all(new Radius.circular(10.0)),
              ),
              child: new Column(children: <Widget>[
                new Expanded(child: new Padding(
                    padding: EdgeInsets.all(10.0), child: new TextField(
                  decoration: new InputDecoration(
                      border: new OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          const Radius.circular(10.0),
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[300],
                      labelText: "${name} spending"
                  ),
                  onChanged: (String text) {
                    setState(() {
                      new_spending = text;
                    });
                  },
                ))),
              ])),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Delete", style: new TextStyle(color: Colors.red)),
              onPressed: () {
                _delete_expense(index);
                Navigator.pop(context);
              },
            ),
            new FlatButton(
              child: new Text("Cancel", style: new TextStyle(color: Colors.black54)),
              onPressed: () => Navigator.pop(context),
            ),
            new FlatButton(
              child: new Text("Change"),
              onPressed: () {
                table_objects[index]._amount = new_spending;
                _get_expense_table();
                _get_total_table();
                print('Resetting new expense data.');
                _save_salary(monthly_salary);
                Navigator.pop(context);
              },
            )
          ],
        )
    );
  }

  _salary_dialog() {
    showDialog(
        context: context,
        child: new AlertDialog(
          title: new Center(child: Text("Change salary")),
          content: new Container(
              width: 260.0,
              height: 70.0,
              decoration: new BoxDecoration(
                shape: BoxShape.rectangle,
                color: const Color(0xFFFFFF),
                borderRadius: new BorderRadius.all(new Radius.circular(10.0)),
              ),
              child: new Column(children: <Widget>[
                new Expanded(child: new Padding(
                    padding: EdgeInsets.all(10.0), child: new TextField(
                  decoration: new InputDecoration(
                      border: new OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          const Radius.circular(10.0),
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[300],
                      labelText: "Monthly Income"
                  ),
                  onChanged: (String text) {
                    setState(() {
                      new_salary = text;
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
              child: new Text("Change"),
              onPressed: () {
                monthly_salary = new_salary;
                salary = ('${(double.parse(new_salary) * 12).toStringAsFixed(2)}');
                _get_salary_table();
                _get_total_table();
                print('Resetting new expense data.');
                _save_salary(monthly_salary);
                Navigator.pop(context);
              },
            )
          ],
        )
    );
}

  _get_salary_table(){
    String temp_monthly_salary = (double.parse(salary) / 12).toStringAsFixed(2);;
    List<DataRow> salaries = [];
    salaries.add(new DataRow(
        cells: [
          new DataCell(new Text('\$${salary}', style: new TextStyle(color: Colors.green)),
              showEditIcon: false,
              onTap: () {
                print('\$${salary}');
              }
          ),
          new DataCell(new Text('\$${monthly_salary}', style: new TextStyle(color: Colors.green)),
              showEditIcon: true,
              onTap: () {
                _salary_dialog();
                print('\$${monthly_salary}');
              }
          ),
        ]
    ));
    setState(() {
      salary_rows = salaries;
      monthly_salary = temp_monthly_salary;
    });
  }

  _get_total_table(){
    List<DataRow> rows_total = [];
    double temp_total = 0.0;
    double temp_extra = 0.0;
    for (var i = 0; i < table_objects.length; i++) {
      print(table_objects[i]._name);
      print(table_objects[i]._amount);
      temp_total += double.parse(table_objects[i]._amount);
      print(temp_total);
    }
    temp_extra = (double.parse(monthly_salary) - temp_total);
    setState((){
      total = temp_total.toStringAsFixed(2);
      extra = temp_extra.toStringAsFixed(2);
    });
    rows_total.add(new DataRow(
        cells: [
          new DataCell(new Text('\$${extra}', style: new TextStyle(color: Colors.green)),
              showEditIcon: false,
              onTap: () {
                print('${extra}');
              }
          ),
          new DataCell(new Text('-\$${total}', style: new TextStyle(color: Colors.red)),
              showEditIcon: false,
              onTap: () {
                print('\$${total}');
              }
          ),
        ]
    ));
    setState((){
      total_rows = rows_total;
    });
  }

  _get_expense_table() {

//    SORT OBJECT
    List<expense_item> sorted_objects = table_objects;
    setState(() {
      sorted_objects.sort((a, b) => double.parse(a._amount).compareTo(double.parse(b._amount)));
//    Inverse List
      table_objects = sorted_objects.reversed.toList();
    });
    sorted_objects = [];

//    CREATE ROWS
    List<DataRow> rows = [];
    for (var i = 0; i < table_objects.length; i++) {
      rows.add(new DataRow(
          cells: [
            new DataCell(new Text(table_objects[i]._name),
                showEditIcon: false,
                onTap: () {
                  _expense_dialog(table_objects[i]._name, i);
                  print('${table_objects[i]._name}, ${table_objects[i]._amount}, ${i}');
                }
            ),
            new DataCell(new Text('-\$${table_objects[i]._amount}', style: new TextStyle(color: Colors.red)),
                showEditIcon: false,
                onTap: () {
                  _expense_dialog(table_objects[i]._name, i);
                  print('${table_objects[i]._name}, ${table_objects[i]._amount}, ${i}');
                }
            ),
          ]
      ));
    }
    setState((){
      expense_rows = rows;
    });
  }

  _create_charts() {
    var spending_chart_data = [
      new charts.Series(
        id: 'Spending Bar',
        domainFn: (expense_item clickData, _) => clickData._name,
        measureFn: (expense_item clickData, _) => double.parse(clickData._amount),
        data: table_objects,
      ),
    ];

    var chart_spending_bar = new charts.BarChart(
      spending_chart_data,
      animate: true,
      defaultRenderer: new charts.BarRendererConfig(
          cornerStrategy: const charts.ConstCornerStrategy(30)),
    );

    var chart_spending_pie = new charts.PieChart(
        spending_chart_data,
        animate: true,
        defaultRenderer: new charts.ArcRendererConfig(
            arcWidth: 60,
            arcRendererDecorators: [new charts.ArcLabelDecorator()])
    );

    setState((){
      print('Created investment bar chart.');
      chartWidget_spending_bar= new Padding(
        padding: new EdgeInsets.all(32.0),
        child: new SizedBox(
          height: 400.0,
          child: chart_spending_bar,
        ),
      );

      print('Created investment pie chart.');
      chartWidget_spending_pie = new Padding(
        padding: new EdgeInsets.all(4.0),
        child: new SizedBox(
          height: 300.0,
          child: chart_spending_pie,
        ),
      );
    });
  }

//  _show_expense_dialog() {
//    _showdetails(String curticker, String buy, String curcurrent, String date, String broker, int position) {
//      showDialog(context: context,
//          child: new AlertDialog(
//              title: new Center(child: Text("$curticker Details")),
//              content: new Container(
//                  width: 260.0,
//                  height: 150.0,
//                  decoration: new BoxDecoration(
//                    shape: BoxShape.rectangle,
//                    color: const Color(0xFFFFFF),
//                    borderRadius: new BorderRadius.all(new Radius.circular(10.0)),
//                  ),
//                  child: new Column(children: <Widget>[
//                    new Row(children: <Widget>[
//                      new Expanded(child: new Text('Ticker :', textAlign: TextAlign.left)),
//                      new Expanded(child: new Text('$curticker', textAlign: TextAlign.right))
//                    ],
//                    ),
//                    new Row(children: <Widget>[
//                      new Expanded(child: new Text('Buy :', textAlign: TextAlign.start)),
//                      new Expanded(child: new Text('\$$buy', textAlign: TextAlign.end))
//                    ],
//                    ),
//                    new Row(children: <Widget>[
//                      new Expanded(child: new Text('Current :', textAlign: TextAlign.left)),
//                      new Expanded(child: new Text('\$$curcurrent', textAlign: TextAlign.right))
//                    ],
//                    ),
//                    new Row(children: <Widget>[
//                      new Expanded(child: new Text('Date :', textAlign: TextAlign.left)),
//                      new Expanded(child: new Text('$date', textAlign: TextAlign.right))
//                    ],
//                    ),
//                    new Row(children: <Widget>[
//                      new Expanded(child: new Text('Broker :', textAlign: TextAlign.left)),
//                      new Expanded(child: new Text('$broker', textAlign: TextAlign.right))
//                    ],
//                    ),
//                    new Row(children: <Widget>[
//                      new Expanded(child: new Padding(padding: EdgeInsets.all(5.0), child: new RaisedButton(
//                        child: new Text("Delete", textAlign: TextAlign.left),
//                        color: Colors.red,
//                        onPressed: () {
//                          setState((){
//                            ticker.removeAt(position);
//                            buying.removeAt(position);
//                            dates.removeAt(position);
//                            current.removeAt(position);
//                            brokers.removeAt(position);
//                          });
//                          _refresh();
//                          Navigator.pop(context);
//                        },
//                      ))),
//                      new Expanded(child: new Padding(padding: EdgeInsets.all(5.0), child: new RaisedButton(
//                        child: new Text("Close", textAlign: TextAlign.right),
//                        onPressed: () {
//                          Navigator.pop(context);
//                        },
//                      )))
//                    ],
//                    ),
//                  ]
//                  )
//              )
//          )
//      );
//    }
//  }

  _load() async{
    print('Loading data.');
    await _load_settings();
    while(true){
      if(load_done_1 == true){
        break;
      }
    }
    print('Loading table data object');
    _create_table_object();
    print('Loading expense table data');
    _get_expense_table();
    print('Loading total table data');
    _get_total_table();
    print('Loading expense table data');
    _get_salary_table();
    print('Loading charts');
    _create_charts();
  }

  @override
  void initState() {
//    _set_settings();
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

    final total_card = Card(
        margin: EdgeInsets.all(4.0),
        child: new Material(
          child: new DataTable(columns: cols_totals, rows: total_rows),
        )
    );

    final salaries_card = Card(
        margin: EdgeInsets.all(4.0),
        child: new Material(
          child: new DataTable(columns: cols_salary, rows: salary_rows),
        )
    );

    final spending_bar_card = Card(
        margin: EdgeInsets.all(4.0),
        child: new Container(
            child: chartWidget_spending_bar
        )
    );

    final spending_pie_card = Card(
        margin: EdgeInsets.all(4.0),
        child: new Container(
            child: chartWidget_spending_pie
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
        children: <Widget>[salaries_card, expense_card, total_card, spending_bar_card, spending_pie_card],
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