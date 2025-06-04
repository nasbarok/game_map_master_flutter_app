import '../../../models/scenario/bomb_operation/bomb_operation_team.dart';

class BombOperationScenarioConfig {
  final Map<int, BombOperationTeam> roles;
  final int scenarioId;

  BombOperationScenarioConfig({
    required this.roles,
    required this.scenarioId,
  });
}