import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_dimens.dart';

/// Geçici ana ekran.
///
/// !!! PLACEHOLDER !!! Figma prototipindeki gerçek ekranlarla değişecek.
/// İskeletin ayakta olduğunu doğrulamak için duruyor.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppConfig.appName)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          children: [
            Text('İskelet hazır', style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Riverpod, go_router, tema ve ağ katmanı kurulu. '
              'Ekranlar Figma tasarımından üretilecek.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tema kontrolü', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(onPressed: () {}, child: const Text('Birincil buton')),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(onPressed: () {}, child: const Text('İkincil buton')),
                    const SizedBox(height: AppSpacing.md),
                    const TextField(
                      decoration: InputDecoration(hintText: 'Örnek alan'),
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
