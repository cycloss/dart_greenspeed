import 'dart:async';
import 'dart:typed_data';

import 'package:stream_channel/isolate_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'utilities.dart';

class DownloadWorker {
  DownloadWorker._();

  static Future<void> startDownload(SpawnBundle sb) async {
    var channel = IsolateChannel.connectSend(sb.sendPort);
    var abortCompleter = Completer();
    var startCompleter = Completer();
    listenForEvents(channel, startCompleter, abortCompleter);
    await startCompleter.future;
    var ws = WebSocketChannel.connect(Uri.parse(sb.serverAddress));
    while (!abortCompleter.isCompleted) {
      if (abortCompleter.isCompleted) break;

      await for (var data in ws.stream) {
        var bytes = Uint8List.fromList(data);

        if (abortCompleter.isCompleted) break;
        if (!startCompleter.isCompleted) continue;
        var megabits = (bytes.length * 8) / 1048576;
        // keep feeding results to the main isolate
        channel.sink.add(megabits);
      }
    }
    await ws.sink.close();
    await channel.sink.close();
  }
}
