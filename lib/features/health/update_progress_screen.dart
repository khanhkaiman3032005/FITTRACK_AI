import 'package:flutter/material.dart';

import '../../services/health_service.dart';
import '../../services/daily_history_service.dart';
import '../../widgets/fittrack_motion.dart';
import 'health_design.dart';

class UpdateProgressScreen extends StatefulWidget {
  const UpdateProgressScreen({super.key});

  @override
  State<UpdateProgressScreen> createState() => _UpdateProgressScreenState();
}

class _UpdateProgressScreenState extends State<UpdateProgressScreen> {
  static const Color _cyan = Color(0xFF11BFF3);
  static const Color _mint = Color(0xFF2DD4BF);
  static const Color _purple = Color(0xFFA78BFA);

  late final TextEditingController _stepsController;
  late final TextEditingController _waterController;
  late final TextEditingController _activeMinutesController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final health = HealthService.data;

    _stepsController = TextEditingController(text: health.steps.toString());

    _waterController = TextEditingController(
      text: health.water.toStringAsFixed(1),
    );

    _activeMinutesController = TextEditingController(
      text: health.activeMinutes.toString(),
    );
  }

  @override
  void dispose() {
    _stepsController.dispose();
    _waterController.dispose();
    _activeMinutesController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF9F2944),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final steps = int.tryParse(_stepsController.text.trim());

    final water = double.tryParse(
      _waterController.text.trim().replaceAll(',', '.'),
    );

    final activeMinutes = int.tryParse(_activeMinutesController.text.trim());

    if (steps == null || steps < 0) {
      _showError('Bước chân không hợp lệ');
      return;
    }

    if (water == null || water < 0) {
      _showError('Lượng nước không hợp lệ');
      return;
    }

    if (activeMinutes == null || activeMinutes < 0) {
      _showError('Thời gian vận động không hợp lệ');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await HealthService.updateProgress(
        steps: steps,
        water: water,
        activeMinutes: activeMinutes,
      );

      await DailyHistoryService.saveTodaySnapshot();

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showError('Không thể lưu tiến độ. Vui lòng thử lại.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1728),
        title: const Text(
          'Cập nhật tiến độ',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: HealthBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 38),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FitEntrance(
                      child: HealthHero(
                        eyebrow: 'DAILY ACTIVITY',
                        title: 'Cập nhật hành trình\nhôm nay của bạn.',
                        subtitle:
                            'Ghi nhận bước chân, nước uống '
                            'và thời gian vận động.',
                        icon: Icons.insights_rounded,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FitEntrance(
                      child: FitGlowCard(
                        accent: _cyan,
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FitSectionTitle(
                              icon: Icons.edit_note_rounded,
                              title: 'Chỉ số hôm nay',
                              subtitle: 'Nhập giá trị đã ghi nhận',
                              accent: _cyan,
                            ),
                            const SizedBox(height: 24),
                            HealthInput(
                              title: 'Bước chân',
                              unit: 'bước',
                              icon: Icons.directions_walk_rounded,
                              controller: _stepsController,
                              accent: _mint,
                            ),
                            const SizedBox(height: 20),
                            HealthInput(
                              title: 'Nước uống',
                              unit: 'L',
                              icon: Icons.water_drop_outlined,
                              controller: _waterController,
                              accent: _cyan,
                              decimal: true,
                            ),
                            const SizedBox(height: 20),
                            HealthInput(
                              title: 'Thời gian vận động',
                              unit: 'phút',
                              icon: Icons.timer_outlined,
                              controller: _activeMinutesController,
                              accent: _purple,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: Text(
                          _isSaving ? 'Đang lưu tiến độ...' : 'Lưu tiến độ',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _cyan,
                          foregroundColor: const Color(0xFF071523),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Center(
                      child: Text(
                        'Dữ liệu sẽ được cập nhật vào '
                        'nhật ký sức khỏe hôm nay.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
