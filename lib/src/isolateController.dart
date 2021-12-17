import 'dart:async';
import 'dart:isolate';

import 'package:dart_librespeed/src/constants.dart';
import 'package:stream_channel/isolate_channel.dart';

import 'utilities.dart';

abstract class IsolateController {
  final List<IsolateChannel> channels = [];
  final int updateIntervalMs;
  final int testDurationMs;
  final String serverAddress;
  final int msGrace = 1000;
  bool abortTest = false;
  final Future<void> Function(SpawnBundle) task;

  IsolateController(
      {required this.serverAddress,
      required this.updateIntervalMs,
      required this.testDurationMs,
      required this.task});

  void close();

  Future<void> start() async {
    reset();
    // initialise isolates with small delay
    await _initialiseIsolates();
    if (abortTest) return;
    // wait 500 ms grace time
    await Future.delayed(Duration(milliseconds: msGrace));
    if (abortTest) return;
    await calculateSpeed();
  }

  Future<void> _initialiseIsolates() async {
    for (var i = 0; i < kIsolateCount; i++) {
      if (abortTest) return;
      var rPort = ReceivePort();
      channels.add(IsolateChannel.connectReceive(rPort));
      await Isolate.spawn(task, SpawnBundle(serverAddress, rPort.sendPort));
      await Future.delayed(Duration(milliseconds: 200));
      if (abortTest) return;
    }
  }

  Future<void> abort() {
    var completer = Completer<void>();
    // signal to the isolates they should stop
    var closed = 0;
    channels.forEach((channel) async {
      channel.sink.add(IsolateEvent.abort);
      if (++closed >= channels.length) {
        completer.complete();
      }
    });
    abortTest = true;
    return completer.future;
  }

  void reset() {
    channels.clear();
    abortTest = false;
  }

  Future<void> calculateSpeed();
}
