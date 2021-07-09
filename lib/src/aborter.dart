mixin Aborter {
  bool _abort = false;

  bool get abort => _abort;
  void abortTest() => _abort = true;

  /// Called by tests on start automatically
  void resetAbort() => _abort = false;
}
