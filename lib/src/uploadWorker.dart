import 'dart:async';

import 'package:stream_channel/isolate_channel.dart';

import 'utilities.dart';

class UploadWorker {
  UploadWorker._();

  // 0.5mb chunk size
  static const _CHUNK_SIZE_BYTES = 524288;

  static Future<void> startUpload(SpawnBundle sb) async {
    var channel = IsolateChannel.connectSend(sb.sendPort);
    var abortCompleter = Completer();
    var startCompleter = Completer();
    listenForEvents(channel, startCompleter, abortCompleter);

    // wait for signal to start given by performTest()
    await startCompleter.future;
    var ws = await createWebSocket(sb.serverAddress, sb.authToken);

    var finishedCompleter = Completer();

    var bytes = generateRandomBytes(_CHUNK_SIZE_BYTES);

    ws.listen((data) async {
      if (abortCompleter.isCompleted) {
        await ws.close();
        finishedCompleter.complete();
      } else {
        ws.add(bytes);
        // print('added');
        var megabits = (bytes.length * 8) / 1000000;
        // keep feeding results to the main isolate
        channel.sink.add(megabits);
      }
    });

    return finishedCompleter.future;
  }
}
