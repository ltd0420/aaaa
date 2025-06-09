import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/thong_bao.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Khởi tạo notification service
  static Future<void> initialize() async {
    // Khởi tạo local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Khởi tạo Firebase Messaging
    await _initializeFirebaseMessaging();
  }

  static Future<void> _initializeFirebaseMessaging() async {
    // Yêu cầu quyền thông báo
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Đã cấp quyền thông báo');
      
      // Lấy FCM token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }

      // Lắng nghe token refresh
      _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);

      // Xử lý thông báo khi app đang chạy
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Xử lý thông báo khi app được mở từ background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // Xử lý thông báo khi app được mở từ terminated state
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessage(initialMessage);
      }
    }
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ Đã lưu FCM token');
      } catch (e) {
        print('❌ Lỗi khi lưu FCM token: $e');
      }
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print('📱 Nhận thông báo khi app đang chạy: ${message.notification?.title}');
    
    // Hiển thị local notification
    _showLocalNotification(
      title: message.notification?.title ?? 'KFC Vietnam',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );

    // Lưu thông báo vào Firestore
    _saveNotificationToFirestore(message);
  }

  static void _handleBackgroundMessage(RemoteMessage message) {
    print('📱 Mở app từ thông báo: ${message.notification?.title}');
    // Xử lý navigation hoặc action cụ thể
    _handleNotificationAction(message.data);
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'kfc_channel',
      'KFC Notifications',
      channelDescription: 'Thông báo từ KFC Vietnam',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFD00808),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('📱 Người dùng tap vào thông báo: ${response.payload}');
    // Xử lý khi user tap vào notification
  }

  static Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final thongBao = ThongBao(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          tieuDe: message.notification?.title ?? 'KFC Vietnam',
          noiDung: message.notification?.body ?? '',
          loai: message.data['type'] ?? 'don_hang', // Mặc định là đơn hàng
          thoiGian: DateTime.now(),
          daDoc: false,
          hinhAnh: message.notification?.android?.imageUrl,
          duLieuThem: message.data,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('thong_bao')
            .add(thongBao.toJson());
        
        print('✅ Đã lưu thông báo vào Firestore');
      } catch (e) {
        print('❌ Lỗi khi lưu thông báo: $e');
      }
    }
  }

  static void _handleNotificationAction(Map<String, dynamic> data) {
    // Xử lý action dựa trên data của notification
    final type = data['type'];
    final id = data['id'];
    
    // Tập trung vào đơn hàng
    if (type == 'don_hang') {
      // Navigate to order detail
    }
  }

  // Gửi thông báo local
  static Future<void> sendLocalNotification({
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
    );
  }

  // Lấy danh sách thông báo của user
  static Future<List<ThongBao>> getUserNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('thong_bao')
          .orderBy('thoiGian', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ThongBao.fromJson(data);
      }).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy thông báo: $e');
      return [];
    }
  }

  // Đánh dấu thông báo đã đọc
  static Future<void> markAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('thong_bao')
          .doc(notificationId)
          .update({'daDoc': true});
    } catch (e) {
      print('❌ Lỗi khi đánh dấu đã đọc: $e');
    }
  }

  // Xóa thông báo
  static Future<void> deleteNotification(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('thong_bao')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('❌ Lỗi khi xóa thông báo: $e');
    }
  }

  // Stream thông báo real-time
  static Stream<List<ThongBao>> streamUserNotifications() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('thong_bao')
        .orderBy('thoiGian', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ThongBao.fromJson(data);
      }).toList();
    });
  }

  // Tạo thông báo trạng thái đơn hàng và lưu vào Firebase
  static Future<void> createOrderStatusNotification({
    required String orderId,
    required String status,
    String? message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String title = '';
    String body = message ?? '';

    switch (status.toLowerCase()) {
      case 'confirmed':
        title = '✅ Đơn hàng đã xác nhận';
        body = body.isEmpty ? 'Đơn hàng #${orderId.substring(0, 8)} đã được xác nhận' : body;
        break;
      case 'preparing':
        title = '👨‍🍳 Đang chuẩn bị món';
        body = body.isEmpty ? 'Đơn hàng của bạn đang được chuẩn bị' : body;
        break;
      case 'shipping':
        title = '🚚 Đang giao hàng';
        body = body.isEmpty ? 'Đơn hàng đang trên đường giao đến bạn' : body;
        break;
      case 'delivered':
        title = '🎉 Giao hàng thành công';
        body = body.isEmpty ? 'Đơn hàng đã được giao thành công!' : body;
        break;
      case 'cancelled':
        title = '❌ Đơn hàng đã hủy';
        body = body.isEmpty ? 'Đơn hàng #${orderId.substring(0, 8)} đã bị hủy' : body;
        break;
      default:
        title = '📦 Cập nhật đơn hàng';
        body = body.isEmpty ? 'Đơn hàng #${orderId.substring(0, 8)} đã được cập nhật' : body;
    }

    try {
      // Tạo đối tượng thông báo
      final thongBao = ThongBao(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tieuDe: title,
        noiDung: body,
        loai: 'don_hang',
        thoiGian: DateTime.now(),
        daDoc: false,
        duLieuThem: {
          'donHangId': orderId,
          'status': status,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Lưu vào Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('thong_bao')
          .add(thongBao.toJson());
    
      // Hiển thị local notification
      await _showLocalNotification(
        title: title,
        body: body,
      );
    
      print('✅ Đã tạo thông báo trạng thái đơn hàng: $title');
    } catch (e) {
      print('❌ Lỗi khi tạo thông báo trạng thái đơn hàng: $e');
    }
  }
}
