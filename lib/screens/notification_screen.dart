import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_notification_model.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_scaffold.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  static const routeName = '/notifications';

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      currentRoute: routeName,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton.icon(
            onPressed: () {
              FirebaseService.instance.markAllNotificationsAsRead();
            },
            icon: const Icon(Icons.done_all, color: Colors.white),
            label: const Text('Tandai Semua Dibaca', style: TextStyle(color: Colors.white)),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: FirebaseService.instance.streamNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.muted),
                  SizedBox(height: 16),
                  Text('Belum ada notifikasi', style: TextStyle(color: AppColors.muted)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _NotificationCard(notification: notif);
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final bool isUnread = !notification.isRead;

    return InkWell(
      onTap: () {
        if (isUnread) {
          FirebaseService.instance.markNotificationAsRead(notification.id);
        }
      },
      borderRadius: AppTheme.radiusLarge,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.paper : AppColors.linen,
          borderRadius: AppTheme.radiusLarge,
          border: Border.all(
            color: isUnread ? AppColors.teal : Colors.transparent,
            width: 1,
          ),
          boxShadow: isUnread ? AppTheme.floatingShadow : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUnread ? AppColors.mint : AppColors.paper,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForType(notification.type),
                color: isUnread ? AppColors.tealDark : AppColors.muted,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.w900 : FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: isUnread ? AppColors.charcoal : AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dateFormat.format(notification.date),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'income':
        return Icons.monetization_on_rounded;
      case 'expense':
        return Icons.money_off_rounded;
      case 'user':
        return Icons.person_add_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
