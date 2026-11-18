import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';

class DeveloperPanelScreen extends ConsumerWidget {
  const DeveloperPanelScreen({super.key});

  Future<void> _openAdmin(BuildContext context, String rawBaseUrl) async {
    final base = Uri.tryParse(rawBaseUrl);
    const localHosts = {'localhost', '127.0.0.1', '10.0.2.2', '::1'};
    final localDebugHttp = kDebugMode &&
        base?.scheme == 'http' &&
        localHosts.contains(base?.host);
    if (base == null ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        (base.scheme != 'https' && !localDebugHttp)) {
      _showMessage(context, 'عنوان لوحة الإدارة غير آمن أو غير صالح.');
      return;
    }

    final adminUri = base.replace(path: '/admin', query: null, fragment: null);
    try {
      final opened = await launchUrl(
        adminUri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        _showMessage(context, 'تعذر فتح لوحة الإدارة.');
      }
    } catch (_) {
      if (context.mounted) _showMessage(context, 'تعذر فتح لوحة الإدارة.');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('لوحة المطوّر')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Icon(
              Icons.admin_panel_settings_rounded,
              size: 58,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'إدارة خزائن الهدى',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              'تُدار صلاحيات المطوّر والمحتوى والإعلانات والملفات في لوحة الخادم. '
              'تُتحقق كلمة المرور هناك فقط ولا تُخزّن داخل التطبيق.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _openAdmin(
                context,
                ref.read(apiProvider).options.baseUrl,
              ),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('فتح لوحة الإدارة الآمنة'),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'يلزم حساب إداري فعّال على الخادم. اسم المستخدم مُعبّأ باسم aliaa في صفحة الدخول؛ إنشاء حساب أو منحه صلاحيات لا يتم من التطبيق ولا يُستبدل بكلمة مرور محلية.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
