import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  final String userId;
  const NotificationsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirebaseService.instance.notificationsStream(userId),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(
                child: Text('لا توجد إشعارات حتى الآن', style: TextStyle(color: Colors.grey)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final n = items[i];
              final read = n['read'] == true;
              return Material(
                color: read ? Colors.white : AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    if (!read) FirebaseService.instance.markNotificationRead(n['id']);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(
                          read ? Icons.notifications_none : Icons.notifications_active,
                          color: read ? Colors.grey : AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n['title'] ?? '',
                                  style: TextStyle(
                                      fontWeight: read ? FontWeight.w600 : FontWeight.w900)),
                              if (n['body'] != null) ...[
                                const SizedBox(height: 2),
                                Text(n['body'],
                                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
