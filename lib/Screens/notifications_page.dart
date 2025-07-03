import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  final List<Map<String, String>> notifications = const [
    {
      'title': 'Budget Alert',
      'body': 'You have spent 80% of your monthly budget.',
      'time': '2h ago',
      'icon': 'notifications',
    },
    {
      'title': 'Weekly Report',
      'body': 'Your weekly spending report is ready.',
      'time': '3d ago',
      'icon': 'trending_up',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.notifications, color: colorScheme.primary),
            SizedBox(width: 10),
            Text('Notifications', style: TextStyle(color: colorScheme.onBackground)),
          ],
        ),
        backgroundColor: colorScheme.background,
        iconTheme: IconThemeData(color: colorScheme.onBackground),
        elevation: 1,
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: colorScheme.primary.withOpacity(0.3)),
                  SizedBox(height: 20),
                  Text('No notifications yet!', style: TextStyle(fontSize: 20, color: colorScheme.onBackground.withOpacity(0.7))),
                  SizedBox(height: 10),
                  Text("You're all caught up.", style: TextStyle(fontSize: 16, color: colorScheme.onBackground.withOpacity(0.5))),
                ],
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.all(18),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => SizedBox(height: 14),
              itemBuilder: (context, i) {
                final n = notifications[i];
                IconData icon;
                switch (n['icon']) {
                  case 'schedule': icon = Icons.schedule; break;
                  case 'trending_up': icon = Icons.trending_up; break;
                  default: icon = Icons.notifications;
                }
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 2,
                  color: colorScheme.surface,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primary.withOpacity(0.13),
                      child: Icon(icon, color: colorScheme.primary),
                    ),
                    title: Text(n['title']!, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                    subtitle: Text(n['body']!, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8))),
                    trailing: Text(n['time']!, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 13)),
                  ),
                );
              },
            ),
    );
  }
} 