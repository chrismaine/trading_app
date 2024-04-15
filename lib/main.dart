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
  
  void sellStock() {
    double currentPrice = intradayData.last['price'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Quantity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _quantity = int.tryParse(value) ?? 1;
                  });
                },
              ),
              SizedBox(height: 16),
              Text(
                  'Total Earn: \$${(_quantity * currentPrice).toStringAsFixed(2)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                double totalEarn = _quantity * currentPrice;
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Confirm Sale'),
                      content: Text(
                          'Are you sure you want to sell $_quantity shares of $symbol for \$${totalEarn.toStringAsFixed(2)}?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            if (_quantity > 0) {
                              setState(() {
                                userBalance += totalEarn;
                                transactions.add({
                                  'type': 'Sell',
                                  'symbol': symbol,
                                  'quantity': _quantity,
                                  'price': currentPrice,
                                  'totalEarn': totalEarn,
                                  'time': DateTime.now(),
                                });
                              });
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(
                                      'You sold $_quantity shares of $symbol for \$${totalEarn.toStringAsFixed(2)}')));
                            }
                          },
                          child: Text('Sell'),
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
              },
              child: Text('Proceed'),
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
  double calculatePortfolioValue() {
    double holdingsValue = transactions.fold(0, (prev, transaction) {
      if (transaction['type'] == 'Buy' && transaction['symbol'] == symbol) {
        return prev + (transaction['totalCost'] ?? 0);
      } else if (transaction['type'] == 'Sell' && transaction['symbol'] == symbol) {
        return prev - transaction['price'];
      } else {
        return prev;
      }
    });
    return holdingsValue + userBalance;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stock Trading App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Symbol: $symbol',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Balance: \$${userBalance.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  'Portfolio Value: \$${calculatePortfolioValue().toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              flex: 2,
              child: intradayData.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: <ChartSeries>[
                  LineSeries<Map<String, dynamic>, String>(
                    dataSource: intradayData,
                    xValueMapper: (Map<String, dynamic> data, _) => data['time'],
                    yValueMapper: (Map<String, dynamic> data, _) => data['price'],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  var transaction = transactions[index];
                  return ListTile(
                    title: Text(
                        '${transaction['type']} ${transaction['symbol']} for \$${transaction['totalCost']}'),
                    subtitle: Text(
                        '${transaction['quantity']} shares at ${transaction['price']} each - ${transaction['time']}'),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Enter Quantity'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    _quantity = int.tryParse(value) ?? 1;
                                  });
                                },
                              ),
                              SizedBox(height: 16),
                              Text(
                                  'Total Cost: \$${(_quantity * intradayData.last['price']).toStringAsFixed(2)}'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                buyStock();
                              },
                              child: Text('Proceed'),
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
                  },
                  child: Text('Buy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    sellStock();
                  },
                  child: Text('Sell'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
