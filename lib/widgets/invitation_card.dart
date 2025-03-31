// Nouveau widget pour afficher une invitation de manière cohérente
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

    if (isSent) {
      username = payload['toUsername'] ?? 'Inconnu';
      role = 'à';
    } else {
      username = payload['fromUsername'] ?? 'Inconnu';
      role = 'de';
    }

    final mapName = payload['mapName'] ?? 'Carte inconnue';

    String statusText;
    if (status == 'pending') {
      statusText = 'En attente';
    } else if (status == 'accepted') {
      statusText = 'Acceptée';
    } else {
      statusText = 'Refusée';
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
        title: Text('Invitation $role $username'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Carte: $mapName'),
            Text('Statut: $statusText'),
          ],
        ),
        trailing: !isSent && status == 'pending' && onRespond != null
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => onRespond!(false),
              child: const Text('Refuser'),
            ),
            ElevatedButton(
              onPressed: () => onRespond!(true),
              child: const Text('Accepter'),
            ),
          ],
        )
            : null,
      ),
    );
  }
}
