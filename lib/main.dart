import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

int calculateFactorial(int n) {
  if (n <= 0) return 1;
  return n * calculateFactorial(n - 1);
}

class FactorialCalculator {
  final SharedPreferences _prefs;

  FactorialCalculator(this._prefs);

  Future<int> calculateFactorialWithCache(int n) async {
    final cachedResult = _prefs.getInt('factorial_$n');
    if (cachedResult != null) {
      print('Using cached result');
      return cachedResult;
    }

    final result = await compute(calculateFactorial, n);
    _prefs.setInt('factorial_$n', result);
    return result;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Background Processing with Cache Example',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late FactorialCalculator _factorialCalculator;
  late TextEditingController _inputController;
  int? _cachedResult;
  List<int> _cachedFactorials = [];

  @override
  void initState() {
    super.initState();
    _initializeFactorialCalculator();
    _inputController = TextEditingController(text: '5'); // Default value
    _loadCachedResult();
  }

  Future<void> _initializeFactorialCalculator() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _factorialCalculator = FactorialCalculator(prefs);
    });
  }

  Future<void> _loadCachedResult() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedResult = prefs.getInt('factorial_${_inputController.text}');
    setState(() {
      _cachedResult = cachedResult;
      _cachedFactorials = _getStoredFactorials(prefs);
    });
  }

  List<int> _getStoredFactorials(SharedPreferences prefs) {
    final keys = prefs.getKeys();
    final factorials = <int>[];
    for (final key in keys) {
      if (key.startsWith('factorial_')) {
        factorials.add(prefs.getInt(key)!);
      }
    }
    return factorials;
  }

  Future<void> _calculateFactorialInBackground() async {
    final inputNumber = int.tryParse(_inputController.text) ?? 0;
     final prefs = await SharedPreferences.getInstance();
    final result = await _factorialCalculator.calculateFactorialWithCache(inputNumber);
    setState(() {
      _cachedResult = result;
      _cachedFactorials = _getStoredFactorials(prefs
      );
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Background Processing with Cache Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _inputController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Enter Number'),
            ),
            _cachedResult != null
                ? Text('Cached Factorial: $_cachedResult')
                : SizedBox(),
            ElevatedButton(
              onPressed: _calculateFactorialInBackground,
              child: Text('Calculate Factorial'),
            ),
            SizedBox(height: 20),
            Text('Cached Factorials:'),
            Column(
              children: _cachedFactorials.map((factorial) {
                return Text(factorial.toString());
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}