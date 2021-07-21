import 'package:dart_librespeed/speed_test.dart';

void main() async {
  print('Starting download test');

  var dlTest = Test.download(
      serverAddress: 'http://speedtest.wessexinternet.com',
      testDurationMs: 10000,
      updateIntervalMs: 100);
  dlTest.mbpsStream.listen(print);
  dlTest.percentCompleteStream.listen(print);
  await dlTest.start();

  print('Starting upload test');

  var ulTest = Test.upload(
      serverAddress: 'http://speedtest.wessexinternet.com',
      testDurationMs: 10000,
      updateIntervalMs: 100);
  ulTest.mbpsStream.listen(print);
  ulTest.percentCompleteStream.listen(print);
  await ulTest.start();

  return;

  var pingTest =
      PingJitterTest(serverAddress: 'http://speedtest.wessexinternet.com');
  pingTest.pingStream.listen((result) {
    print('${result.value.toStringAsFixed(2)}ms ping');
  });
  pingTest.jitterStream.listen((result) {
    print('${result.value.toStringAsFixed(2)}ms jitter');
  });
  await pingTest.start();
}
