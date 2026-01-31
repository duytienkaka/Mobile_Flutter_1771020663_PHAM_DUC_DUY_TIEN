import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionTitle('Hiển thị'),
            Card(
              child: Consumer<ThemeProvider>(
                builder: (context, theme, _) {
                  return Column(
                    children: [
                      RadioListTile<ThemeMode>(
                        title: const Text('Theo hệ thống'),
                        value: ThemeMode.system,
                        groupValue: theme.themeMode,
                        onChanged: (mode) {
                          if (mode != null) theme.setThemeMode(mode);
                        },
                      ),
                      const Divider(height: 1),
                      RadioListTile<ThemeMode>(
                        title: const Text('Chế độ sáng'),
                        value: ThemeMode.light,
                        groupValue: theme.themeMode,
                        onChanged: (mode) {
                          if (mode != null) theme.setThemeMode(mode);
                        },
                      ),
                      const Divider(height: 1),
                      RadioListTile<ThemeMode>(
                        title: const Text('Chế độ tối'),
                        value: ThemeMode.dark,
                        groupValue: theme.themeMode,
                        onChanged: (mode) {
                          if (mode != null) theme.setThemeMode(mode);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            _SectionTitle('Tài khoản'),
            Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.notifications_outlined),
                    title: Text('Thông báo'),
                    subtitle: Text('Tạm thời hiển thị toàn bộ thông báo'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Đổi mật khẩu'),
                    subtitle: const Text('Yêu cầu nhập mật khẩu hiện tại'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                  const Divider(height: 1),
                  Consumer<LanguageProvider>(
                    builder: (context, lang, _) {
                      return Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.language_outlined),
                            title: const Text('Ngôn ngữ'),
                            subtitle: Text(lang.languageCode == 'vi' ? 'Tiếng Việt' : 'English'),
                          ),
                          RadioListTile<String>(
                            title: const Text('Tiếng Việt'),
                            value: 'vi',
                            groupValue: lang.languageCode,
                            onChanged: (code) {
                              if (code != null) lang.setLanguage(code);
                            },
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            title: const Text('English'),
                            value: 'en',
                            groupValue: lang.languageCode,
                            onChanged: (code) {
                              if (code != null) lang.setLanguage(code);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Bạn có thể thay đổi giao diện sáng/tối và các thiết lập khác trong tương lai.',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}

void _showChangePasswordDialog(BuildContext context) {
  final currentPasswordCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Đổi mật khẩu'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: currentPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu hiện tại';
                }
                return null;
              },
            ),
            TextFormField(
              controller: newPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu mới';
                }
                if (value.length < 6) {
                  return 'Mật khẩu mới phải có ít nhất 6 ký tự';
                }
                return null;
              },
            ),
            TextFormField(
              controller: confirmPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu mới'),
              validator: (value) {
                if (value != newPasswordCtrl.text) {
                  return 'Mật khẩu xác nhận không khớp';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final auth = Provider.of<AuthProvider>(context, listen: false);
            final success = await auth.changePassword(
              currentPasswordCtrl.text,
              newPasswordCtrl.text,
            );
            if (!context.mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? 'Đổi mật khẩu thành công' : 'Đổi mật khẩu thất bại'),
              ),
            );
          },
          child: const Text('Đổi mật khẩu'),
        ),
      ],
    ),
  );
}
