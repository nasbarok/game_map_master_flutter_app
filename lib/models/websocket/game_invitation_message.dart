import 'package:airsoft_game_map/models/websocket/websocket_message.dart';

class GameInvitationMessage extends WebSocketMessage {
  final int fieldId;
  final int senderId;
  final int targetUserId;

  GameInvitationMessage({
    required this.fieldId,
    required this.senderId,
    required this.targetUserId,
  }) : super('GAME_INVITATION', senderId);

  factory GameInvitationMessage.fromJson(Map<String, dynamic> json) {
    return GameInvitationMessage(
      fieldId: json['fieldId'],
      senderId: json['senderId'],
      targetUserId: json['targetUserId'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'fieldId': fieldId,
      'senderId': senderId,
      'targetUserId': targetUserId,
    };
  }
}
