/// Tracks rolling frame performance statistics.
///
/// Call [recordFrame(dt)] every game frame to maintain rolling averages.
class PerformanceMonitor {
  PerformanceMonitor({this.rollingWindowSize = 60});

  final int rollingWindowSize;
  final List<double> _frameTimes = [];

  double _minFps = double.infinity;
  double _maxFps = 0;
  int _totalFrames = 0;

  void recordFrame(double dt) {
    if (dt <= 0) return;
    _totalFrames++;

    _frameTimes.add(dt);
    if (_frameTimes.length > rollingWindowSize) {
      _frameTimes.removeAt(0);
    }

    final fps = 1.0 / dt;
    if (fps < _minFps) _minFps = fps;
    if (fps > _maxFps) _maxFps = fps;
  }

  double get fps {
    if (_frameTimes.isEmpty) return 0;
    final avg = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    return avg > 0 ? 1.0 / avg : 0;
  }

  double get frameTime {
    if (_frameTimes.isEmpty) return 0;
    return _frameTimes.last * 1000; // ms
  }

  double get avgFrameTime {
    if (_frameTimes.isEmpty) return 0;
    return _frameTimes.reduce((a, b) => a + b) / _frameTimes.length * 1000;
  }

  double get minFps => _minFps == double.infinity ? 0 : _minFps;
  double get maxFps => _maxFps;
  int get totalFrames => _totalFrames;

  void reset() {
    _frameTimes.clear();
    _minFps = double.infinity;
    _maxFps = 0;
  }
}
