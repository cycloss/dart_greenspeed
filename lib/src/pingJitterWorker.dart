import 'dart:async';

import 'package:stream_channel/isolate_channel.dart';

import 'utilities.dart';

class PingJitterWorker {
  PingJitterWorker._();

  // long method, but has to be as must be static for isolate
  // so member variables are not allowed
  static Future<void> startPJTest(SpawnBundle sb) async {
    var channel = IsolateChannel.connectSend(sb.sendPort);
    var abortCompleter = Completer();
    var startCompleter = Completer();
    listenForEvents(channel, startCompleter, abortCompleter);

    await startCompleter.future;
    var ws = await createWebSocket(sb.serverAddress, sb.authToken);
    var lastPing = 0.0;
    var pingCount = 1;
    var totalPing = 0.0;
    var totalJitter = 0.0;

    // websocket broadcast stream, can be listened to more than once
    // also only gives data from the time when it is listened to
    var wsBs = ws.asBroadcastStream();
    while (!abortCompleter.isCompleted) {
      var pingStart = DateTime.now();
      ws.add('$pingCount');
      await wsBs.first;
      var pingEnd = DateTime.now();
      var currentPing = pingEnd.difference(pingStart).inMicroseconds / 1000;
      totalPing += currentPing;
      var averagePing = totalPing / pingCount;
      var currentJitter = (currentPing - lastPing).abs();
      lastPing = currentPing;
      totalJitter += currentJitter;
      var averageJitter = totalJitter / pingCount;
      var message =
          '${averagePing.toStringAsFixed(2)}-${averageJitter.toStringAsFixed(2)}';
      channel.sink.add(message);
      await Future.delayed(Duration(milliseconds: 4));
      pingCount++;
    }
    await ws.close();
  }
}
