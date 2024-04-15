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

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String apiKey = 'GEGBPZAOZMHVLTDQ';
  String symbol = 'IBM';
  double userBalance = 1000.0; // Initial user balance
  List<Map<String, dynamic>> intradayData = [];
  List<Map<String, dynamic>> transactions = [];
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    fetchIntradayData();
    Timer.periodic(Duration(minutes: 5), (Timer t) => fetchIntradayData());
  }

  Future<void> fetchIntradayData() async {
    final response = await http.get(Uri.parse(
        'https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol=$symbol&interval=5min&apikey=$apiKey'));
    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      setState(() {
        intradayData = _extractIntradayData(jsonData);
      });
    } else {
      throw Exception('Failed to load intraday data');
    }
  }

  List<Map<String, dynamic>> _extractIntradayData(
      Map<String, dynamic> jsonData) {
    List<Map<String, dynamic>> data = [];
    jsonData['Time Series (5min)'].forEach((key, value) {
      data.add({
        'time': key,
        'price': double.parse(value['4. close']),
      });
    });
    return data;
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
}