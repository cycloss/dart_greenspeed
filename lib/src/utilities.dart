import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:dart_greenspeed/speed_test.dart';
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
  final String? authToken;
  final SendPort sendPort;

  SpawnBundle(this.serverAddress, this.authToken, this.sendPort);
}

enum IsolateEvent { start, abort }

void listenForEvents(IsolateChannel<dynamic> channel,
    Completer<dynamic> startCompleter, Completer<dynamic> abortCompleter) {
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

Future<WebSocket> createWebSocket(String url, String? authToken) async {
  var client = HttpClient();
  var request = await client.getUrl(Uri.parse(url));
  request.headers.add('Connection', 'upgrade', preserveHeaderCase: true);
  request.headers.add('Upgrade', 'websocket', preserveHeaderCase: true);
  if (authToken != null) {
    request.headers.add('Authorize', authToken);
  }
  request.headers
      .add('sec-websocket-version', '13'); // insert the correct version here
  request.headers.add('sec-websocket-key', generateWsKey());

  var response = await request.close();

  if (response.statusCode == 401 || response.statusCode == 400) {
    throw SpeedTestAuthException();
  } else if (response.statusCode != 101) {
    print(response.statusCode);
    var resp = await readResponse(response);
    throw Exception('Failed to upgrade to web socket: $resp');
  }

  var socket = await response.detachSocket();

  return WebSocket.fromUpgradedSocket(
    socket,
    serverSide: false,
  );
}

String generateWsKey() {
  var r = Random();
  return base64.encode(List<int>.generate(8, (_) => r.nextInt(255)));
}

Future<String> readResponse(HttpClientResponse response) {
  final completer = Completer<String>();
  final contents = StringBuffer();
  var utf8;
  response.transform(utf8.decoder).listen((data) {
    contents.write(data);
  }, onDone: () => completer.complete(contents.toString()));
  return completer.future;
}

Exception parseExecption(String exceptionStr) {
  if ((exceptionStr).contains('SocketException')) {
    return SocketException('Failed to connect web socket');
  }
  if ((exceptionStr).contains('SpeedTestAuthException')) {
    return SpeedTestAuthException('Failed to authorize with speed test server');
  }
  return Exception('Unknown exception thrown by isolate: $exceptionStr');
}
