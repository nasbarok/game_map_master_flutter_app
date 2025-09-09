// Nouveau widget pour afficher une invitation de manière cohérente
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';

class InvitationCard extends StatelessWidget {
  final Map<String, dynamic> invitation;
  final bool isSent;
  final Function(bool)? onRespond;

  const InvitationCard({
    Key? key,
    required this.invitation,
    required this.isSent,
    this.onRespond,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final payload = invitation['payload'] ?? {};
    final status = invitation['status'] ?? 'pending';

    final String username;
    final String role;

    final l10n = AppLocalizations.of(context)!;

    if (isSent) {
      username = payload['toUsername'] ?? l10n.unknown;
      role = l10n.roleTo;
    } else {
      username = payload['fromUsername'] ?? l10n.unknown;
      role = l10n.roleFrom;
    }

    final mapName = payload['mapName'] ?? l10n.unknownMap;

    String statusText;
    if (status == 'pending') {
      statusText = l10n.statusPending;
    } else if (status == 'accepted') {
      statusText = l10n.statusAccepted;
    } else {
      statusText = l10n.statusDeclined;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: status == 'pending'
              ? Colors.blue
              : status == 'accepted'
              ? Colors.green
              : Colors.red,
          child: Icon(
            status == 'pending'
                ? Icons.hourglass_empty
                : status == 'accepted'
                ? Icons.check
                : Icons.close,
            color: Colors.white,
          ),
        ),
        title: Text(l10n.invitationFromAndRole(username,role)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.mapLabelShort(mapName)),
            Text(l10n.sessionStatusLabel(statusText)),
          ],
        ),
        trailing: !isSent && status == 'pending' && onRespond != null
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => onRespond!(false),
              child: Text(l10n.decline),
            ),
            ElevatedButton(
              onPressed: () => onRespond!(true),
              child: Text(l10n.accept),
            ),
          ],
        )
            : null,
      ),
    );
  }
}
