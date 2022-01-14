import 'package:dart_greenspeed/speed_test.dart';

Future<void> main() async {
  var baseAddress = 'http://localhost:5001/v1/speed-test';

  print('Starting download test');

  var dlTest = DownloadTest(
      serverAddress: '$baseAddress/download',
      testDurationMs: 10000,
      updateIntervalMs: 100,
      isolateCount: 4);
  dlTest.mbpsStream.listen(print);
  dlTest.percentCompleteStream.listen(print);

  await dlTest.start();
  await dlTest.close();

  print('Starting upload test');

  var ulTest = UploadTest(
      serverAddress: '$baseAddress/upload',
      testDurationMs: 10000,
      updateIntervalMs: 100,
      isolateCount: 2);
  ulTest.mbpsStream.listen(print);
  ulTest.percentCompleteStream.listen(print);

  await ulTest.start();
  await ulTest.close();

  print('Starting ping jitter test');

  var pingJitterTest = PingJitterTest(
      serverAddress: '$baseAddress/ping',
      testDurationMs: 10000,
      updateIntervalMs: 100,
      isolateCount: 1);
  pingJitterTest.pingStream
      .listen((pingMs) => print('${pingMs.toStringAsFixed(2)} ms ping'));
  pingJitterTest.jitterStream
      .listen((jitterMs) => print('$jitterMs ms jitter'));
  pingJitterTest.percentStream.listen(print);

  await pingJitterTest.start();
  await pingJitterTest.close();
}
