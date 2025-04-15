import 'package:airsoft_game_map/models/scenario.dart';
import 'package:airsoft_game_map/models/scenario/treasure_hunt/treasure_hunt_scenario.dart';

class ScenarioDTO {
  final Scenario scenario;
  final TreasureHuntScenario? treasureHuntScenario;

  ScenarioDTO({
    required this.scenario,
    this.treasureHuntScenario,
  });

  factory ScenarioDTO.fromJson(Map<String, dynamic> json) {
    return ScenarioDTO(
      scenario: Scenario.fromJson(json['scenario']),
      treasureHuntScenario: json['treasureHuntScenario'] != null
          ? TreasureHuntScenario.fromJson(json['treasureHuntScenario'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scenario': scenario.toJson(),
      'treasureHuntScenario': treasureHuntScenario?.toJson(),
    };
  }
}
