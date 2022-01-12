import 'dart:async';
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
    var ws = await createWebSocket(sb.serverAddress, sb.authToken);

    await for (var data in ws) {
      var bytes = Uint8List.fromList(data);

      if (abortCompleter.isCompleted) {
        await ws.close();
        break;
      } else {
        var megabits = (bytes.length * 8) / 1000000;
        // keep feeding results to the main isolate
        channel.sink.add(megabits);
      }
    }
  }
}
