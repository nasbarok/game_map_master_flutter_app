import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';

class InviteBadge extends StatelessWidget {
  final int count;
  final EdgeInsets padding;
  final double fontSize;

  const InviteBadge({
    Key? key,
    required this.count,
    this.padding = const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    this.fontSize = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = count > 99 ? '99+' : '$count';
    return Semantics(
      label: l10n.pendingInvitationsLabel(label),
      child: Container(
        padding: padding,
        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: fontSize),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
