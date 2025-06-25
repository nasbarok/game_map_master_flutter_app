import 'package:game_map_master_flutter_app/models/websocket/websocket_message.dart';
import 'package:game_map_master_flutter_app/models/scenario/scenario_dto.dart';

class ScenarioUpdateMessage extends WebSocketMessage {
  final int fieldId;
  final List<ScenarioDTO> scenarioDtos;

  ScenarioUpdateMessage({
    required this.fieldId,
    required this.scenarioDtos,
    required int senderId,
    required DateTime timestamp,
  }) : super('SCENARIO_UPDATE', senderId);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'senderId': senderId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'payload': {
        'fieldId': fieldId,
        'scenarioDtos': scenarioDtos.map((dto) => dto.toJson()).toList(),
      },
    };
  }

  factory ScenarioUpdateMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>? ?? {};

    final dynamic rawFieldId = payload['fieldId'];
    final int fieldId = (rawFieldId != null)
        ? (rawFieldId is int ? rawFieldId : int.tryParse(rawFieldId.toString()) ?? 0)
        : 0;

    final dynamic rawSenderId = json['senderId'];
    final int senderId = (rawSenderId != null)
        ? (rawSenderId is int ? rawSenderId : int.tryParse(rawSenderId.toString()) ?? 0)
        : 0;

    final dynamic rawTimestamp = json['timestamp'];
    final DateTime timestamp = (rawTimestamp != null)
        ? (rawTimestamp is int
        ? DateTime.fromMillisecondsSinceEpoch(rawTimestamp)
        : DateTime.fromMillisecondsSinceEpoch(int.tryParse(rawTimestamp.toString()) ?? 0))
        : DateTime.now();

    final List<dynamic> scenariosJson = payload['scenarioDtos'] ?? [];
    final List<ScenarioDTO> scenarioDtos = [];
    for (final dtoJson in scenariosJson) {
      scenarioDtos.add(ScenarioDTO.fromJson(Map<String, dynamic>.from(dtoJson)));
    }

    return ScenarioUpdateMessage(
      fieldId: fieldId,
      scenarioDtos: scenarioDtos,
      senderId: senderId,
      timestamp: timestamp,
    );
  }



}
