import 'dart:async';

class Tester {
  StreamController<bool> ctrl = StreamController<bool>();

  bool abort = false;

  Tester() {
    ctrl.stream.listen((abort) {
      if (abort) {
        this.abort = abort;
        print('aborting');
      }
    });
  }

  Future<void> start() async {
    var delayStream = Stream.fromFutures(
        List.generate(10, (i) => Future.delayed(Duration(seconds: i))));
    var i = 0;
    await for (var _ in delayStream) {
      if (abort) {
        return;
      }
      print(i++);
    }
  }
}

Future<void> main() async {
  var tester = Tester();
  tester.start();
  await Future.delayed(Duration(seconds: 3));
  // tester.ctrl.sink.add(true);
  tester.abort = true;
}
