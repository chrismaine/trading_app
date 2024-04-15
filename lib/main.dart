import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stock Trading App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto', // Using Roboto font for consistency
      ),
      home: HomePage(),
    );
  }
}

  void buyStock() {
    double currentPrice = intradayData.last['price'];
    double totalCost = _quantity * currentPrice;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Purchase'),
          content: Text(
              'Are you sure you want to buy $_quantity shares of $symbol for \$${totalCost.toStringAsFixed(2)}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (userBalance >= totalCost) {
                  setState(() {
                    userBalance -= totalCost;
                    transactions.add({
                      'type': 'Buy',
                      'symbol': symbol,
                      'quantity': _quantity,
                      'price': currentPrice,
                      'totalCost': totalCost,
                      'time': DateTime.now(),
                    });
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'You bought $_quantity shares of $symbol for \$${totalCost.toStringAsFixed(2)}')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Insufficient funds')));
                }
              },
              child: Text('Buy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }