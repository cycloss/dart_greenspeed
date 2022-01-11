import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:stream_channel/isolate_channel.dart';

import 'utilities.dart';

class DownloadWorker {
  DownloadWorker._();

  static Future<void> startDownload(SpawnBundle sb) async {
    var channel = IsolateChannel.connectSend(sb.sendPort);
    var abortCompleter = Completer();
    var startCompleter = Completer();
    listenForEvents(channel, startCompleter, abortCompleter);

    /// wait for signal to start given by performTest()
    await startCompleter.future;
    var ws = await _createWebSocket(sb.serverAddress);

    await for (var data in ws) {
      var bytes = Uint8List.fromList(data);

      if (!startCompleter.isCompleted) continue;
      if (abortCompleter.isCompleted) {
        await ws.close();
        break;
      } else {
        var megabits = (bytes.length * 8) / 1048576;
        // keep feeding results to the main isolate
        channel.sink.add(megabits);
      }
    }
  }

  static Future<WebSocket> _createWebSocket(String url) async {
    var client = HttpClient();
    var request = await client.getUrl(Uri.parse(url));
    request.headers.add('Connection', 'upgrade', preserveHeaderCase: true);
    request.headers.add('Upgrade', 'websocket', preserveHeaderCase: true);
    request.headers.add('Authorize',
        '04b4c703948eaa46e2042e680833b4918626b814e2f14aad8227476f8eab3221');
    request.headers
        .add('sec-websocket-version', '13'); // insert the correct version here
    request.headers.add('sec-websocket-key', generateWsKey());

    var response = await request.close();

    if (response.statusCode != 101) {
      var resp = await readResponse(response);
      throw Exception('Failed to upgrade to web socket: $resp');
    }

    var socket = await response.detachSocket();

    return WebSocket.fromUpgradedSocket(
      socket,
      serverSide: false,
    );
  }
}
