import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_scalable_ocr/flutter_scalable_ocr.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String text = "";
  final StreamController<String> controller = StreamController<String>();
  bool torchOn = false;
  int cameraSelection = 0;
  bool lockCamera = true;
  bool loading = false;
  final GlobalKey<ScalableOCRState> cameraKey = GlobalKey<ScalableOCRState>();

  bool isValidVIN(String vin) {
    // Check if VIN is null or empty
    if (vin.isEmpty) return false;

    // VIN must be exactly 17 characters
    if (vin.length != 17) return false;

    // Convert to uppercase for consistency
    vin = vin.toUpperCase();

    // Allowed characters: 0-9 and A-Z (excluding I, O, Q)
    final RegExp vinPattern = RegExp(r'^[0-9A-HJ-NPR-Z]+$');
    if (!vinPattern.hasMatch(vin)) return false;

    // Check if contains forbidden letters (I, O, Q)
    if (vin.contains('I') || vin.contains('O') || vin.contains('Q')) {
      return false;
    }

    // Weight table for check digit calculation (position 1-17)
    const List<int> weights = [
      8,
      7,
      6,
      5,
      4,
      3,
      2,
      10,
      0,
      9,
      8,
      7,
      6,
      5,
      4,
      3,
      2,
    ];

    // Value table for letters
    const Map<String, int> transliteration = {
      'A': 1,
      'B': 2,
      'C': 3,
      'D': 4,
      'E': 5,
      'F': 6,
      'G': 7,
      'H': 8,
      'J': 1,
      'K': 2,
      'L': 3,
      'M': 4,
      'N': 5,
      'P': 7,
      'R': 9,
      'S': 2,
      'T': 3,
      'U': 4,
      'V': 5,
      'W': 6,
      'X': 7,
      'Y': 8,
      'Z': 9,
    };

    // Calculate check digit (position 9 in VIN)
    int sum = 0;
    for (int i = 0; i < 17; i++) {
      String char = vin[i];
      int value;

      // If it's a number
      if (int.tryParse(char) != null) {
        value = int.parse(char);
      }
      // If it's a letter
      else {
        value = transliteration[char] ?? 0;
      }

      sum += value * weights[i];
    }

    // Calculate modulo 11
    String checkDigit = (sum % 11).toString();
    if (checkDigit == '10') checkDigit = 'X';

    // Compare calculated check digit with the one in VIN (position 9, index 8)
    return vin[8] == checkDigit;
  }

  void setText(value) {
    // Check if scanned text is a valid VIN
    if (value != null && value.toString().trim().isNotEmpty) {
      String potentialVin = value.toString().trim().toUpperCase();
      bool isVin = isValidVIN(potentialVin);

      // Add to stream for display
      controller.add(potentialVin);

      setState(() {
        text = potentialVin;
      });

      if (isVin) {
        // Show feedback that a valid VIN was detected
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Valid VIN detected!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          // children: <Widget>[
          //   const Text('You have pushed the button this many times:'),
          //   Text(
          //     '$_counter',
          //     style: Theme.of(context).textTheme.headlineMedium,
          //   ),
          // ],
          children: <Widget>[
            !loading
                ? ScalableOCR(
                  key: cameraKey,
                  torchOn: torchOn,
                  cameraSelection: cameraSelection,
                  lockCamera: lockCamera,
                  paintboxCustom:
                      Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 4.0
                        ..color = const Color.fromARGB(153, 102, 160, 241),
                  boxLeftOff: 5,
                  boxBottomOff: 2.5,
                  boxRightOff: 5,
                  boxTopOff: 2.5,
                  boxHeight: MediaQuery.of(context).size.height / 3,
                  getRawData: (value) {
                    inspect(value);
                  },
                  getScannedText: (value) {
                    setText(value);
                  },
                )
                : Padding(
                  padding: const EdgeInsets.all(17.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    height: MediaQuery.of(context).size.height / 3,
                    width: MediaQuery.of(context).size.width,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            StreamBuilder<String>(
              stream: controller.stream,
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                return Result(
                  text: snapshot.data != null ? snapshot.data! : "",
                );
              },
            ),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      loading = true;
                      cameraSelection = cameraSelection == 0 ? 1 : 0;
                    });
                    Future.delayed(const Duration(milliseconds: 150), () {
                      setState(() {
                        loading = false;
                      });
                    });
                  },
                  child: const Text("Switch Camera"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      loading = true;
                      torchOn = !torchOn;
                    });
                    Future.delayed(const Duration(milliseconds: 150), () {
                      setState(() {
                        loading = false;
                      });
                    });
                  },
                  child: const Text("Toggle Torch"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      loading = true;
                      lockCamera = !lockCamera;
                    });
                    Future.delayed(const Duration(milliseconds: 150), () {
                      setState(() {
                        loading = false;
                      });
                    });
                  },
                  child: const Text("Toggle Lock Camera"),
                ),
              ],
            ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class Result extends StatelessWidget {
  const Result({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const Text("Scan a VIN number");
    }

    // Check if scanned text is valid VIN
    final _MyHomePageState state =
        context.findAncestorStateOfType<_MyHomePageState>()!;
    bool isValid = text.length == 17 && state.isValidVIN(text);

    return Column(
      children: [
        Text("Scanned text: $text"),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isValid ? Colors.green.shade100 : Colors.red.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.error,
                color: isValid ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isValid ? "Valid VIN" : "Invalid VIN format",
                    style: TextStyle(
                      color:
                          isValid ? Colors.green.shade800 : Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
