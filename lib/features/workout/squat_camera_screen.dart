import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../services/squat_rep_counter.dart';

/// Android/iOS prototype. Open ONLY from an approved, active Workout session.
/// Returns detected rep count, never writes completion/calories directly.
class SquatCameraScreen extends StatefulWidget {
  final int sets;
  final int repsPerSet;
  const SquatCameraScreen({
    super.key,
    required this.sets,
    required this.repsPerSet,
  });

  @override
  State<SquatCameraScreen> createState() => _SquatCameraScreenState();
}

class _SquatCameraScreenState extends State<SquatCameraScreen> {
  CameraController? _camera;
  late SquatRepCounter _counter;
  final PoseDetector _detector = PoseDetector(
    options: PoseDetectorOptions(mode: PoseDetectionMode.single),
  );
  Timer? _ticker;
  bool _busy = false;
  bool _closing = false;
  String _status = 'Đang khởi tạo camera...';

  @override
  void initState() {
    super.initState();
    _counter = SquatRepCounter(totalSets: widget.sets, targetReps: widget.repsPerSet);
    _start();
  }

  Future<void> _start() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw StateError('Thiết bị không có camera.');
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(camera, ResolutionPreset.medium,
          enableAudio: false);
      await controller.initialize();
      if (!mounted || _closing) {
        await controller.dispose();
        return;
      }
      _camera = controller;
      setState(() => _status = 'Đứng đủ xa để thấy cả người, quay nghiêng khi squat.');
      // Single-image prototype. Efficient YUV streaming is a future optimization.
      _ticker = Timer.periodic(const Duration(milliseconds: 850), (_) {
        if (!mounted || _closing) return;
        if (_counter.resting) {
          setState(() {});
        } else if (!_counter.finished) {
          _readPose();
        }
      });
    } catch (e) {
      if (mounted) setState(() => _status = 'Không thể mở camera: $e');
    }
  }

  double? _angleForSide(Pose pose, bool left) {
    final pts = pose.landmarks;
    final hip = pts[left ? PoseLandmarkType.leftHip : PoseLandmarkType.rightHip];
    final knee = pts[left ? PoseLandmarkType.leftKnee : PoseLandmarkType.rightKnee];
    final ankle = pts[left ? PoseLandmarkType.leftAnkle : PoseLandmarkType.rightAnkle];
    if (hip == null || knee == null || ankle == null) return null;
    if (hip.likelihood < 0.55 || knee.likelihood < 0.55 || ankle.likelihood < 0.55) return null;
    return SquatRepCounter.jointAngle(
      hipX: hip.x, hipY: hip.y,
      kneeX: knee.x, kneeY: knee.y,
      ankleX: ankle.x, ankleY: ankle.y,
    );
  }

  Future<void> _readPose() async {
    if (_busy || _camera == null || !_camera!.value.isInitialized || _closing) return;
    _busy = true;
    String? temporaryPath;
    try {
      final image = await _camera!.takePicture();
      temporaryPath = image.path;
      final poses = await _detector.processImage(InputImage.fromFilePath(image.path));
      if (!mounted || _closing) return;
      if (poses.isEmpty) {
        setState(() => _status = 'Không thấy cơ thể. Đặt camera cách xa hơn.');
        return;
      }
      final pose = poses.first;
      final angle = _angleForSide(pose, true) ?? _angleForSide(pose, false);
      if (angle == null) {
        setState(() => _status = 'Không nhìn rõ hông, gối và cổ chân. Hãy quay nghiêng.');
        return;
      }
      final counted = _counter.observe(angle, DateTime.now());
      setState(() {
        _status = counted ? 'Đã ghi nhận 1 lần squat' :
            'Góc gối khoảng ${angle.toStringAsFixed(0)}°. Xuống rồi đứng thẳng để đếm.';
      });
    } catch (e) {
      if (mounted) setState(() => _status = 'Không xử lý được khung hình: $e');
    } finally {
      if (temporaryPath != null) {
        try { await File(temporaryPath).delete(); } catch (_) { /* Temp only */ }
      }
      _busy = false;
    }
  }

  @override
  void dispose() {
    _closing = true;
    _ticker?.cancel();
    _camera?.dispose();
    _detector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rest = _counter.restSecondsRemaining(DateTime.now());
    return Scaffold(
      appBar: AppBar(title: const Text('AI Camera — Squat (thử nghiệm)')),
      body: SafeArea(child: Column(children: [
        Expanded(child: _camera?.value.isInitialized == true
          ? CameraPreview(_camera!)
          : const Center(child: CircularProgressIndicator())),
        Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          Text('Hiệp ${_counter.currentSet}/${widget.sets}  •  ${_counter.repsInSet}/${widget.repsPerSet} lần',
            style: Theme.of(context).textTheme.titleLarge),
          Text('Tổng số lần nhận diện: ${_counter.totalReps}'),
          if (_counter.resting) Text('Nghỉ: $rest giây',
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 22)),
          if (_counter.finished) const Text('Đã đủ số hiệp!',
              style: TextStyle(color: Colors.greenAccent)),
          Text(_status, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _counter.finished
              ? () => Navigator.pop(context, _counter.totalReps)
              : null,
            child: const Text('Xác nhận số rep và quay lại buổi tập'),
          ),
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Hủy — không ghi nhận rep')),
        ])),
      ])),
    );
  }
}
