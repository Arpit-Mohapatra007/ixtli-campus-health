import 'dart:async';
import 'package:campus_health/utils/app_exception.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localParams = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  Future<void> init() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', 
      'High Importance Notifications', 
      importance: Importance.max,
      playSound: true,
    );

    await _localParams
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localParams.initialize(initializationSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _showLocalNotification(
          id: notification.hashCode,
          title: notification.title ?? 'Alert',
          body: notification.body ?? '',
          payload: 'fcm',
        );
      }
    });
  }

  Future<void> uploadFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcmToken': token,
      });
    } catch (e) {
      throw AppException('Failed to upload FCM token: $e');
    }
  }

  List<StreamSubscription> listenForLocalAlerts(UserModel user) {
    List<StreamSubscription> subs = [];
    
    if (user.role == 'driver') {
      subs.add(_listenToSOS());
    } else if (user.role == 'student') {
      subs.add(_listenToAppointments(user.uid));
      subs.add(_listenToBroadcasts(user));
    }
    
    return subs;
  }

  StreamSubscription _listenToSOS() {
    return _db.collection('emergencies')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          _showLocalNotification(
            id: change.doc.hashCode,
            title: "SOS ALERT!",
            body: "${data['studentName']} at ${data['roomNumber']} needs help!",
            payload: "sos",
          );
        }
      }
    });
  }

  StreamSubscription _listenToAppointments(String studentId) {
    return _db.collection('appointments')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data() as Map<String, dynamic>;
          if (data['status'] == 'approved') {
            _showLocalNotification(
              id: change.doc.hashCode,
              title: "Appointment Approved",
              body: "${data['doctorName']} is ready to see you.",
              payload: "appointment",
            );
          }
        }
      }
    });
  }

  StreamSubscription _listenToBroadcasts(UserModel user) {
    String? myWing;
    String? myFloor;
    final roomRegex = RegExp(r"^([A-Z0-9]+)([1-4])(\d{2})$");
    final match = roomRegex.firstMatch(user.roomNumber);
    if (match != null) {
      myWing = match.group(1);
      myFloor = match.group(2);
    }

    return _db.collection('broadcasts')
        .where('targetHostel', isEqualTo: user.hostel)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
       for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
           final data = change.doc.data() as Map<String, dynamic>;

           String? targetWing = data['targetWing'];
           String? targetFloor = data['targetFloor'];

           bool wingMatch = (targetWing == null || targetWing.isEmpty || targetWing == 'All' || targetWing == myWing);
           bool floorMatch = (targetFloor == null || targetFloor.isEmpty || targetFloor == 'All' || targetFloor == myFloor);

           if (wingMatch && floorMatch) {
             _showLocalNotification(
               id: change.doc.hashCode,
               title: "HOSTEL ALERT",
               body: data['message'] ?? "Important notice for your hostel.",
               payload: "broadcast",
             );
           }
        }
       }
    });
  }

  Future<void> _showLocalNotification({
    required int id, 
    required String title, 
    required String body, 
    required String payload
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel', 
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      styleInformation: BigTextStyleInformation(''),
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    
    await _localParams.show(id, title, body, details, payload: payload);
  }
}