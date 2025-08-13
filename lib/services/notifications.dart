import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/invitation.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);
}

Future<void> showInvitationNotification(Invitation invitation) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'invitation_channel',
    'Invitations',
    channelDescription: 'Notifications des invitations reçues',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    'Invitation reçue',
    'De ${invitation.senderUsername} pour "${invitation.fieldName}"',
    platformDetails,
  );
}