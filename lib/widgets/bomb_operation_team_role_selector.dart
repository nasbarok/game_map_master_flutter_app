import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/scenario/bomb_operation/bomb_operation_team.dart';
import '../models/team.dart';

class BombOperationTeamRoleSelector extends StatefulWidget {
  final int gameSessionId;
  final List<Team> teams;
  final Function(Map<int, BombOperationTeam>) onRolesAssigned;

  const BombOperationTeamRoleSelector({
    Key? key,
    required this.gameSessionId,
    required this.teams,
    required this.onRolesAssigned,
  }) : super(key: key);

  @override
  _BombOperationTeamRoleSelectorState createState() => _BombOperationTeamRoleSelectorState();
}

class _BombOperationTeamRoleSelectorState extends State<BombOperationTeamRoleSelector> {
  final Map<int, BombOperationTeam> _assignedRoles = {};

  @override
  void initState() {
    super.initState();
    if (widget.teams.length >= 2) {
      _assignedRoles[widget.teams[0].id] = BombOperationTeam.attack;
      _assignedRoles[widget.teams[1].id] = BombOperationTeam.defense;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Assignation des rôles pour l\'Opération Bombe',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Text(
          'Choisissez quelle équipe sera Terroriste (attaque) et quelle équipe sera Anti-terroriste (défense).',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        ...widget.teams.map((team) => _buildTeamRoleSelector(team)).toList(),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _validateAndSave,
          child: const Text('Confirmer les rôles'),
        ),
      ],
    );
  }

  Widget _buildTeamRoleSelector(Team team) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _parseColor(team.color) ?? Colors.grey,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1, // 1/3 de l'espace
              child: Text(
                team.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2, // 2/3 de l'espace
              child: DropdownButton<BombOperationTeam>(
                isExpanded: true,
                value: _assignedRoles[team.id] ?? BombOperationTeam.attack,
                selectedItemBuilder: (context) {
                  return [
                    const Text('Terroriste (Attaque)'),
                    const Text('Anti-terroriste'),
                  ];
                },
                items: [
                  DropdownMenuItem(
                    value: BombOperationTeam.attack,
                    child: Row(
                      children: const [
                        Icon(Icons.dangerous, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Terroriste (Attaque)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: BombOperationTeam.defense,
                    child: Row(
                      children: const [
                        Icon(Icons.shield, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Anti-terroriste (Defense)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _assignedRoles[team.id] = value;
                      for (final otherTeam in widget.teams) {
                        if (otherTeam.id != team.id) {
                          _assignedRoles[otherTeam.id] =
                          value == BombOperationTeam.attack
                              ? BombOperationTeam.defense
                              : BombOperationTeam.attack;
                        }
                      }
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _validateAndSave() {
    if (_assignedRoles.length != widget.teams.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez assigner un rôle à chaque équipe.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final hasAttack = _assignedRoles.values.contains(BombOperationTeam.attack);
    final hasDefense = _assignedRoles.values.contains(BombOperationTeam.defense);

    if (!hasAttack || !hasDefense) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Il doit y avoir au moins une équipe Terroriste et une équipe Anti-terroriste.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    widget.onRolesAssigned(_assignedRoles);
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse('0xFF${colorString.substring(1)}'));
      }
      return Colors.blue;
    } catch (_) {
      return null;
    }
  }
}