# Dart Librespeed

A speed test utility to connect and test [Librespeed](https://github.com/librespeed/speedtest) servers. Built for use in a Flutter app.

Supports testing ping (ms), jitter (ms), download speed (megabits/sec) and upload speed (megabits/sec). Also shows the percentage completetion for each test.

## Installing

This library is not available on pub.dev, so add the following to your `pubspec.yaml` dependencies:

```yaml
dart_librespeed:
    git:
      url: https://github.com/lucas979797/dart_librespeed
      ref: main
```

## Simple Usage Example

```dart
import 'package:dart_librespeed/speed_test.dart';

void main() async {
  print('Starting download test');

  var dlTest = DownloadTest(
      serverAddress: 'http://mydomain.com',
      testDurationMs: 10000,
      updateIntervalMs: 100);
  dlTest.mbpsStream.listen(print);
  dlTest.percentCompleteStream.listen(print);
  await dlTest.start();

  print('Starting upload test');

  var ulTest = UploadTest(
      serverAddress: 'http://mydomain.com',
      testDurationMs: 10000,
      updateIntervalMs: 100);
  ulTest.mbpsStream.listen(print);
  ulTest.percentCompleteStream.listen(print);
  await ulTest.start();

  print('Starting ping jitter test');

  var pingTest = PingJitterTest(
      serverAddress: 'http://mydomain.com',
      testDurationMs: 10000,
      updateIntervalMs: 100);
  pingTest.pingStream
      .listen((pingMs) => print('${pingMs.toStringAsFixed(2)} ms ping'));
  pingTest.jitterStream.listen((jitterMs) => print('$jitterMs ms jitter'));
  pingTest.percentStream.listen(print);
  await pingTest.start();
}
```
