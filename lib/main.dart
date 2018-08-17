import 'package:flutter/material.dart';
import 'stockpage.dart';
import 'budgetpage.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Flutter App',
      home: BudgetPage(),
    );
  }
}