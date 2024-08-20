import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Price Ticker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StockTickerPage(),
    );
  }
}

class StockTickerPage extends StatefulWidget {
  @override
  _StockTickerPageState createState() => _StockTickerPageState();
}

class _StockTickerPageState extends State<StockTickerPage> {
  late StreamController<Map<String, double>> _streamController;
  late Stream<Map<String, double>> _broadcastStream;
  late Timer _timer;
  final Random _random = Random();

  final List<String> _stocks = ['RELIANCE', 'AIRTEL', 'ITC', 'TATA STEEL', 'INFOSYS'];

  @override
  void initState() {
    super.initState();

    _streamController = StreamController<Map<String, double>>();
    _broadcastStream = _streamController.stream.asBroadcastStream();

    // Simulate stock price updates every second
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      final Map<String, double> stockUpdates = {};
      for (String stock in _stocks) {
        stockUpdates[stock] = 3000 + _random.nextDouble() * 50 * (_random.nextBool() ? 1 : -1);
      }
      _streamController.add(stockUpdates);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Stock Price Ticker')),
      ),
      body: Column(
        children: _stocks.map((stock) {
          return Expanded(
            child: StockItemWidget(
              stockSymbol: stock,
              stockStream: _broadcastStream,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class StockItemWidget extends StatefulWidget {
  final String stockSymbol;
  final Stream<Map<String, double>> stockStream;

  StockItemWidget({required this.stockSymbol, required this.stockStream});

  @override
  _StockItemWidgetState createState() => _StockItemWidgetState();
}

class _StockItemWidgetState extends State<StockItemWidget>
    with SingleTickerProviderStateMixin {
  late double _currentPrice;
  late double _previousPrice;
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _currentPrice = 1000.0;
    _previousPrice = _currentPrice;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.white,
    ).animate(_animationController);

    widget.stockStream.listen((stockData) {
      if (stockData.containsKey(widget.stockSymbol)) {
        setState(() {
          _previousPrice = _currentPrice;
          _currentPrice = stockData[widget.stockSymbol]!;
          _updateColorAnimation();
          _animationController.forward(from: 0.0);
        });
      }
    });
  }

  void _updateColorAnimation() {
    if (_currentPrice > _previousPrice) {
      _colorAnimation = ColorTween(
        begin: Colors.green.withOpacity(0.5),
        end: Colors.white,
      ).animate(_animationController);
    } else if (_currentPrice < _previousPrice) {
      _colorAnimation = ColorTween(
        begin: Colors.red.withOpacity(0.5),
        end: Colors.white,
      ).animate(_animationController);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.stockSymbol,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                '\₹${_currentPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  color: _currentPrice > _previousPrice
                      ? Colors.green
                      : _currentPrice < _previousPrice
                      ? Colors.red
                      : Colors.black,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
