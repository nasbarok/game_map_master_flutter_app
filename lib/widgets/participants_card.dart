import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/game_session.dart';
import '../models/game_session_participant.dart';

class ParticipantsCard extends StatelessWidget {
  final List<GameSessionParticipant> participants;
  final Map<int, Color> teamColors;

  const ParticipantsCard({
    Key? key,
    required this.participants,
    required this.teamColors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Regrouper les participants par équipe
    Map<int?, List<GameSessionParticipant>> participantsByTeam = {};

    for (var participant in participants) {
      if (!participantsByTeam.containsKey(participant.teamId)) {
        participantsByTeam[participant.teamId] = [];
      }
      participantsByTeam[participant.teamId]!.add(participant);
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: Colors.blue,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  l10n.connectedPlayers,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${participants.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Afficher les participants par équipe
            ...participantsByTeam.entries.map((entry) {
              final teamId = entry.key;
              final teamParticipants = entry.value;
              final teamName = teamId != null && teamParticipants.isNotEmpty
                  ? teamParticipants.first.teamName ?? l10n.team + ' $teamId'
                  : l10n.noTeam;
              final teamColor = teamId != null ? teamColors[teamId] ?? Colors.grey : Colors.grey;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: teamColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: teamColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.group,
                          color: teamColor,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          teamName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: teamColor,
                          ),
                        ),
                        SizedBox(width: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: teamColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${teamParticipants.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: teamParticipants.map((participant) {
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor: teamColor,
                          child: Text(
                            participant.username.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        label: Text(participant.username),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: teamColor),
                        deleteIcon:Icon(Icons.star, color: Colors.amber, size: 16),
                        onDeleted: null,
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
