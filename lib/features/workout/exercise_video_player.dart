import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ExerciseVideoPanel extends StatefulWidget {
  final String exerciseName;

  const ExerciseVideoPanel({super.key, required this.exerciseName});

  @override
  State<ExerciseVideoPanel> createState() => _ExerciseVideoPanelState();
}

class _ExerciseVideoPanelState extends State<ExerciseVideoPanel> {
  static const Map<String, String> _videos = {
    'Squat': 'assets/videos/squat.mp4',
    'Push Up': 'assets/videos/push_up.mp4',
    'Lunge': 'assets/videos/lunge.mp4',
    'Plank': 'assets/videos/plank.mp4',
    'Jumping Jack': 'assets/videos/jumping_jack.mp4',
    'Shoulder Press': 'assets/videos/shoulder_press.mp4',
  };

  VideoPlayerController? _controller;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final path = _videos[widget.exerciseName];

    if (path == null) {
      setState(() {
        _error = 'Chưa có video cho bài tập này.';
      });
      return;
    }

    final controller = VideoPlayerController.asset(path);
    _controller = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _ready = true;
      });
    } catch (e, stackTrace) {
      debugPrint('VIDEO ERROR [${widget.exerciseName}]');
      debugPrint('VIDEO PATH: $path');
      debugPrint('VIDEO EXCEPTION: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _error = 'Không thể phát video: $e';
      });
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !_ready) return;

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102A40), Color(0xFF161C32), Color(0xFF291C43)],
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFF1EC8F4).withValues(alpha: 0.30),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C8FF).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.ondemand_video_rounded,
                color: Color(0xFF54E5FF),
                size: 22,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'VIDEO HƯỚNG DẪN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF54E5FF),
                size: 17,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ColoredBox(
                color: const Color(0xFF060D1A),
                child: _error != null
                    ? _buildPlaceholder(_error!)
                    : !_ready || controller == null
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF12C9F5),
                        ),
                      )
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _togglePlayback,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Center(
                              child: AspectRatio(
                                aspectRatio: controller.value.aspectRatio,
                                child: VideoPlayer(controller),
                              ),
                            ),
                            ValueListenableBuilder<VideoPlayerValue>(
                              valueListenable: controller,
                              builder: (context, value, child) {
                                return AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: value.isPlaying ? 0 : 1,
                                  child: Container(
                                    width: 67,
                                    height: 67,
                                    decoration: BoxDecoration(
                                      color: const Color(0xCC10354C),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF60E9FF),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 39,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          if (_ready && controller != null) ...[
            const SizedBox(height: 11),
            VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Color(0xFF12C9F5),
                bufferedColor: Color(0xFF31546D),
                backgroundColor: Color(0xFF273349),
              ),
            ),
            const SizedBox(height: 9),
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(value.position),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFA6BED0),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _togglePlayback,
                      icon: Icon(
                        value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 19,
                      ),
                      label: Text(value.isPlaying ? 'Tạm dừng' : 'Phát video'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF65E7FF),
                      ),
                    ),
                    Text(
                      _formatDuration(value.duration),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFA6BED0),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 9),
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: Color(0xFF8BAABF),
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Xem kỹ tư thế và thực hiện theo khả năng. '
                  'Video sẽ tự phát lại khi kết thúc.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9FB9CC),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.video_library_outlined,
              color: Color(0xFF55CFEF),
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFC5D8E6), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }
}
