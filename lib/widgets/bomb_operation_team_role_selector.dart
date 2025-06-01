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
  // Map des rôles assignés (teamId -> rôle)
  final Map<int, BombOperationTeam> _assignedRoles = {};

  @override
  void initState() {
    super.initState();
    // Initialiser avec des valeurs par défaut
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
              child: Text(
                team.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DropdownButton<BombOperationTeam>(
              value: _assignedRoles[team.id] ?? BombOperationTeam.attack,
              items: [
                DropdownMenuItem(
                  value: BombOperationTeam.attack,
                  child: Row(
                    children: [
                      Icon(Icons.dangerous, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Terroriste (Attaque)'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: BombOperationTeam.defense,
                  child: Row(
                    children: [
                      Icon(Icons.shield, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Anti-terroriste (Défense)'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _assignedRoles[team.id] = value;

                    // Si on assigne un rôle à cette équipe, s'assurer que l'autre équipe a le rôle opposé
                    for (final otherTeam in widget.teams) {
                      if (otherTeam.id != team.id) {
                        _assignedRoles[otherTeam.id] = value == BombOperationTeam.attack
                            ? BombOperationTeam.defense
                            : BombOperationTeam.attack;
                      }
                    }
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _validateAndSave() {
    // Vérifier que toutes les équipes ont un rôle assigné
    if (_assignedRoles.length != widget.teams.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez assigner un rôle à chaque équipe.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérifier qu'il y a au moins une équipe d'attaque et une équipe de défense
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

    // Appeler le callback avec les rôles assignés
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
