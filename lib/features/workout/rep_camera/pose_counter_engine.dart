import 'dart:math' as math;

enum Joint {
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
}

class JointPoint {
  final double x, y, confidence;
  const JointPoint(this.x, this.y, [this.confidence = 1]);
}

typedef Skeleton = Map<Joint, JointPoint>;

enum ExerciseKind { squat, pushUp, lunge, plank, jumpingJack, shoulderPress }

ExerciseKind? exerciseKindFromName(String input) {
  final n = input.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  if (n.contains('squat')) return ExerciseKind.squat;
  if (n.contains('pushup')) return ExerciseKind.pushUp;
  if (n.contains('lunge')) return ExerciseKind.lunge;
  if (n.contains('plank')) return ExerciseKind.plank;
  if (n.contains('jumpingjack')) return ExerciseKind.jumpingJack;
  if (n.contains('shoulderpress')) return ExerciseKind.shoulderPress;
  return null;
}

double? jointAngle(JointPoint? a, JointPoint? b, JointPoint? c) {
  if (a == null ||
      b == null ||
      c == null ||
      a.confidence < .55 ||
      b.confidence < .55 ||
      c.confidence < .55) {
    return null;
  }
  final uX = a.x - b.x, uY = a.y - b.y;
  final vX = c.x - b.x, vY = c.y - b.y;
  final denom = math.sqrt((uX * uX + uY * uY) * (vX * vX + vY * vY));
  if (denom < 1e-8) return null;
  final cosine = ((uX * vX + uY * vY) / denom).clamp(-1.0, 1.0);
  return math.acos(cosine) * 180 / math.pi;
}

class PoseObservation {
  final bool? contracted;
  final bool? extended;
  final bool plankAligned;
  final double? metric;
  final String cue;
  const PoseObservation({
    this.contracted,
    this.extended,
    this.plankAligned = false,
    this.metric,
    required this.cue,
  });
}

bool _visible(Skeleton p, List<Joint> joints, {double minConfidence = .65}) =>
    joints.every((j) => p[j] != null && p[j]!.confidence >= minConfidence);

bool _bodyInFrame(Skeleton p, List<Joint> joints) {
  if (!_visible(p, joints)) return false;
  final values = joints.map((j) => p[j]!).toList();
  final xs = values.map((v) => v.x).toList();
  final ys = values.map((v) => v.y).toList();
  // Reject tiny skeletons: joint-angle estimates are unreliable at distance.
  return (xs.reduce(math.max) - xs.reduce(math.min) > 22 ||
          ys.reduce(math.max) - ys.reduce(math.min) > 90);
}

double? _bestAngle(Skeleton p, List<(Joint, Joint, Joint)> triples) {
  final found = <double>[];
  for (final (a, b, c) in triples) {
    final angle = jointAngle(p[a], p[b], p[c]);
    if (angle != null) found.add(angle);
  }
  if (found.isEmpty) return null;
  return found.reduce((a, b) => a + b) / found.length;
}

PoseObservation observeExercise(ExerciseKind kind, Skeleton p) {
  final elbows = _bestAngle(p, [
    (Joint.leftShoulder, Joint.leftElbow, Joint.leftWrist),
    (Joint.rightShoulder, Joint.rightElbow, Joint.rightWrist),
  ]);
  switch (kind) {
    case ExerciseKind.squat:
      final sides = <double>[];
      for (final triplet in [
        [Joint.leftShoulder, Joint.leftHip, Joint.leftKnee, Joint.leftAnkle],
        [Joint.rightShoulder, Joint.rightHip, Joint.rightKnee, Joint.rightAnkle],
      ]) {
        if (!_bodyInFrame(p, triplet)) continue;
        final angle = jointAngle(p[triplet[1]], p[triplet[2]], p[triplet[3]]);
        if (angle != null) sides.add(angle);
      }
      if (sides.isEmpty) {
        return const PoseObservation(cue: 'Chưa thấy đủ vai, hông, gối và cổ chân. Đặt máy xa hơn, đứng nghiêng và vào đủ khung hình.');
      }
      final knees = sides.reduce((a, b) => a + b) / sides.length;
      if (sides.length == 2 && (sides[0] - sides[1]).abs() > 32) {
        return const PoseObservation(cue: 'Khớp gối chưa ổn định, điều chỉnh góc camera.');
      }
      return PoseObservation(
        contracted: knees < 112,
        extended: knees > 158,
        metric: knees,
        cue: 'Squat: hạ hông xuống và đứng dậy; không gập người thay cho gập gối.',
      );
    case ExerciseKind.lunge:
      final lk = jointAngle(
        p[Joint.leftHip],
        p[Joint.leftKnee],
        p[Joint.leftAnkle],
      );
      final rk = jointAngle(
        p[Joint.rightHip],
        p[Joint.rightKnee],
        p[Joint.rightAnkle],
      );
      if (lk == null || rk == null ||
          !_bodyInFrame(p, [Joint.leftHip, Joint.leftKnee, Joint.leftAnkle, Joint.rightHip, Joint.rightKnee, Joint.rightAnkle])) {
        return const PoseObservation(
          cue: 'Đặt camera nghiêng để thấy cả hai đầu gối và chân.',
        );
      }
      return PoseObservation(
        contracted: math.min(lk, rk) < 112,
        extended: lk > 150 && rk > 150,
        metric: math.min(lk, rk),
        cue: 'Lunge: hạ đầu gối trước, rồi đứng thẳng lại.',
      );
    case ExerciseKind.pushUp:
      final torso = _bestAngle(p, [
        (Joint.leftShoulder, Joint.leftHip, Joint.leftAnkle),
        (Joint.rightShoulder, Joint.rightHip, Joint.rightAnkle),
      ]);
      if (elbows == null || torso == null || torso < 155 ||
          !_bodyInFrame(p, [Joint.leftShoulder, Joint.leftHip, Joint.leftAnkle, Joint.leftElbow, Joint.leftWrist]) &&
          !_bodyInFrame(p, [Joint.rightShoulder, Joint.rightHip, Joint.rightAnkle, Joint.rightElbow, Joint.rightWrist])) {
        return const PoseObservation(
          cue: 'Đặt camera ngang người; giữ thân thẳng, đủ tay trong hình.',
        );
      }
      return PoseObservation(
        contracted: elbows < 100,
        extended: elbows > 155,
        metric: elbows,
        cue: 'Push Up: hạ thấp và đẩy lên duỗi tay.',
      );
    case ExerciseKind.shoulderPress:
      final ls = p[Joint.leftShoulder], rs = p[Joint.rightShoulder];
      final lw = p[Joint.leftWrist], rw = p[Joint.rightWrist];
      if (elbows == null ||
          ls == null ||
          rs == null ||
          lw == null ||
          rw == null ||
          [ls, rs, lw, rw].any((v) => v.confidence < .55)) {
        return const PoseObservation(
          cue: 'Đưa cả hai tay, vai và đầu vào khung hình.',
        );
      }
      final wristsUp = lw.y < ls.y && rw.y < rs.y;
      return PoseObservation(
        contracted: elbows < 110,
        extended: elbows > 150 && wristsUp,
        metric: elbows,
        cue: 'Shoulder Press: đẩy tay lên rồi hạ về vai.',
      );
    case ExerciseKind.jumpingJack:
      final la = p[Joint.leftAnkle], ra = p[Joint.rightAnkle];
      final lh = p[Joint.leftHip], rh = p[Joint.rightHip];
      final ls = p[Joint.leftShoulder], rs = p[Joint.rightShoulder];
      final lw = p[Joint.leftWrist], rw = p[Joint.rightWrist];
      final pts = [la, ra, lh, rh, ls, rs, lw, rw];
      if (pts.any((v) => v == null || v.confidence < .55)) {
        return const PoseObservation(
          cue: 'Đứng xa hơn để thấy đủ tay và chân.',
        );
      }
      final hipWidth = (lh!.x - rh!.x).abs();

      if (hipWidth < 8) {
        return const PoseObservation(cue: 'Đứng đối diện camera.');
      }

      final ratio = (la!.x - ra!.x).abs() / hipWidth;

      final leftWrist = lw;
      final rightWrist = rw;

      final armsUp =
          leftWrist != null &&
          rightWrist != null &&
          leftWrist.y < ls!.y &&
          rightWrist.y < rs!.y;

      final armsDown =
          leftWrist != null &&
          rightWrist != null &&
          leftWrist.y > ls!.y &&
          rightWrist.y > rs!.y;
      return PoseObservation(
        contracted: ratio > 2.0 && armsUp,
        extended: ratio < 1.55 && armsDown,
        metric: ratio,
        cue: 'Jumping Jack: dang tay-chân, rồi khép về.',
      );
    case ExerciseKind.plank:
      final torso = _bestAngle(p, [
        (Joint.leftShoulder, Joint.leftHip, Joint.leftAnkle),
        (Joint.rightShoulder, Joint.rightHip, Joint.rightAnkle),
      ]);
      final aligned = torso != null && torso >= 160 && torso <= 180 &&
          (_bodyInFrame(p, [Joint.leftShoulder, Joint.leftHip, Joint.leftAnkle]) ||
           _bodyInFrame(p, [Joint.rightShoulder, Joint.rightHip, Joint.rightAnkle]));
      return PoseObservation(
        plankAligned: aligned,
        metric: torso,
        cue: aligned
            ? 'Giữ thân thẳng — đang tính thời gian.'
            : 'Plank: cần thấy vai, hông, cổ chân cùng một đường.',
      );
  }
}

/// Hysteresis, filtered metric, timed phases, and rearm after invalid poses.
/// This class never awards a rep based solely on a single noisy frame.
class RepDetector {
  final ExerciseKind exercise;
  int reps = 0;
  bool _armed = false;
  int _stableCount = 0;
  bool? _candidate;
  DateTime? _downAt;
  DateTime? _lastRep;
  DateTime? _lastValid;
  double? _filtered;
  RepDetector(this.exercise);

  bool update(PoseObservation pose, DateTime now) {
    if (exercise == ExerciseKind.plank) return false;
    if (pose.contracted == null && pose.extended == null) {
      _invalidate();
      return false;
    }
    // When landmarks disappear for too long, abandon unfinished movement.
    if (_lastValid != null && now.difference(_lastValid!).inMilliseconds > 700) {
      _invalidate();
    }
    _lastValid = now;
    if (pose.metric != null) {
      _filtered = _filtered == null
          ? pose.metric
          : (_filtered! * .55 + pose.metric! * .45);
    }
    bool? state;
    if (_filtered != null && pose.metric != null) {
      final value = _filtered!;
      switch (exercise) {
        case ExerciseKind.squat: state = value < 115 ? true : (value > 152 ? false : null); break;
        case ExerciseKind.lunge: state = value < 115 ? true : (value > 145 ? false : null); break;
        case ExerciseKind.pushUp: state = value < 105 ? true : (value > 150 ? false : null); break;
        case ExerciseKind.shoulderPress:
          state = value < 115 && pose.contracted == true ? true :
            (value > 145 && pose.extended == true ? false : null);
          break;
        case ExerciseKind.jumpingJack:
          state = value > 2.05 && pose.contracted == true ? true :
            (value < 1.6 && pose.extended == true ? false : null);
          break;
        case ExerciseKind.plank: return false;
      }
    } else {
      // Compatibility path for synthetic tests; production supplies metric.
      if (pose.contracted == true) state = true;
      if (pose.extended == true) state = false;
    }
    if (state == null) {
      _candidate = null;
      _stableCount = 0;
      return false;
    }
    _stableCount = _candidate == state ? _stableCount + 1 : 1;
    _candidate = state;
    if (_stableCount < 2) return false;
    if (state == true && !_armed) {
      _armed = true;
      _downAt = now;
      return false;
    }
    if (state == false && _armed) {
      final movementMs = now.difference(_downAt!).inMilliseconds;
      _armed = false;
      _downAt = null;
      if (movementMs >= 250 && movementMs <= 8000 &&
          (_lastRep == null || now.difference(_lastRep!).inMilliseconds >= 750)) {
        _lastRep = now;
        reps++;
        return true;
      }
    }
    return false;
  }

  void _invalidate() {
    _armed = false;
    _downAt = null;
    _candidate = null;
    _stableCount = 0;
    _filtered = null;
  }

  void reset() {
    reps = 0;
    _lastRep = null;
    _lastValid = null;
    _invalidate();
  }
}
