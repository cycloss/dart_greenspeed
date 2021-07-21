import 'dart:async';
import 'dart:io';

import 'package:stream_channel/isolate_channel.dart';

import 'utilities.dart';

class DownloadWorker {
  DownloadWorker._();

  static const _CK_SIZE = 100;

  static Future<void> startDownload(SpawnBundle sb) async {
    var channel = IsolateChannel.connectSend(sb.sendPort);
    var abortCompleter = Completer();
    var startCompleter = Completer();
    var client = HttpClient();
    listenForEvents(channel, startCompleter, abortCompleter, client);
    await startCompleter.future;
    while (!abortCompleter.isCompleted) {
      var resp = await _makeRequest(client, sb.serverAddress);
      if (abortCompleter.isCompleted) return;
      await for (var data in resp) {
        if (abortCompleter.isCompleted) return;
        if (!startCompleter.isCompleted) continue;
        var megabits = (data.length * 8) / 1048576;
        // keep feeding results to the main isolate
        channel.sink.add(megabits);
      }
    }
  }

  static Future<HttpClientResponse> _makeRequest(
      HttpClient client, String serverAddress) async {
    var req = await client
        .getUrl(Uri.parse('$serverAddress/garbage.php?ckSize=$_CK_SIZE'));
    return req.close();
  }
}
