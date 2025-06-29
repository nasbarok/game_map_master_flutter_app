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
class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  final navigationService = GetIt.instance<NavigationService>();

  @override
  Widget build(BuildContext context) {
    final navigatorKey = navigationService.navigatorKey;

    final router = GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/host',
          builder: (context, state) => const HostDashboardScreen(),
        ),
        GoRoute(
          path: '/gamer/lobby',
          builder: (context, state) {
            final refresh = state.queryParameters['refresh'];
            return GameLobbyScreen(key: ValueKey(refresh));
          },
        ),
      ],
      redirect: (context, state) {
       final authService = GetIt.I<AuthService>();
        final isLoggedIn = authService.isLoggedIn;
        final isLoggingIn = state.location == '/login' || state.location == '/register';
        final isSplash = state.location == '/splash';

       // ⚠️ NE RIEN FAIRE tant qu’on est sur le splash (il gère tout)
        if (isSplash) return null;

       // ➕ Empêche accès aux autres pages sans session
        if (!isLoggedIn && !isLoggingIn) return '/login';

       // ➕ Empêche retour à login/register après authentification
        if (isLoggedIn && isLoggingIn) {
          final user = authService.currentUser;
          if (user != null) {
            return user.hasRole('HOST') ? '/host' : '/gamer/lobby';
          }
        }
        return null;
      },
    );

    return ChangeNotifierProvider<LocaleService>.value(
      value: GetIt.instance<LocaleService>(), // Récupère l'instance de GetIt
      child: WebSocketInitializer(
        child: Consumer<LocaleService>( // Utilise Consumer pour réagir aux changements de locale
          builder: (context, localeService, child) {
            return MaterialApp.router(
              title: AppLocalizations.of(context)?.appTitle ?? 'Airsoft Game Master', // Utilise la chaîne localisée

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

              theme: ThemeData(
                primarySwatch: Colors.blue,
                visualDensity: VisualDensity.adaptivePlatformDensity,
                useMaterial3: true,
              ),
              routerConfig: router, // Votre configuration GoRouter
            );
          },
        ),
      ),
    );
  }
}
