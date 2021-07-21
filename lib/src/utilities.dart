import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:stream_channel/isolate_channel.dart';

Uint8List generateRandomBytes(int length) {
  if (length < 0) {
    throw Exception('Byte list length must be greater than 0');
  }

  final random = Random();
  final bytes = Uint8List(length);
  for (var i = 0; i < length; i++) {
    bytes[i] = random.nextInt(256);
  }
  return bytes;
}

class SpawnBundle {
  final String serverAddress;
  final SendPort sendPort;

  SpawnBundle(this.serverAddress, this.sendPort);
}

enum IsolateEvent { start, abort }

void listenForEvents(
    IsolateChannel<dynamic> channel,
    Completer<dynamic> startCompleter,
    Completer<dynamic> abortCompleter,
    HttpClient client) {
  // wait for signal from main isolate to stop
  channel.stream.listen((event) {
    if (event is! IsolateEvent) return;
    switch (event) {
      case IsolateEvent.start:
        startCompleter.complete();
        return;
      case IsolateEvent.abort:
        abortCompleter.complete();
        return;
    }
  });
}
