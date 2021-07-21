import 'dart:async';
import 'dart:isolate';

import 'package:stream_channel/isolate_channel.dart';

import '../speed_test.dart';
import 'utilities.dart';

class IsolatedTest implements Test {
  final StreamController<double> _mbpsController = StreamController();
  final StreamController<double> _percentController = StreamController();
  final List<IsolateChannel> _channels = [];
  final int updateIntervalMs;
  final int testDurationMs;
  final String serverAddress;
  bool _abort = false;
  final Future<void> Function(SpawnBundle) task;
  @override
  Stream<double> get mbpsStream => _mbpsController.stream;
  @override
  Stream<double> get percentCompleteStream => _percentController.stream;

  IsolatedTest(
      {required this.serverAddress,
      required this.updateIntervalMs,
      required this.testDurationMs,
      required this.task});

  @override
  void close() {
    _mbpsController.close();
    _percentController.close();
  }

  @override
  Future<void> start() async {
    _reset();
    // initialise isolates with small delay
    await _initialiseIsolates();
    if (_abort) return;
    // wait 500 ms grace time
    await Future.delayed(Duration(milliseconds: 1000));
    if (_abort) return;
    await _calculateSpeed();
  }

  Future<void> _initialiseIsolates() async {
    for (var i = 0; i < 5; i++) {
      if (_abort) return;
      var rPort = ReceivePort();
      _channels.add(IsolateChannel.connectReceive(rPort));
      await Isolate.spawn(task, SpawnBundle(serverAddress, rPort.sendPort));
      await Future.delayed(Duration(milliseconds: 200));
      if (_abort) return;
    }
  }

  Future<void> _calculateSpeed() async {
    var totalMegabitsDownloaded = 0.0;
    var startTime = DateTime.now();
    _channels.forEach((channel) {
      channel.sink.add(IsolateEvent.start);
      channel.stream.listen((mbits) {
        totalMegabitsDownloaded += mbits;
      });
    });
    while (!_abort) {
      var elapsedSecs =
          DateTime.now().difference(startTime).inMilliseconds / 1000;
      if ((elapsedSecs * 1000) > testDurationMs) {
        _percentController.add(1.0);
        await abort();
        return;
      }
      _mbpsController.add(totalMegabitsDownloaded / elapsedSecs);
      _percentController.add((elapsedSecs * 1000) / testDurationMs);
      await Future.delayed(Duration(milliseconds: updateIntervalMs));
    }
  }

  void _reset() {
    _channels.clear();
    _abort = false;
  }

  @override
  Future<void> abort() {
    var completer = Completer<void>();
    // signal to the isolates they should stop
    var closed = 0;
    _channels.forEach((channel) async {
      channel.sink.add(IsolateEvent.abort);
      await channel.sink.close();
      if (++closed >= _channels.length) {
        completer.complete();
      }
    });
    _abort = true;
    return completer.future;
  }
}
