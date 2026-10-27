import 'package:flutter/material.dart';

import '../../services/health_service.dart';
import '../../widgets/fittrack_motion.dart';
import 'health_design.dart';

class UpdateHealthScreen extends StatefulWidget {
  const UpdateHealthScreen({super.key});

  @override
  State<UpdateHealthScreen> createState() => _UpdateHealthScreenState();
}

class _UpdateHealthScreenState extends State<UpdateHealthScreen> {
  static const Color _cyan = Color(0xFF11BFF3);
  static const Color _purple = Color(0xFFA78BFA);
  static const Color _orange = Color(0xFFFFB15C);
  static const Color _rose = Color(0xFFFF7185);

  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _heartRateController;
  late final TextEditingController _sleepController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final data = HealthService.data;

    _heightController = TextEditingController(
      text: data.height.toStringAsFixed(0),
    );

    _weightController = TextEditingController(
      text: data.weight.toStringAsFixed(0),
    );

    _heartRateController = TextEditingController(
      text: data.heartRate.toString(),
    );

    _sleepController = TextEditingController(text: data.sleepHours.toString());
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _heartRateController.dispose();
    _sleepController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final height = double.tryParse(
      _heightController.text.trim().replaceAll(',', '.'),
    );

    final weight = double.tryParse(
      _weightController.text.trim().replaceAll(',', '.'),
    );

    final heartRate = int.tryParse(_heartRateController.text.trim());

    final sleep = double.tryParse(
      _sleepController.text.trim().replaceAll(',', '.'),
    );

    if (height == null ||
        weight == null ||
        heartRate == null ||
        sleep == null ||
        height <= 0 ||
        weight <= 0 ||
        heartRate < 0 ||
        sleep < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin hợp lệ.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await HealthService.updateHealth(
        height: height,
        weight: weight,
        heartRate: heartRate,
        sleepHours: sleep,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể lưu chỉ số sức khỏe. Vui lòng thử lại.'),
        ),
      );
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
          'Cập nhật sức khỏe',
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
                        eyebrow: 'BODY METRICS',
                        title: 'Hiểu cơ thể.\nChăm sóc bản thân.',
                        subtitle:
                            'Cập nhật các chỉ số để FITTRACK AI '
                            'theo dõi sức khỏe chính xác hơn.',
                        icon: Icons.favorite_rounded,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FitEntrance(
                      child: FitGlowCard(
                        accent: _purple,
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FitSectionTitle(
                              icon: Icons.monitor_weight_rounded,
                              title: 'Thông tin cơ thể',
                              subtitle: 'Các chỉ số đang theo dõi',
                              accent: _purple,
                            ),
                            const SizedBox(height: 24),
                            HealthInput(
                              title: 'Chiều cao',
                              unit: 'cm',
                              icon: Icons.height_rounded,
                              controller: _heightController,
                              accent: _cyan,
                              decimal: true,
                            ),
                            const SizedBox(height: 20),
                            HealthInput(
                              title: 'Cân nặng',
                              unit: 'kg',
                              icon: Icons.scale_outlined,
                              controller: _weightController,
                              accent: _orange,
                              decimal: true,
                            ),
                            const SizedBox(height: 20),
                            HealthInput(
                              title: 'Nhịp tim',
                              unit: 'bpm',
                              icon: Icons.favorite_border_rounded,
                              controller: _heartRateController,
                              accent: _rose,
                            ),
                            const SizedBox(height: 20),
                            HealthInput(
                              title: 'Giấc ngủ',
                              unit: 'giờ',
                              icon: Icons.bedtime_rounded,
                              controller: _sleepController,
                              accent: _purple,
                              decimal: true,
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
                          _isSaving
                              ? 'Đang lưu chỉ số...'
                              : 'Lưu chỉ số sức khỏe',
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
                        'Các chỉ số sau khi lưu sẽ được '
                        'cập nhật trên trang Sức khỏe.',
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
