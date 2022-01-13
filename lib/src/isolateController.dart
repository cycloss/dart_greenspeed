import 'dart:async';
import 'dart:isolate';

import 'package:stream_channel/isolate_channel.dart';

import 'utilities.dart';

abstract class IsolateController {
  final List<IsolateChannel> channels = [];
  final List<ReceivePort> rPorts = [];
  final int updateIntervalMs;
  final int testDurationMs;
  final int isolateCount;
  final String serverAddress;
  final String? authToken;
  final int msGrace = 1000;
  bool abortTest = false;
  final Future<void> Function(SpawnBundle) task;

  IsolateController(
      {required this.serverAddress,
      this.authToken,
      required this.updateIntervalMs,
      required this.testDurationMs,
      required this.isolateCount,
      required this.task});

  // must close ports on abort and end test
  void closeReceivePorts() {
    for (var rPort in rPorts) {
      rPort.close();
    }
  }

  Future<void> start() async {
    reset();
    // initialise isolates with small delay
    await _initialiseIsolates();
    // wait 500 ms grace time
    await Future.delayed(Duration(milliseconds: msGrace));
    if (abortTest) return;
    await calculateSpeed();
    if (abortTest) return;
    closeReceivePorts();
  }

  Future<void> _initialiseIsolates() async {
    for (var i = 0; i < isolateCount; i++) {
      if (abortTest) return;
      var rPort = ReceivePort();
      rPorts.add(rPort);
      channels.add(IsolateChannel.connectReceive(rPort));
      await Isolate.spawn(
          task, SpawnBundle(serverAddress, authToken, rPort.sendPort));
      await Future.delayed(Duration(milliseconds: 200));
      if (abortTest) return;
    }
  }

  void abort() async {
    // signal to the isolates they should stop
    channels.forEach((channel) {
      channel.sink.add(IsolateEvent.abort);
    });
    abortTest = true;
    closeReceivePorts();
  }

  void reset() {
    closeReceivePorts();
    channels.clear();
    abortTest = false;
  }

  Future<void> calculateSpeed();
}
