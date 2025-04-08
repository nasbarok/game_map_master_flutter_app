import 'package:airsoft_game_map/models/websocket/websocket_message.dart';

class InvitationReceivedMessage extends WebSocketMessage {
  final int fieldId;
  final int senderId;
  final int targetUserId;
  final String fromUsername;
  final String mapName;

  InvitationReceivedMessage({
    required this.fieldId,
    required this.senderId,
    required this.targetUserId,
    required this.fromUsername,
    required this.mapName,
  }) : super('INVITATION_RECEIVED', senderId);

  factory InvitationReceivedMessage.fromJson(Map<String, dynamic> json) {
    return InvitationReceivedMessage(
      fieldId: json['payload']['fieldId'],
      senderId: json['payload']['senderId'],
      targetUserId: json['payload']['targetUserId'],
      fromUsername: json['payload']['fromUsername'],
      mapName: json['payload']['mapName'],
    );
  }

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
      },
    };
  }
}
