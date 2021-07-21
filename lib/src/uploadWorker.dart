import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:stream_channel/isolate_channel.dart';

import 'utilities.dart';

class UploadWorker {
  UploadWorker._();

  static const _CK_SIZE = 100;
  static const _BUFFER_SIZE_BYTES = 10000;
  static const _BUFFER_SIZE_MEGABITS = _BUFFER_SIZE_BYTES / 1000000 * 8;

  static Future<void> startUpload(SpawnBundle sb) async {
    var channel = IsolateChannel.connectSend(sb.sendPort);
    var abortCompleter = Completer();
    var startCompleter = Completer();
    var client = HttpClient();
    listenForEvents(channel, startCompleter, abortCompleter, client);
    await startCompleter.future;
    while (!abortCompleter.isCompleted) {
      var postReq = await _makePost(client, sb.serverAddress);
      if (abortCompleter.isCompleted) return;
      var bytes = generateRandomBytes(_CK_SIZE * 1000000);
      for (var offset = 0;
          offset + _BUFFER_SIZE_BYTES < bytes.buffer.lengthInBytes;
          offset += _BUFFER_SIZE_BYTES) {
        var byteView = Uint8List.view(bytes.buffer, offset, _BUFFER_SIZE_BYTES);
        postReq.add(byteView);
        await postReq.flush();
        if (abortCompleter.isCompleted) return;
        channel.sink.add(_BUFFER_SIZE_MEGABITS);
        if (abortCompleter.isCompleted) return;
      }
    }
  }

  static Future<HttpClientRequest> _makePost(
      HttpClient client, String serverAddress) async {
    var r = Random().nextDouble();
    var post = await client.postUrl(Uri.parse('$serverAddress/empty.php?r=$r'));
    post.headers.contentType = ContentType.binary;
    // flush the headers to the stream
    await post.flush();
    return post;
  }
}
