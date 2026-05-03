import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final res = await ApiService.getNotifications();
      if (res['success'] == true) {
        setState(() {
          _notifications = res['data'];
          _isLoading = false;
        });
        // Mark as read after fetching
        await ApiService.markNotificationsRead();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('MMM dd, yyyy - hh:mm a').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(child: Text('No notifications yet.', style: TextStyle(fontSize: 16)))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    final isRead = notif['is_read'] == true;
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: isRead ? 1 : 3,
                      color: isRead ? Colors.white : Colors.blue.shade50,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: notif['title'].toString().toLowerCase().contains('earned') 
                              ? Colors.green.shade100 
                              : Colors.orange.shade100,
                          child: Icon(
                            notif['title'].toString().toLowerCase().contains('earned') 
                                ? Icons.add_circle 
                                : Icons.remove_circle,
                            color: notif['title'].toString().toLowerCase().contains('earned') 
                                ? Colors.green 
                                : Colors.orange,
                          ),
                        ),
                        title: Text(
                          notif['title'],
                          style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(notif['message'], style: TextStyle(color: Colors.black87)),
                            SizedBox(height: 4),
                            Text(
                              _formatDate(notif['created_at']),
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
