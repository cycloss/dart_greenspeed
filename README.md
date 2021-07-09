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
  var dlTest =
      DownloadTest(serverAddress: 'http://mydomain.com');
  dlTest.mbpsStream.listen((event) {
    print(event);
  });
  await dlTest.start();

  var ulTest = UploadTest(serverAddress: 'http://mydomain.com');
  ulTest.mbpsStream.listen(print);
  await ulTest.start();

  var pingTest =
      PingJitterTest(serverAddress: 'http://mydomain.com');
  pingTest.pingStream.listen((event) {
    print('${event.toStringAsFixed(2)}ms ping');
  });
  pingTest.jitterStream.listen((event) {
    print('${event.toStringAsFixed(2)}ms jitter');
  });
  await pingTest.start();
}
```
