import 'dart:async';
import 'package:employee_time_tracking/homePage/work_time.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class TimerState {
  final int seconds;
  final bool isRunning;
  final bool isOnBreak;
  final WorkTime workTime;

  TimerState(this.workTime, {
    required this.seconds,
    required this.isRunning,
    required this.isOnBreak,
  });

  TimerState copyWith({
    int? seconds,
    bool? isRunning,
    bool? isOnBreak,
  }) {
    return TimerState(
      workTime,
      seconds: seconds ?? this.seconds,
      isRunning: isRunning ?? this.isRunning,
      isOnBreak: isOnBreak ?? this.isOnBreak,
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TimerPage(),
    );
  }
}

class TimerPage extends StatefulWidget {
  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  Timer? _timer;

  TimerState state = TimerState(
    WorkTime(hours: 2, minutes: 48, seconds: 14),
    seconds: 0,
    isRunning: false,
    isOnBreak: false,
  );

  void _tick() {
    setState(() {
      state = state.copyWith(seconds: state.seconds + 1);
    });
  }

  void toggleRunning() {
    if (state.isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(
        Duration(seconds: 1),
            (_) => _tick(),
      );
    }

    setState(() {
      state = state.copyWith(
        isRunning: !state.isRunning,
        isOnBreak: false,
      );
    });
  }

  void reset() {
    _timer?.cancel();
    setState(() {
      state = state.copyWith(
        seconds: 0,
        isRunning: false,
      );
    });
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Timer")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              formatTime(state.seconds),
              style: TextStyle(fontSize: 48),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: toggleRunning,
              child: Text(state.isRunning ? "Pause" : "Start"),
            ),
            ElevatedButton(
              onPressed: reset,
              child: Text("Reset"),
            ),
          ],
        ),
      ),
    );
  }
}