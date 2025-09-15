import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:game_map_master_flutter_app/services/l10n/locale_service.dart';
import 'package:game_map_master_flutter_app/services/navigation_service.dart';
import 'package:game_map_master_flutter_app/widgets/websocket_initializer.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/common/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/host/host_dashboard_screen.dart';
import '../screens/gamer/game_lobby_screen.dart';
import 'config/app_config.dart';
import 'generated/l10n/app_localizations.dart';
import '../theme/global_theme.dart';

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  final navigationService = GetIt.instance<NavigationService>();
  final GoRouter _router = GetIt.I<GoRouter>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LocaleService>.value(
      value: GetIt.instance<LocaleService>(), // Récupère l'instance de GetIt
      child: WebSocketInitializer(
        child: Consumer<LocaleService>( // Utilise Consumer pour réagir aux changements de locale
          builder: (context, localeService, child) {
            return MaterialApp.router(
              title: AppLocalizations.of(context)?.appTitle ?? 'Game Map Master', // Utilise la chaîne localisée

              // Configuration i18n
              locale: localeService.currentLocale, // La locale actuelle du service
              localizationsDelegates: const [
                AppLocalizations.delegate, // Délégué généré
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppConfig.supportedLocales, // Locales supportées de votre config
              localeResolutionCallback: (locale, supportedLocales) {
                // Vérifie si la langue du système est supportée
                if (locale != null) {
                  for (var supportedLocale in supportedLocales) {
                    if (supportedLocale.languageCode == locale.languageCode) {
                      return supportedLocale;
                    }
                  }
                }
                // Retourne la langue par défaut si non supportée
                return AppConfig.fallbackLocale;
              },

              theme: GlobalMilitaryTheme.themeData,
              // Wrapper global pour fermer le clavier
              builder: (context, child) {
                return Listener(
                  // ✅ Écoute les changements de navigation
                  onPointerDown: (_) {
                    // Ferme le clavier sur tout tap/interaction
                    FocusScope.of(context).unfocus();
                  },
                  child: GestureDetector(
                    // ✅ Garde votre logique existante pour les zones vides
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      FocusScope.of(context).unfocus();
                    },
                    child: child,
                  ),
                );
              },
              routerConfig: _router, // Votre configuration GoRouter
            );
          },
        ),
      ),
    );
  }
}
