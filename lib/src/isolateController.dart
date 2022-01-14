import 'dart:async';
import 'dart:isolate';

import 'package:stream_channel/isolate_channel.dart';

import 'utilities.dart';

abstract class IsolateController {
  final List<IsolateChannel> channels = [];
  final List<ReceivePort> rPorts = [];
  final List<ReceivePort> errorRPorts = [];
  final int updateIntervalMs;
  final int testDurationMs;
  final int isolateCount;
  final String serverAddress;
  final String? authToken;
  final int msGrace = 500;
  bool abortTest = false;
  final Future<void> Function(SpawnBundle) task;

  IsolateController(
      {required this.serverAddress,
      this.authToken,
      required this.updateIntervalMs,
      required this.testDurationMs,
      required this.isolateCount,
      required this.task});

  Future<void> start() async {
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
      var errorRPort = ReceivePort();
      rPorts.add(rPort);
      errorRPorts.add(errorRPort);
      channels.add(IsolateChannel.connectReceive(rPort));
      await Isolate.spawn(
          task, SpawnBundle(serverAddress, authToken, rPort.sendPort),
          onError: errorRPort.sendPort);
      // await Future.delayed(Duration(milliseconds: 100));

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

  // must close ports on abort and end test
  void closeReceivePorts() {
    for (var rPort in rPorts) {
      rPort.close();
    }
    for (var rPort in errorRPorts) {
      rPort.close();
    }
  }

  Future<void> calculateSpeed();
}
