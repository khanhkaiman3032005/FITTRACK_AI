import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/profile_service.dart';
import '../../services/health_service.dart';
import '../../services/auth_service.dart';
import '../../core/routes/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _cyan = Color(0xFF12C9F5);
  static const Color _purple = Color(0xFFA78BFA);
  static const Color _mint = Color(0xFF2DD4BF);
  static const Color _orange = Color(0xFFFFB15C);
  static const Color _muted = Color(0xFFA6BED0);

  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _targetWeightController;
  late final TextEditingController _stepGoalController;
  late final TextEditingController _waterGoalController;
  late final TextEditingController _calorieGoalController;
  late final TextEditingController _activeMinutesGoalController;

  String _gender = 'Nam';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final profile = ProfileService.profile;

    _nameController = TextEditingController(text: profile.name);
    _ageController = TextEditingController(text: profile.age.toString());
    _heightController = TextEditingController(
      text: profile.height.toStringAsFixed(0),
    );
    _weightController = TextEditingController(
      text: profile.weight.toStringAsFixed(1),
    );
    _targetWeightController = TextEditingController(
      text: profile.targetWeight.toStringAsFixed(1),
    );
    _stepGoalController = TextEditingController(
      text: profile.dailyStepGoal.toString(),
    );
    _waterGoalController = TextEditingController(
      text: profile.dailyWaterGoal.toStringAsFixed(1),
    );
    _calorieGoalController = TextEditingController(
      text: profile.dailyCalorieGoal.toString(),
    );
    _activeMinutesGoalController = TextEditingController(
      text: profile.dailyActiveMinutesGoal.toString(),
    );

    _gender = profile.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _stepGoalController.dispose();
    _waterGoalController.dispose();
    _calorieGoalController.dispose();
    _activeMinutesGoalController.dispose();
    super.dispose();
  }

  double get _previewBmi {
    final height =
        double.tryParse(_heightController.text.replaceAll(',', '.')) ?? 0;
    final weight =
        double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0;

    if (height <= 0 || weight <= 0) return 0;

    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text);
    final height = double.tryParse(_heightController.text.replaceAll(',', '.'));
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final targetWeight = double.tryParse(
      _targetWeightController.text.replaceAll(',', '.'),
    );
    final stepGoal = int.tryParse(_stepGoalController.text);
    final waterGoal = double.tryParse(
      _waterGoalController.text.replaceAll(',', '.'),
    );
    final calorieGoal = int.tryParse(_calorieGoalController.text);
    final activeMinutesGoal = int.tryParse(_activeMinutesGoalController.text);

    if (name.isEmpty ||
        age == null ||
        age <= 0 ||
        height == null ||
        height <= 0 ||
        weight == null ||
        weight <= 0 ||
        targetWeight == null ||
        targetWeight <= 0 ||
        stepGoal == null ||
        stepGoal <= 0 ||
        waterGoal == null ||
        waterGoal <= 0 ||
        calorieGoal == null ||
        calorieGoal <= 0 ||
        activeMinutesGoal == null ||
        activeMinutesGoal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ và đúng thông tin.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final profile = UserProfile(
        name: name,
        age: age,
        gender: _gender,
        height: height,
        weight: weight,
        targetWeight: targetWeight,
        dailyStepGoal: stepGoal,
        dailyWaterGoal: waterGoal,
        dailyCalorieGoal: calorieGoal,
        dailyActiveMinutesGoal: activeMinutesGoal,
      );

      await ProfileService.saveProfile(profile);

      await HealthService.updateHealth(
        height: height,
        weight: weight,
        heartRate: HealthService.data.heartRate,
        sleepHours: HealthService.data.sleepHours,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu hồ sơ thành công.')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể lưu đầy đủ hồ sơ. Vui lòng kiểm tra lại.'),
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

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF17233A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Đăng xuất',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi FITTRACK AI?',
            style: TextStyle(color: Color(0xFFCBD5E1)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: _cyan,
                foregroundColor: const Color(0xFF020617),
              ),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    try {
      await AuthService.signOut();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể đăng xuất. Vui lòng thử lại.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1B2E),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hồ sơ cá nhân',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            Text(
              'Thông tin và mục tiêu của bạn',
              style: TextStyle(fontSize: 11, color: _muted),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 17),
            child: Icon(Icons.verified_user_rounded, color: _cyan),
          ),
        ],
      ),
      body: _ProfileBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 850;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  desktop ? 32 : 17,
                  23,
                  desktop ? 32 : 17,
                  45,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileEntrance(child: _buildHero()),
                        const SizedBox(height: 25),
                        _buildSummary(),
                        const SizedBox(height: 32),
                        if (desktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildPersonalSection()),
                              const SizedBox(width: 18),
                              Expanded(child: _buildBodySection()),
                            ],
                          )
                        else ...[
                          _buildPersonalSection(),
                          const SizedBox(height: 25),
                          _buildBodySection(),
                        ],
                        const SizedBox(height: 28),
                        _buildGoalsSection(),
                        const SizedBox(height: 30),
                        _buildActions(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    final name = _nameController.text.trim();
    final displayName = name.isEmpty ? 'Thành viên FITTRACK' : name;
    final initial = name.isEmpty ? 'F' : name.substring(0, 1).toUpperCase();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 580;

        return Container(
          padding: EdgeInsets.all(compact ? 20 : 30),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF115066), Color(0xFF17304D), Color(0xFF30204E)],
            ),
            borderRadius: BorderRadius.circular(27),
            border: Border.all(color: _cyan.withValues(alpha: 0.34)),
            boxShadow: [
              BoxShadow(
                color: _cyan.withValues(alpha: 0.09),
                blurRadius: 30,
                offset: const Offset(0, 11),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF83E9FF),
                    size: 15,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'YOUR FITNESS IDENTITY',
                    style: TextStyle(
                      color: Color(0xFF83E9FF),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Container(
                    width: compact ? 65 : 82,
                    height: compact ? 65 : 82,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF17C6F3), Color(0xFF7659D7)],
                      ),
                      borderRadius: BorderRadius.circular(compact ? 21 : 26),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.50),
                        width: 1.3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _cyan.withValues(alpha: 0.24),
                          blurRadius: 25,
                        ),
                      ],
                    ),
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 31 : 38,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 17),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 20 : 27,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Thành viên FITTRACK AI',
                          style: TextStyle(
                            color: Color(0xFFC2D6E7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 9),
                        const Row(
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              color: _mint,
                              size: 15,
                            ),
                            SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Hồ sơ sức khỏe cá nhân',
                                style: TextStyle(
                                  color: Color(0xFF92EADA),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFF75E4FA),
                      size: 19,
                    ),
                    SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Mỗi ngày một bước tiến tốt hơn '
                        'cho sức khỏe của bạn.',
                        style: TextStyle(
                          color: Color(0xFFCFDEEA),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummary() {
    final bmi = _previewBmi;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 850
            ? 3
            : width >= 340
            ? 2
            : 1;
        final itemWidth = (width - (columns - 1) * 12) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: _summaryCard(
                icon: Icons.monitor_weight_rounded,
                title: 'BMI hiện tại',
                value: bmi <= 0 ? '--' : bmi.toStringAsFixed(1),
                subtitle: _bmiStatus(bmi),
                color: _purple,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _summaryCard(
                icon: Icons.flag_rounded,
                title: 'Cân nặng mục tiêu',
                value: '${_targetWeightController.text} kg',
                subtitle: 'Mục tiêu cá nhân',
                color: _orange,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _summaryCard(
                icon: Icons.directions_walk_rounded,
                title: 'Bước chân mục tiêu',
                value: _stepGoalController.text,
                subtitle: 'Bước mỗi ngày',
                color: _mint,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return _ProfileGlowCard(
      accent: color,
      child: SizedBox(
        height: 126,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(color: _muted, fontSize: 11)),
            const SizedBox(height: 5),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: Text(
                value,
                key: ValueKey('$title-$value'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalSection() {
    return _ProfileEntrance(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            Icons.badge_outlined,
            'Thông tin cá nhân',
            'Thông tin cơ bản của tài khoản',
            _cyan,
          ),
          const SizedBox(height: 16),
          _ProfileGlowCard(
            accent: _cyan,
            child: Column(
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Họ và tên',
                  icon: Icons.person_outline_rounded,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 18),
                _buildTextField(
                  controller: _ageController,
                  label: 'Tuổi',
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 18),
                _buildGenderField(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodySection() {
    return _ProfileEntrance(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            Icons.monitor_heart_outlined,
            'Chỉ số cơ thể',
            'Theo dõi các chỉ số sức khỏe',
            _purple,
          ),
          const SizedBox(height: 16),
          _ProfileGlowCard(
            accent: _purple,
            child: Column(
              children: [
                _buildTextField(
                  controller: _heightController,
                  label: 'Chiều cao',
                  suffix: 'cm',
                  icon: Icons.height_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 18),
                _buildTextField(
                  controller: _weightController,
                  label: 'Cân nặng',
                  suffix: 'kg',
                  icon: Icons.scale_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                _buildBmiCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSection() {
    return _ProfileEntrance(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            Icons.track_changes_rounded,
            'Mục tiêu cá nhân',
            'Thiết lập chỉ tiêu luyện tập và dinh dưỡng',
            _mint,
          ),
          const SizedBox(height: 16),
          _ProfileGlowCard(
            accent: _mint,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = width >= 680 ? 2 : 1;
                final itemWidth = (width - (columns - 1) * 16) / columns;

                Widget field(
                  TextEditingController controller,
                  String label,
                  String suffix,
                  IconData icon, {
                  bool decimal = false,
                  bool refresh = false,
                }) {
                  return SizedBox(
                    width: itemWidth,
                    child: _buildTextField(
                      controller: controller,
                      label: label,
                      suffix: suffix,
                      icon: icon,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: decimal,
                      ),
                      onChanged: refresh ? (_) => setState(() {}) : null,
                    ),
                  );
                }

                return Wrap(
                  spacing: 16,
                  runSpacing: 19,
                  children: [
                    field(
                      _targetWeightController,
                      'Cân nặng mục tiêu',
                      'kg',
                      Icons.flag_rounded,
                      decimal: true,
                      refresh: true,
                    ),
                    field(
                      _stepGoalController,
                      'Mục tiêu bước chân',
                      'bước/ngày',
                      Icons.directions_walk_rounded,
                      refresh: true,
                    ),
                    field(
                      _waterGoalController,
                      'Mục tiêu uống nước',
                      'L/ngày',
                      Icons.water_drop_outlined,
                      decimal: true,
                    ),
                    field(
                      _calorieGoalController,
                      'Mục tiêu calories',
                      'kcal/ngày',
                      Icons.local_fire_department_rounded,
                    ),
                    field(
                      _activeMinutesGoalController,
                      'Mục tiêu vận động',
                      'phút/ngày',
                      Icons.timer_outlined,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return _ProfileEntrance(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF112338),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cyan.withValues(alpha: 0.16)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: _cyan, size: 22),
                SizedBox(width: 13),
                Expanded(
                  child: Text(
                    'Các mục tiêu cá nhân sẽ được sử dụng '
                    'trong Dashboard, Dinh dưỡng, Sức khỏe '
                    'và trợ lý AI.',
                    style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 55,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _isSaving ? 'Đang lưu hồ sơ...' : 'Lưu thay đổi',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
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
          SizedBox(
            height: 53,
            child: OutlinedButton.icon(
              onPressed: _isSaving ? null : _logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'Đăng xuất tài khoản',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF8796),
                side: const BorderSide(color: Color(0xFFB74A65)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Center(
            child: Text(
              'FITTRACK AI • PERSONAL FITNESS PLATFORM',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF70869D),
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    IconData icon,
    String title,
    String subtitle,
    Color accent,
  ) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? suffix,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted),
        prefixIcon: Icon(icon, color: _cyan),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: _muted, fontSize: 11),
        filled: true,
        fillColor: const Color(0xFF0D1C30),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: _cyan.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _cyan, width: 1.6),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _buildGenderField() {
    return DropdownButtonFormField<String>(
      initialValue: _gender,
      dropdownColor: const Color(0xFF17243C),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Giới tính',
        labelStyle: const TextStyle(color: _muted),
        prefixIcon: const Icon(Icons.wc_rounded, color: _cyan),
        filled: true,
        fillColor: const Color(0xFF0D1C30),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: _cyan.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _cyan),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'Nam', child: Text('Nam')),
        DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
        DropdownMenuItem(value: 'Khác', child: Text('Khác')),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _gender = value;
        });
      },
    );
  }

  String _bmiStatus(double bmi) {
    if (bmi <= 0) return 'Chưa có dữ liệu';
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 25) return 'Bình thường';
    if (bmi < 30) return 'Thừa cân';
    return 'Béo phì';
  }

  Widget _buildBmiCard() {
    final bmi = _previewBmi;
    final status = _bmiStatus(bmi);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF104457), Color(0xFF252044)],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _cyan.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            height: 49,
            width: 49,
            decoration: BoxDecoration(
              color: _cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.monitor_heart_rounded,
              color: _cyan,
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BMI dự kiến',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
                const SizedBox(height: 5),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    bmi <= 0 ? '--' : bmi.toStringAsFixed(1),
                    key: ValueKey(bmi.toStringAsFixed(1)),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Text(
              status,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: _cyan,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileEntrance extends StatelessWidget {
  final Widget child;

  const _ProfileEntrance({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 17 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _ProfileGlowCard extends StatefulWidget {
  final Widget child;
  final Color accent;

  const _ProfileGlowCard({required this.child, required this.accent});

  @override
  State<_ProfileGlowCard> createState() => _ProfileGlowCardState();
}

class _ProfileGlowCardState extends State<_ProfileGlowCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF141F33),
              Color.lerp(
                const Color(0xFF1E1C36),
                widget.accent.withValues(alpha: 0.24),
                _hovered ? 0.65 : 0.32,
              )!,
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: widget.accent.withValues(alpha: _hovered ? 0.52 : 0.20),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.accent.withValues(alpha: _hovered ? 0.13 : 0.04),
              blurRadius: _hovered ? 27 : 13,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

class _ProfileBackdrop extends StatefulWidget {
  final Widget child;

  const _ProfileBackdrop({required this.child});

  @override
  State<_ProfileBackdrop> createState() => _ProfileBackdropState();
}

class _ProfileBackdropState extends State<_ProfileBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();

    _animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final t = _animation.value;

        return Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF081D2D),
                      Color(0xFF090F20),
                      Color(0xFF201333),
                      Color(0xFF080D19),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -150 + t * 55,
              right: -130 + t * 35,
              child: const IgnorePointer(
                child: _ProfileGlow(size: 380, color: Color(0x3000C8F8)),
              ),
            ),
            Positioned(
              bottom: -160 + t * 45,
              left: -140 + t * 50,
              child: const IgnorePointer(
                child: _ProfileGlow(size: 420, color: Color(0x2D9770F8)),
              ),
            ),
            Positioned.fill(child: child!),
          ],
        );
      },
    );
  }
}

class _ProfileGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _ProfileGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}
