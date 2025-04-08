import 'package:airsoft_game_map/models/websocket/websocket_message.dart';

class InvitationResponseMessage extends WebSocketMessage {
  final int fieldId;
  final int senderId;
  final int targetUserId;
  final String fromUsername;
  final String mapName;
  final bool accepted;

  InvitationResponseMessage({
    required this.fieldId,
    required this.senderId,
    required this.targetUserId,
    required this.fromUsername,
    required this.mapName,
    required this.accepted,
  }) : super('INVITATION_RESPONSE', senderId);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'senderId': senderId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'payload': {
        'fieldId': fieldId,
        'senderId': senderId,
        'targetUserId': targetUserId,
        'fromUsername': fromUsername,
        'mapName': mapName,
        'accepted': accepted,
      },
    };
  }

  factory InvitationResponseMessage.fromJson(Map<String, dynamic> json) {
    return InvitationResponseMessage(
      fieldId: json['payload']['fieldId'],
      senderId: json['payload']['senderId'],
      targetUserId: json['payload']['targetUserId'],
      fromUsername: json['payload']['fromUsername'],
      mapName: json['payload']['mapName'],
      accepted: json['payload']['accepted'],
    );
  }
}
