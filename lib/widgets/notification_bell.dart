import 'package:flutter/material.dart';
import '../models/app_notification_model.dart';
import '../screens/notification_screen.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppNotification>>(
      stream: FirebaseService.instance.streamNotifications(),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          unreadCount = snapshot.data!.where((n) => !n.isRead).length;
        }

        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton.filledTonal(
                tooltip: 'Notifikasi',
                onPressed: () {
                  Navigator.pushNamed(context, NotificationScreen.routeName);
                },
                icon: const Icon(Icons.notifications_rounded),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
