import 'package:flutter/material.dart';

import '../../services/health_guardian_service.dart';

class HealthGuardianProfileScreen extends StatefulWidget {
  const HealthGuardianProfileScreen({super.key});
  @override
  State<HealthGuardianProfileScreen> createState() =>
      _HealthGuardianProfileScreenState();
}

class _HealthGuardianProfileScreenState
    extends State<HealthGuardianProfileScreen> {
  static const _choices = <String>[
    'Bệnh tim mạch',
    'Vấn đề huyết áp',
    'Hô hấp / hen suyễn',
    'Tiểu đường',
    'Chấn thương / cơ xương khớp',
    'Tình trạng khác',
  ];
  final _notes = TextEditingController();
  final Set<String> _selected = {};
  bool? _hasCondition;
  bool _consent = false;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await HealthGuardianService.loadProfile();
      if (!mounted) return;
      setState(() {
        _hasCondition = data?.hasCondition;
        _selected.addAll(data?.conditionTypes ?? []);
        _notes.text = data?.notes ?? '';
        _busy = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '$e';
        });
      }
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_consent || _hasCondition == null) return;
    if (_hasCondition! && _selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hãy chọn ít nhất một nhóm tình trạng sức khỏe.'),
        ),
      );
      return;
    }
    // Không cho xóa khai báo bệnh lý hiện hữu chỉ bằng một lần chạm.
    final previous = await HealthGuardianService.loadProfile();
    if (!mounted) return;
    if (previous?.hasCondition == true && _hasCondition == false) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xác nhận thay đổi hồ sơ'),
          content: const Text(
            'Bạn đang thay đổi khai báo từ CÓ vấn đề sức khỏe thành KHÔNG. '
            'Chỉ thay đổi khi thông tin trước đây không còn chính xác. '
            'Việc này không thay thế đánh giá y tế.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xác nhận thay đổi'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await HealthGuardianService.saveProfile(
        GuardianHealthProfile(
          hasCondition: _hasCondition!,
          conditionTypes: _selected.toList(),
          notes: _notes.text,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lưu hồ sơ thất bại: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF080D19),
    appBar: AppBar(
      title: const Text('Hồ sơ an toàn sức khỏe'),
      backgroundColor: const Color(0xFF0D1728),
    ),
    body: _busy && _hasCondition == null && _error == null
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_error != null)
                    Text(
                      'Không tải được hồ sơ: $_error',
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                  const Text(
                    'Đây là thông tin sức khỏe tự khai báo nhằm hỗ trợ sàng lọc. '
                    'FITTRACK AI không thể tự xác nhận người có bệnh lý đủ điều kiện tập.',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Bạn có bệnh lý, chấn thương hoặc hạn chế sức khỏe ảnh hưởng vận động?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    children: [
                      ChoiceChip(
                        label: const Text('Có'),
                        selected: _hasCondition == true,
                        onSelected: _busy
                            ? null
                            : (_) => setState(() => _hasCondition = true),
                      ),
                      ChoiceChip(
                        label: const Text('Không'),
                        selected: _hasCondition == false,
                        onSelected: _busy
                            ? null
                            : (_) => setState(() => _hasCondition = false),
                      ),
                    ],
                  ),
                  if (_hasCondition == true) ...[
                    const SizedBox(height: 18),
                    const Text(
                      'Chọn nhóm liên quan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    for (final item in _choices)
                      CheckboxListTile(
                        title: Text(item),
                        value: _selected.contains(item),
                        onChanged: _busy
                            ? null
                            : (v) => setState(() {
                                if (v == true) {
                                  _selected.add(item);
                                } else {
                                  _selected.remove(item);
                                }
                              }),
                      ),
                    TextField(
                      controller: _notes,
                      maxLength: 300,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú (tùy chọn)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: _consent,
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _consent = v ?? false),
                    title: const Text(
                      'Tôi đồng ý lưu thông tin sức khỏe tự khai báo vào tài khoản '
                      'để hỗ trợ theo dõi an toàn luyện tập.',
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: _busy || _hasCondition == null || !_consent
                        ? null
                        : _save,
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text('Lưu hồ sơ sức khỏe'),
                    ),
                  ),
                ],
              ),
            ),
          ),
  );
}
