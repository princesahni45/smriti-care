// lib/core/localization/language_selector_sheet.dart
//
// Dementia-friendly language selector dialog and modal sheet.
//
// REQUIREMENTS SATISFIED:
// 1. English, Hindi, and Assamese options.
// 2. Large touch targets (> 64px height).
// 3. High contrast, readable typography without swipe gestures.
// 4. Clear selected-state checkmark indicator.
// 5. Offline persistence via LocaleController.
// 6. Immediate screen update without restarting or resetting patient session.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'app_locale_config.dart';
import 'locale_controller.dart';

class LanguageSelectorSheet extends StatelessWidget {
  final bool isCaregiverMode;
  final VoidCallback? onLanguageSelected;

  const LanguageSelectorSheet({
    super.key,
    this.isCaregiverMode = false,
    this.onLanguageSelected,
  });

  static Future<void> show(
    BuildContext context, {
    bool isCaregiverMode = false,
    VoidCallback? onLanguageSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LanguageSelectorSheet(
        isCaregiverMode: isCaregiverMode,
        onLanguageSelected: onLanguageSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = isCaregiverMode
        ? (l10n?.settings ?? 'Device Setup: Default Language')
        : (l10n?.language ?? 'Choose Language');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 28, color: AppColors.ink),
                  tooltip: l10n?.cancel ?? 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isCaregiverMode
                  ? 'Set the default language for patient interactions and voice guidance.'
                  : (l10n?.help ?? 'Tap your preferred language below.'),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 20),

            // Language Options (English, Hindi, Assamese)
            ListenableBuilder(
              listenable: LocaleController.instance,
              builder: (context, _) {
                final current = LocaleController.instance.currentLocale;
                return Column(
                  children: [
                    _LanguageOptionCard(
                      locale: AppLocaleConfig.english,
                      displayName: 'English',
                      nativeName: 'English',
                      isSelected: current.languageCode == 'en',
                      onTap: () => _selectLanguage(context, 'en'),
                    ),
                    const SizedBox(height: 12),
                    _LanguageOptionCard(
                      locale: AppLocaleConfig.hindi,
                      displayName: 'Hindi',
                      nativeName: 'हिन्दी',
                      isSelected: current.languageCode == 'hi',
                      onTap: () => _selectLanguage(context, 'hi'),
                    ),
                    const SizedBox(height: 12),
                    _LanguageOptionCard(
                      locale: AppLocaleConfig.assamese,
                      displayName: 'Assamese',
                      nativeName: 'অসমীয়া',
                      isSelected: current.languageCode == 'as',
                      onTap: () => _selectLanguage(context, 'as'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _selectLanguage(BuildContext context, String code) {
    LocaleController.instance.setLocaleByCode(code);
    onLanguageSelected?.call();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

class _LanguageOptionCard extends StatelessWidget {
  final Locale locale;
  final String displayName;
  final String nativeName;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOptionCard({
    required this.locale,
    required this.displayName,
    required this.nativeName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.tealLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.teal : AppColors.border,
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nativeName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.teal : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              )
            else
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
