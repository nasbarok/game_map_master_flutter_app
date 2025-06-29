// lib/widgets/common/language_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../config/app_config.dart';
import '../../services/l10n/locale_service.dart';

class LanguageSelector extends StatelessWidget {
  final bool showAsDialog;

  const LanguageSelector({
    super.key,
    this.showAsDialog = false,
  });

  @override
  Widget build(BuildContext context) {
    final localeService = Provider.of<LocaleService>(context);
    final l10n = AppLocalizations.of(context)!;

    if (showAsDialog) {
      return IconButton(
        icon: Text(
          AppConfig.getLanguageFlag(localeService.currentLocale),
          style: const TextStyle(fontSize: 24),
        ),
        onPressed: () => _showLanguageDialog(context),
      );
    }

    return PopupMenuButton<Locale>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppConfig.getLanguageFlag(localeService.currentLocale),
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 4),
          Text(
            AppConfig.getLanguageName(localeService.currentLocale),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
      onSelected: (Locale locale) {
        localeService.setLocale(locale);
      },
      itemBuilder: (BuildContext context) {
        return AppConfig.supportedLocales.map((Locale locale) {
          return PopupMenuItem<Locale>(
            value: locale,
            child: Row(
              children: [
                Text(
                  AppConfig.getLanguageFlag(locale),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Text(AppConfig.getLanguageName(locale)),
                if (locale == localeService.currentLocale) ...[
                  const Spacer(),
                  const Icon(Icons.check, color: Colors.green),
                ],
              ],
            ),
          );
        }).toList();
      },
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.selectLanguage),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: AppConfig.supportedLocales.length,
              itemBuilder: (context, index) {
                final locale = AppConfig.supportedLocales[index];
                final localeService = Provider.of<LocaleService>(context);

                return ListTile(
                  leading: Text(
                    AppConfig.getLanguageFlag(locale),
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(AppConfig.getLanguageName(locale)),
                  trailing: locale == localeService.currentLocale
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    localeService.setLocale(locale);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        );
      },
    );
  }
}