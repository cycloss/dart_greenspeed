import 'package:dart_librespeed/speed_test.dart';

Future<void> main() async {
  print('Starting download test');

  var dlTest = DownloadTest(
      serverAddress:
          'https://mobile-proxy.wessexinternet.net/v1/speed-test/download',
      testDurationMs: 5000,
      updateIntervalMs: 100);
  dlTest.mbpsStream.listen(print);
  dlTest.percentCompleteStream.listen(print);
  await dlTest.start();

  // print('Starting upload test');

  // var ulTest = UploadTest(
  //     serverAddress: 'http://speedtest.wessexinternet.com',
  //     testDurationMs: 10000,
  //     updateIntervalMs: 100);
  // ulTest.mbpsStream.listen(print);
  // ulTest.percentCompleteStream.listen(print);
  // await ulTest.start();

  // print('Starting ping jitter test');

  // var pingTest = PingJitterTest(
  //     serverAddress: 'http://speedtest.wessexinternet.com',
  //     testDurationMs: 10000,
  //     updateIntervalMs: 100);
  // pingTest.pingStream
  //     .listen((pingMs) => print('${pingMs.toStringAsFixed(2)} ms ping'));
  // pingTest.jitterStream.listen((jitterMs) => print('$jitterMs ms jitter'));
  // pingTest.percentStream.listen(print);
  // await pingTest.start();
}
