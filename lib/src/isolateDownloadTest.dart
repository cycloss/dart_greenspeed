import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:dart_librespeed/speed_test.dart';
import 'package:stream_channel/isolate_channel.dart';

class IsolateDownloadTest implements DownloadTest {
  final StreamController<double> _mbpsController = StreamController();
  final StreamController<double> _percentController = StreamController();
  final List<IsolateChannel> _channels = [];
  final int updateIntervalMs;
  final int testDurationMs;
  final String serverAddress;
  bool _abort = false;

  @override
  Stream<double> get mbpsStream => _mbpsController.stream;
  @override
  Stream<double> get percentCompleteStream => _percentController.stream;

  IsolateDownloadTest(
      {required this.serverAddress,
      required this.updateIntervalMs,
      required this.testDurationMs});

  @override
  void close() {
    _mbpsController.close();
    _percentController.close();
  }

  @override
  Future<void> start() async {
    _reset();
    // initialise isolates with small delay
    await _initialiseIsolates();
    if (_abort) return;
    // wait 500 ms grace time
    await Future.delayed(Duration(milliseconds: 1000));
    if (_abort) return;
    await _calculateSpeed();
  }

  Future<void> _initialiseIsolates() async {
    for (var i = 0; i < 5; i++) {
      if (_abort) return;
      var rPort = ReceivePort();
      _channels.add(IsolateChannel.connectReceive(rPort));
      await Isolate.spawn(DownloadIsolate.startDownload,
          SpawnBundle(serverAddress, rPort.sendPort));
      await Future.delayed(Duration(milliseconds: 200));
      if (_abort) return;
    }
  }

  Future<void> _calculateSpeed() async {
    var totalMegabitsDownloaded = 0.0;
    var startTime = DateTime.now();
    _channels.forEach((channel) {
      channel.sink.add(IsolateEvent.start);
      channel.stream.listen((mbits) {
        totalMegabitsDownloaded += mbits;
      });
    });
    while (!_abort) {
      var elapsedSecs =
          DateTime.now().difference(startTime).inMilliseconds / 1000;
      if ((elapsedSecs * 1000) > testDurationMs) {
        _percentController.add(1.0);
        await abort();
        return;
      }
      _mbpsController.add(totalMegabitsDownloaded / elapsedSecs);
      _percentController.add((elapsedSecs * 1000) / testDurationMs);
      await Future.delayed(Duration(milliseconds: updateIntervalMs));
    }
  }

  void _reset() {
    _channels.clear();
    _abort = false;
  }

  @override
  Future<void> abort() {
    var completer = Completer<void>();
    // signal to the isolates they should stop
    var closed = 0;
    _channels.forEach((channel) async {
      channel.sink.add(IsolateEvent.abort);
      await channel.sink.close();
      if (++closed >= _channels.length) {
        completer.complete();
      }
    });
    _abort = true;
    return completer.future;
  }
}

class SpawnBundle {
  final String serverAddress;
  final SendPort sendPort;

  SpawnBundle(this.serverAddress, this.sendPort);
}

enum IsolateEvent { start, abort }

class DownloadIsolate {
  DownloadIsolate._();

  static const _CK_SIZE = 100;

  static Future<void> startDownload(SpawnBundle sb) async {
    var channel = IsolateChannel.connectSend(sb.sendPort);
    var abortCompleter = Completer();
    var startCompleter = Completer();
    var client = HttpClient();
    _listenForEvents(channel, startCompleter, abortCompleter, client);
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

  static void _listenForEvents(
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
          client.close();
          channel.sink.close();
          print('Isolate completed');
          return;
      }
    });
  }

  static Future<HttpClientResponse> _makeRequest(
      HttpClient client, String serverAddress) async {
    var req = await client
        .getUrl(Uri.parse('$serverAddress/garbage.php?ckSize=$_CK_SIZE'));
    return req.close();
  }
}

void main() async {
  var test = IsolateDownloadTest(
      serverAddress: 'http://speedtest.wessexinternet.com',
      updateIntervalMs: 500,
      testDurationMs: 10000);
  test.mbpsStream.listen((event) => print(event));
  test.percentCompleteStream.listen((event) => print(event));
  await test.start();
  test.close();
  print('Test completed');
}
