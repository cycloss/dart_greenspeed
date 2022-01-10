import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:stream_channel/isolate_channel.dart';

import 'utilities.dart';

class PingJitterWorker {
  PingJitterWorker._();

  static Future<void> startPJTest(SpawnBundle sb) async {
    var channel = IsolateChannel.connectSend(sb.sendPort);
    var abortCompleter = Completer();
    var startCompleter = Completer();
    var client = HttpClient();
    listenForEvents(channel, startCompleter, abortCompleter);

    await startCompleter.future;

    var lastPing = 0.0;
    var pingCount = 0;
    var totalPing = 0.0;
    var totalJitter = 0.0;
    while (!abortCompleter.isCompleted) {
      var pingStart = DateTime.now();
      var req = await _makeRequest(client, sb.serverAddress);
      if (abortCompleter.isCompleted) break;
      var resp = await req.close();
      if (abortCompleter.isCompleted) break;
      if (resp.statusCode != 200) {
        throw Exception(
            'Server not operational, status code: ${resp.statusCode}');
      }
      var pingEnd = DateTime.now();
      var currentPing = pingEnd.difference(pingStart).inMicroseconds / 1000;
      totalPing += currentPing;
      var averagePing = totalPing / ++pingCount;
      var currentJitter = (currentPing - lastPing).abs();
      lastPing = currentPing;
      totalJitter += currentJitter;
      var averageJitter = totalJitter / pingCount;
      var message =
          '${averagePing.toStringAsFixed(2)}-${averageJitter.toStringAsFixed(2)}';
      channel.sink.add(message);
    }
    client.close();
    await channel.sink.close();
  }

  static Future<HttpClientRequest> _makeRequest(
      HttpClient client, String serverAddress) async {
    var r = Random().nextDouble();
    return client.getUrl(Uri.parse('$serverAddress/empty.php?r=$r'));
  }
}
