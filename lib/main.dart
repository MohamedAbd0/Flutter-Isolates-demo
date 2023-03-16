// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

String reverseString(String input) {
  return input.split('').reversed.join();
}

void runIsolated(SendPort sendPort) {
  // Do some computation or other long-running task here
  for (int i = 0; i < 10; i++) {
    print(i);
  }
  sendPort.send('Task completed');
}

void isolateCommunicationFunction(SendPort sendPort) {
  ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    if (message is Message) {
      print("Received message in isolate: ${message.content}");
      sendPort.send(Message("Hello from the isolate!"));
    }
  });
}

void runInfiniteInIsolate(int seconds) {
  print("Isolate running");
  // Do some work here...
  Timer.periodic(Duration(seconds: seconds), (timer) {
    print(timer.tick);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late String text = "";

  @override
  void initState() {
    super.initState();
  }

  Future<void> runCompute() async {
    String originalString = 'Hello world';
    String reversedString = await compute(reverseString, originalString);
    print(reversedString);
    setState(() {
      text = reversedString;
    });
  }

  Future<void> runIsolate() async {
    ReceivePort receivePort = ReceivePort();
    await Isolate.spawn(runIsolated, receivePort.sendPort);
    receivePort.listen((message) {
      print('Received message: $message');
      setState(() {
        text = message;
      });
    });
  }

  Future<void> runIsolateFunctionCommunication() async {
    ReceivePort receivePort = ReceivePort();
    await Isolate.spawn(isolateCommunicationFunction, receivePort.sendPort);

    receivePort.listen((message) {
      if (message is SendPort) {
        SendPort sendPort = message;
        sendPort.send(Message("Hello from the main isolate!"));
      } else if (message is Message) {
        print("Received message: ${message.content}");
        setState(() {
          text = message.content;
        });
      }
    });
  }

  stopIsolate() async {
    Isolate isolate = await Isolate.spawn(runInfiniteInIsolate, 1);
    // Wait for 5 seconds and then kill the isolate
    await Future.delayed(const Duration(seconds: 3));
    isolate.kill(priority: Isolate.immediate);
    print("Isolate stopped");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dart Isplates"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(text),
            ElevatedButton(
                onPressed: () => runCompute(), child: Text("run Compute")),
            ElevatedButton(
                onPressed: () => runIsolate(), child: Text("run Isolate")),
            ElevatedButton(
                onPressed: () => runIsolateFunctionCommunication(),
                child: Text("run Isolate Communication")),
            ElevatedButton(
                onPressed: () => stopIsolate(), child: Text("stop Isolate")),
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class Message {
  final String content;
  Message(this.content);
}
