import 'package:game_map_master_flutter_app/models/websocket/websocket_message.dart';
import 'package:game_map_master_flutter_app/models/game_session_participant.dart';

class ParticipantJoinedMessage extends WebSocketMessage {
  final int gameSessionId;
  final GameSessionParticipant participant;

  ParticipantJoinedMessage({
    required this.gameSessionId,
    required this.participant,
    required int senderId,
  }) : super('PARTICIPANT_JOINED', senderId);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'senderId': senderId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'payload': {
        'gameSessionId': gameSessionId,
        'participant': participant.toJson(),
      },
    };
  }

  factory ParticipantJoinedMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'];
    return ParticipantJoinedMessage(
      gameSessionId: payload['gameSessionId'],
      participant: GameSessionParticipant.fromJson(payload['participant']),
      senderId: json['senderId'],
    );
  }
}
