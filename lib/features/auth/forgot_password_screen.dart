import 'package:flutter/material.dart';

import '../../widgets/fittrack_auth_design.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendRequest() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Chức năng gửi email khôi phục đang được hoàn thiện. '
          'Hiện chưa có email nào được gửi.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070D18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1B2E),
        title: const Text(
          'Khôi phục tài khoản',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: FitAuthBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 25, 18, 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 510),
                child: FitAuthAppearance(
                  child: FitAuthCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF087D9D), Color(0xFF4A3588)],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: FitAuthColors.cyan.withValues(
                                    alpha: 0.20,
                                  ),
                                  blurRadius: 23,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              color: Colors.white,
                              size: 39,
                            ),
                          ),
                          const SizedBox(height: 26),
                          const Text(
                            'Quên mật khẩu?',
                            style: TextStyle(
                              fontSize: 29,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 11),
                          const Text(
                            'Nhập email đã đăng ký để yêu cầu '
                            'khôi phục quyền truy cập tài khoản.',
                            style: TextStyle(
                              color: FitAuthColors.muted,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Email tài khoản',
                              hintText: 'example@gmail.com',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập email';
                              }
                              final regex = RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              );
                              if (!regex.hasMatch(value.trim())) {
                                return 'Email không hợp lệ';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          FitAuthButton(
                            label: 'Yêu cầu khôi phục',
                            icon: Icons.mark_email_read_outlined,
                            onPressed: _sendRequest,
                          ),
                          const SizedBox(height: 17),
                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Quay lại đăng nhập'),
                            ),
                          ),
                          const SizedBox(height: 17),
                          const Divider(color: Color(0xFF334357)),
                          const SizedBox(height: 13),
                          const Text(
                            'Bảo mật tài khoản là ưu tiên '
                            'của FITTRACK AI.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: FitAuthColors.muted,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
