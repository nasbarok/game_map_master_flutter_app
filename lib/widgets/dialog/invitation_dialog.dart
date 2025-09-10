import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/invitation.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/invitation_service.dart';
import '../../services/api_service.dart';
import '../../services/game_state_service.dart';

class InvitationDialog extends StatefulWidget {
  final Invitation invitation;
  final bool isWebSocketDialog;

  const InvitationDialog({
    Key? key,
    required this.invitation,
    this.isWebSocketDialog = false,
  }) : super(key: key);

  @override
  _InvitationDialogState createState() => _InvitationDialogState();
}

class _InvitationDialogState extends State<InvitationDialog> {
  bool _isLoading = false;

  Future<void> _handleResponse(bool accept) async {
    if (_isLoading) return; // ✅ Éviter double clic

    setState(() => _isLoading = true);

    final l10n = AppLocalizations.of(context)!;

    try {
      final invitationService = context.read<InvitationService>();

      if (widget.isWebSocketDialog && accept) {
        // Logique complète pour WebSocket (accept avec navigation)
        final gameStateService = context.read<GameStateService>();
        final apiService = context.read<ApiService>();
        final currentUser = context.read<AuthService>().currentUser;

        // 1. Envoi réponse ACCEPT
        await invitationService.respondToInvitation(
            context,
            widget.invitation.id,
            true
        );

        // 2. Restore session complète
        await gameStateService.restoreSessionIfNeeded(
            apiService,
            widget.invitation.fieldId
        );

        // 3. Navigation
        if (mounted) {
          Navigator.of(context).pop();
          if (currentUser != null) {
            if (currentUser.hasRole('HOST')) {
              context.go('/host');
            } else {
              final timestamp = DateTime.now().millisecondsSinceEpoch;
              context.go('/gamer/lobby?refresh=$timestamp');
            }
          }
        }
      } else {
        // Logique simple pour HostDashboard
        await invitationService.respondToInvitation(
            context,
            widget.invitation.id,
            accept
        );

        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.genericError(e)),
            backgroundColor: const Color(0xFFE53E3E),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _buildMilitaryDialog(
      title: l10n.invitationReceivedTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.isWebSocketDialog
                ? l10n.invitationReceivedBody(
                widget.invitation.senderUsername,
                widget.invitation.fieldName
            )
                : l10n.invitationReceivedMessage(
              widget.invitation.senderUsername ?? l10n.unknownPlayerName,
              widget.invitation.fieldName ?? l10n.unknownMap,
            ),
            style: const TextStyle(color: Color(0xFFF7FAFC)),
          ),

          // ✅ NOUVEAU : Indicateur de chargement
          if (_isLoading) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF48BB78)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.processing,
                  style: const TextStyle(
                    color: Color(0xFF48BB78),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: _isLoading ? [] : [ // Masquer boutons pendant loading
        _buildMilitaryButton(
          text: widget.isWebSocketDialog ? l10n.decline : l10n.declineInvitation,
          onPressed: () => _handleResponse(false),
          style: _MilitaryButtonStyle.secondary,
        ),
        _buildMilitaryButton(
          text: widget.isWebSocketDialog ? l10n.accept : l10n.acceptInvitation,
          onPressed: () => _handleResponse(true),
          style: _MilitaryButtonStyle.primary,
        ),
      ],
    );
  }

  /// _buildMilitaryDialog
  Widget _buildMilitaryDialog({
    required String title,
    required Widget content,
    required List<Widget> actions,
  }) {
    return Dialog(
      backgroundColor: const Color(0xFF2D3748),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF4A5568), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFF7FAFC),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            content,
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions
                  .map((action) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: action,
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ _buildMilitaryButton
  Widget _buildMilitaryButton({
    required String text,
    required VoidCallback? onPressed,
    required _MilitaryButtonStyle style,
    IconData? icon,
  }) {
    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;

    switch (style) {
      case _MilitaryButtonStyle.primary:
        backgroundColor = const Color(0xFF48BB78);
        foregroundColor = const Color(0xFFF7FAFC);
        borderColor = const Color(0xFF48BB78);
        break;
      case _MilitaryButtonStyle.secondary:
        backgroundColor = Colors.transparent;
        foregroundColor = const Color(0xFF48BB78);
        borderColor = const Color(0xFF48BB78);
        break;
      case _MilitaryButtonStyle.danger:
        backgroundColor = const Color(0xFFE53E3E);
        foregroundColor = const Color(0xFFF7FAFC);
        borderColor = const Color(0xFFE53E3E);
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: foregroundColor, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _MilitaryButtonStyle {
  primary,
  secondary,
  danger,
}