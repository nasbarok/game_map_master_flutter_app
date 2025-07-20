import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import 'package:go_router/go_router.dart';

import '../../theme/global_theme.dart';
import '../../theme/themed_text_form_field.dart';
import '../../widgets/adaptive_background.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  bool _isPasswordVisible = false;
  String? _selectedRole;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final authService = GetIt.I<AuthService>();
      final success = await authService.register(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
        _firstNameController.text,
        _lastNameController.text,
        _phoneNumberController.text,
        _selectedRole!,
      );

      final l10n = AppLocalizations.of(context)!;
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.registrationSuccess),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/login');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.registrationFailure),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = GetIt.I<AuthService>();
    final l10n = AppLocalizations.of(context)!;

    return AdaptiveScaffold(
      gameBackgroundType: GameBackgroundType.home,
      enableParallax: true,
      backgroundOpacity: 0.85,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 🎨 BANNER AVEC PERSONNAGE + TEXTE
                    Container(
                      height: 120,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: const BoxDecoration(
                            // 🎨 Background de base
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                GlobalMilitaryTheme.darkMetal,
                                GlobalMilitaryTheme.primaryMetal,
                                GlobalMilitaryTheme.darkMetal,
                              ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              // 🎨 OVERLAY POUR AMÉLIORER LA LISIBILITÉ
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.black.withOpacity(0.2),
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.4),
                                    ],
                                  ),
                                ),
                              ),

                              // 👤 VOTRE PERSONNAGE À GAUCHE
                              Positioned(
                                left: 20,
                                top: 10,
                                bottom: 10,
                                child: Container(
                                  width: 100, // Largeur du personnage
                                  child: Image.asset(
                                    'assets/images/theme/register_character.png',
                                    fit: BoxFit.contain,
                                    // Garde les proportions
                                    alignment: Alignment.centerLeft,
                                    errorBuilder: (context, error, stackTrace) {
                                      // 🎨 Fallback si l'image ne charge pas
                                      return Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: GlobalMilitaryTheme.accentGreen
                                              .withOpacity(0.3),
                                          border: Border.all(
                                            color:
                                                GlobalMilitaryTheme.accentGreen,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          size: 40,
                                          color: GlobalMilitaryTheme.textLight,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              // 📝 TEXTE À DROITE
                              Positioned(
                                right: 20,
                                top: 16,
                                bottom: 16,
                                left: 140,
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // TITRE
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final baseFontSize =
                                              constraints.maxWidth < 180
                                                  ? 16.0
                                                  : 20.0;
                                          final lengthFactor =
                                              (l10n.recruitmentTitle.length /
                                                      12)
                                                  .clamp(1.0, 1.5);
                                          return Text(
                                            l10n.recruitmentTitle,
                                            style: TextStyle(
                                              fontSize:
                                                  baseFontSize / lengthFactor,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 1.2,
                                              shadows: const [
                                                Shadow(
                                                  color: Colors.black,
                                                  blurRadius: 6,
                                                  offset: Offset(2, 2),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 8),

                                      // SOUS-TITRE EN ITALIQUE
                                      SizedBox(
                                        width: double.infinity,
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            final subtitleFontSize = (l10n
                                                        .recruitmentSubtitle
                                                        .length >
                                                    110)
                                                ? 10.0
                                                : 11.5;

                                            return Text(
                                              l10n.recruitmentSubtitle,
                                              textAlign: TextAlign.right,
                                              softWrap: true,
                                              style: TextStyle(
                                                fontSize: subtitleFontSize,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                                height: 1.3,
                                                shadows: const [
                                                  Shadow(
                                                    color: Colors.black,
                                                    blurRadius: 4,
                                                    offset: Offset(1, 1),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 🎨 TITRE PRINCIPAL (même style que LoginScreen)
                    Text(
                      l10n.createAccount,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 🎨 CHAMPS AVEC ThemedTextFormField
                    ThemedTextFormField(
                      controller: _usernameController,
                      label: l10n.usernameLabel,
                      prefixIcon: const Icon(Icons.person,
                          color: GlobalMilitaryTheme.lightMetal),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.usernamePrompt;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    ThemedTextFormField(
                      controller: _emailController,
                      label: l10n.emailLabel,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email,
                          color: GlobalMilitaryTheme.lightMetal),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.emailPrompt;
                        }
                        if (!value.contains('@')) {
                          return l10n.emailInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    ThemedTextFormField(
                      controller: _passwordController,
                      label: l10n.passwordLabel,
                      obscureText: !_isPasswordVisible,
                      prefixIcon: const Icon(Icons.lock,
                          color: GlobalMilitaryTheme.lightMetal),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: GlobalMilitaryTheme.lightMetal,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.passwordPrompt;
                        }
                        if (value.length < 6) {
                          return l10n.passwordTooShort;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    ThemedTextFormField(
                      controller: _confirmPasswordController,
                      label: l10n.confirmPasswordLabel,
                      obscureText: !_isPasswordVisible,
                      prefixIcon: const Icon(Icons.lock,
                          color: GlobalMilitaryTheme.lightMetal),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.confirmPasswordPrompt;
                        }
                        if (value != _passwordController.text) {
                          return l10n.passwordsDoNotMatch;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    ThemedTextFormField(
                      controller: _firstNameController,
                      label: l10n.firstNameLabel,
                      prefixIcon: const Icon(Icons.person_outline,
                          color: GlobalMilitaryTheme.lightMetal),
                    ),
                    const SizedBox(height: 16),

                    ThemedTextFormField(
                      controller: _lastNameController,
                      label: l10n.lastNameLabel,
                      prefixIcon: const Icon(Icons.person_outline,
                          color: GlobalMilitaryTheme.lightMetal),
                    ),
                    const SizedBox(height: 16),

                    // 🎨 DROPDOWN STYLISÉ
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              GlobalMilitaryTheme.primaryMetal.withOpacity(0.5),
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedRole,
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: l10n.roleLabel,
                          labelStyle: const TextStyle(color: Colors.black87),
                          prefixIcon: const Icon(Icons.person_pin,
                              color: GlobalMilitaryTheme.lightMetal),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'HOST',
                            child: Text(l10n.roleHost,
                                style: const TextStyle(color: Colors.black87)),
                          ),
                          DropdownMenuItem(
                            value: 'GAMER',
                            child: Text(l10n.roleGamer,
                                style: const TextStyle(color: Colors.black87)),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.rolePrompt;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 🎨 BOUTONS
                    ElevatedButton(
                      onPressed: authService.isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: authService.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(l10n.registerButton),
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        context.go('/login');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l10n.alreadyRegistered),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
