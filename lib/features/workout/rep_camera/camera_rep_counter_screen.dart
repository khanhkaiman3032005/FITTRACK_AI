import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'pose_counter_engine.dart';
import '../../../services/health_guardian_service.dart';

class CameraWorkoutResult {
  final List<int> perSet;
  final int elapsedSeconds;
  final int plankHoldSeconds;
  final bool stoppedForSymptoms;
  const CameraWorkoutResult(
    this.perSet,
    this.elapsedSeconds,
    this.plankHoldSeconds, {
    this.stoppedForSymptoms = false,
  });
  int get totalReps => perSet.fold<int>(0, (a, b) => a + b);
}

enum _Stage { active, rest, done }

class CameraRepCounterScreen extends StatefulWidget {
  final String exerciseName;
  final int sets;
  final int repsPerSet;
  const CameraRepCounterScreen({
    super.key,
    required this.exerciseName,
    required this.sets,
    required this.repsPerSet,
  });
  @override
  State<CameraRepCounterScreen> createState() => _CameraRepCounterScreenState();
}

class _CameraRepCounterScreenState extends State<CameraRepCounterScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  PoseDetector? _detector;
  Timer? _clock;
  bool _busy = false, _paused = false, _stopping = false;
  bool _confirmingSafetyStop = false;
  String? _error;
  String _cue = 'Đặt camera sao cho nhìn thấy toàn thân.';
  late final ExerciseKind _kind;
  late RepDetector _counter;
  _Stage _stage = _Stage.active;
  int _set = 1, _rest = 30, _elapsed = 0, _hold = 0, _plankTotal = 0;
  final List<int> _completed = [];
  DateTime? _lastAligned;
  DateTime? _lastFrame;
  DateTime? _lastProcessed;
  int _alignedFrames = 0;
  bool _plankLocked = false;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  bool get _plank => _kind == ExerciseKind.plank;
  int get _target => _plank ? 30 : widget.repsPerSet;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _kind = exerciseKindFromName(widget.exerciseName) ?? ExerciseKind.squat;
    _counter = RepDetector(_kind);
    if (!_supported || exerciseKindFromName(widget.exerciseName) == null) {
      _error = 'Camera Pose Detection chỉ được hỗ trợ trên Android/iOS cho 6 bài tập hiện tại. Trên Web hãy sử dụng đếm thủ công.';
    } else {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw StateError('Không tìm thấy camera.');
      final selected =
          cameras
              .where((x) => x.lensDirection == CameraLensDirection.front)
              .firstOrNull ??
          cameras.first;
      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted || _stopping) {
        await controller.dispose();
        return;
      }
      _camera = controller;
      _detector = PoseDetector(
        options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
      );
      await controller.startImageStream(_onFrame);
      _clock = Timer.periodic(const Duration(seconds: 1), _tick);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = 'Không khởi động được camera: $e');
    }
  }

  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };
  InputImage? _toInputImage(CameraImage frame) {
    final controller = _camera;
    if (controller == null || frame.planes.length != 1) return null;
    final camera = controller.description;
    final sensor = camera.sensorOrientation;
    final int degrees;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      degrees = sensor;
    } else {
      final orientation = _orientations[controller.value.deviceOrientation];
      if (orientation == null) return null;
      degrees = camera.lensDirection == CameraLensDirection.front
          ? (sensor + orientation) % 360
          : (sensor - orientation + 360) % 360;
    }
    final rotation = InputImageRotationValue.fromRawValue(degrees);
    final format = InputImageFormatValue.fromRawValue(frame.format.raw);
    if (rotation == null || format == null) return null;
    if (defaultTargetPlatform == TargetPlatform.android &&
        format != InputImageFormat.nv21) {
      return null;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        format != InputImageFormat.bgra8888) {
      return null;
    }
    return InputImage.fromBytes(
      bytes: frame.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(frame.width.toDouble(), frame.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: frame.planes.first.bytesPerRow,
      ),
    );
  }

  static const _joints = <Joint, PoseLandmarkType>{
    Joint.leftShoulder: PoseLandmarkType.leftShoulder,
    Joint.rightShoulder: PoseLandmarkType.rightShoulder,
    Joint.leftElbow: PoseLandmarkType.leftElbow,
    Joint.rightElbow: PoseLandmarkType.rightElbow,
    Joint.leftWrist: PoseLandmarkType.leftWrist,
    Joint.rightWrist: PoseLandmarkType.rightWrist,
    Joint.leftHip: PoseLandmarkType.leftHip,
    Joint.rightHip: PoseLandmarkType.rightHip,
    Joint.leftKnee: PoseLandmarkType.leftKnee,
    Joint.rightKnee: PoseLandmarkType.rightKnee,
    Joint.leftAnkle: PoseLandmarkType.leftAnkle,
    Joint.rightAnkle: PoseLandmarkType.rightAnkle,
  };

  Future<void> _onFrame(CameraImage frame) async {
    if (!mounted || _busy || _paused || _stage != _Stage.active || _stopping) {
      return;
    }
    final now = DateTime.now();
    if (_lastProcessed != null &&
        now.difference(_lastProcessed!).inMilliseconds < 140) {
      return;
    }
    _lastProcessed = now;
    _busy = true;
    try {
      final image = _toInputImage(frame);
      final detector = _detector;
      if (image == null || detector == null) return;
      final poses = await detector.processImage(image);
      if (!mounted || _stage != _Stage.active || _paused || _stopping) return;
      if (poses.isEmpty) {
        _counter.update(
          const PoseObservation(cue: 'Không phát hiện được người.'),
          now,
        );
        setState(() {
          _cue = 'Không phát hiện người — điều chỉnh vị trí camera.';
          _lastAligned = null;
          _alignedFrames = 0;
          _plankLocked = false;
        });
        return;
      }
      final p = poses.first;
      final skeleton = <Joint, JointPoint>{};
      for (final entry in _joints.entries) {
        final point = p.landmarks[entry.value];
        if (point != null) {
          skeleton[entry.key] = JointPoint(point.x, point.y, point.likelihood);
        }
      }
      final obs = observeExercise(_kind, skeleton);
      if (_plank) {
        if (obs.plankAligned) {
          _alignedFrames++;
          _plankLocked = _alignedFrames >= 3;
          _lastAligned = _plankLocked ? now : null;
        } else {
          _alignedFrames = 0;
          _plankLocked = false;
          _lastAligned = null;
        }
      } else {
        final counted = _counter.update(obs, now);
        if (counted && _counter.reps >= _target) _completeSet();
      }
      if (mounted) setState(() => _cue = obs.cue);
      _lastFrame = now;
    } catch (e) {
      if (mounted) setState(() => _cue = 'Không xử lý được khung hình: $e');
    } finally {
      _busy = false;
    }
  }

  void _tick(Timer timer) {
    if (!mounted || _stopping || _paused) return;
    setState(() {
      if (_stage == _Stage.rest) {
        if (--_rest <= 0) {
          _stage = _Stage.active;
          _set++;
          _hold = 0;
          _alignedFrames = 0;
          _plankLocked = false;
          _counter.reset();
          _cue = 'Sẵn sàng hiệp $_set';
        }
        return;
      }
      if (_stage == _Stage.done) return;
      _elapsed++;
      if (_plank &&
          _plankLocked &&
          _lastAligned != null &&
          _lastFrame != null &&
          DateTime.now().difference(_lastAligned!).inMilliseconds < 800 &&
          DateTime.now().difference(_lastFrame!).inMilliseconds < 800) {
        _hold++;
        if (_hold >= _target) _completeSet();
      }
    });
  }

  void _completeSet() {
    if (_stage != _Stage.active) return;
    final count = _plank ? 1 : _counter.reps;
    _completed.add(count);
    if (_plank) _plankTotal += _hold;
    _lastAligned = null;
    if (_set >= widget.sets) {
      _stage = _Stage.done;
      _clock?.cancel();
      _cue = 'Đã đủ ${widget.sets} hiệp. Chọn hoàn thành để đánh giá RPE.';
    } else {
      _stage = _Stage.rest;
      _rest = 30;
      _cue = 'Nghỉ 30 giây trước hiệp tiếp theo.';
    }
  }

  Future<void> _finish() async {
    if (_stage != _Stage.done || _stopping) return;
    _stopping = true;
    await _stopCamera();
    if (!mounted) return;
    Navigator.pop(
      context,
      CameraWorkoutResult(List.unmodifiable(_completed), _elapsed, _plankTotal),
    );
  }

  Future<void> _stopCamera() async {
    _clock?.cancel();
    final c = _camera;
    _camera = null;
    if (c != null) {
      try {
        if (c.value.isStreamingImages) await c.stopImageStream();
      } catch (_) {}
      try {
        await c.dispose();
      } catch (_) {}
    }
    final detector = _detector;
    _detector = null;
    if (detector != null) {
      try {
        await detector.close();
      } catch (_) {}
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) {
      setState(() => _paused = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    _stopCamera();
    super.dispose();
  }

  Future<void> _emergencyStop() async {
    if (_confirmingSafetyStop || _stopping || !mounted) return;
    // Stop processing camera frames and the rest/rep timer immediately.
    final wasPaused = _paused;
    setState(() {
      _confirmingSafetyStop = true;
      _paused = true;
    });

    bool confirmed = false;
    try {
      confirmed =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (c) => AlertDialog(
              title: const Text('Dừng vì dấu hiệu bất thường'),
              content: const Text(
                'Dừng ngay nếu có đau ngực, chóng mặt hoặc khó thở '
                'bất thường. Nếu cấp cứu, gọi 115 tại Việt Nam. '
                'Bạn muốn ghi nhận và dừng tập?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('Quay lại'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('Dừng tập'),
                ),
              ],
            ),
          ) ??
          false;
    } finally {
      if (mounted) {
        setState(() {
          _confirmingSafetyStop = false;
          if (!confirmed && !_stopping) _paused = wasPaused;
        });
      }
    }

    if (!confirmed || !mounted) return;
    setState(() {
      _stopping = true;
      _paused = true;
    });
    await _stopCamera();
    try {
      await HealthGuardianService.saveCheck(
        exerciseName: widget.exerciseName,
        phase: 'during',
        status: 'stopped',
        hasSymptoms: true,
      );
    } catch (e) {
      debugPrint('Cannot sync emergency stop: $e');
    }
    // No workout calories or completion after reporting symptoms.
    if (mounted) {
      Navigator.pop(
        context,
        const CameraWorkoutResult([], 0, 0, stoppedForSymptoms: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = _camera;
    return Scaffold(
      backgroundColor: const Color(0xFF080D19),
      appBar: AppBar(
        title: Text('AI Camera · ${widget.exerciseName}'),
        backgroundColor: const Color(0xFF0D1728),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) ...[
                  const Icon(
                    Icons.videocam_off_outlined,
                    size: 64,
                    color: Colors.orange,
                  ),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Quay về đếm thủ công'),
                  ),
                ] else if (camera == null || !camera.value.isInitialized)
                  const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  AspectRatio(
                    aspectRatio: camera.value.aspectRatio,
                    child: CameraPreview(camera),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Hiệp $_set/${widget.sets} · ${_stage == _Stage.rest
                      ? 'Nghỉ $_rest giây'
                      : _stage == _Stage.done
                      ? 'Hoàn thành'
                      : 'Đang tập'}',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _stage == _Stage.rest
                      ? '$_rest'
                      : _plank
                      ? '$_hold / $_target giây'
                      : '${_counter.reps} / $_target lần',
                  style: const TextStyle(
                    fontSize: 45,
                    color: Colors.cyan,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(_cue, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  'Hiệp đã xong: ${_completed.join(' • ')}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                if (_error == null && _stage != _Stage.done) ...[
                  OutlinedButton.icon(
                    onPressed: _confirmingSafetyStop || _stopping
                        ? null
                        : () => setState(() => _paused = !_paused),
                    icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                    label: Text(_paused ? 'Tiếp tục' : 'Tạm dừng'),
                  ),
                ],
                if (_stage == _Stage.done)
                  FilledButton.icon(
                    onPressed: _confirmingSafetyStop || _stopping
                        ? null
                        : _finish,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Hoàn thành · Đánh giá RPE'),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Đây là bộ đếm thử nghiệm dựa vào tư thế camera, không phải thiết bị y tế hoặc hệ thống phát hiện kiệt sức. Sai số phụ thuộc ánh sáng/góc camera. Không tự vượt mục tiêu để tăng calories.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16233A),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFF9D68).withValues(alpha: 0.38),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.health_and_safety_outlined,
                              color: Color(0xFFFFAD76), size: 19),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Báo dấu hiệu bất thường',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Dừng buổi tập và ghi nhận cảnh báo sức khỏe khi cần.',
                        style: TextStyle(color: Color(0xFF9FB5C9), fontSize: 12),
                      ),
                      const SizedBox(height: 11),
                      SizedBox(
                        height: 42,
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _confirmingSafetyStop || _stopping ? null : _emergencyStop,
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Dừng tập an toàn'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF493345),
                            foregroundColor: const Color(0xFFFFD5C3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
