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

    var bytes = generateRandomBytes(_CHUNK_SIZE_BYTES);

    // websocket broadcast stream, can be listened to more than once
    // also only gives data from the time when it is listened to
    var wsBs = ws.asBroadcastStream();
    while (!abortCompleter.isCompleted) {
      ws.add(bytes);
      var megabits = (bytes.length * 8) / 1000000;
      // keep feeding results to the main isolate
      channel.sink.add(megabits);
      // await acknowledgement of acceptance
      // first automatically closes
      await wsBs.first;
    }
    await ws.close();
  }
}
