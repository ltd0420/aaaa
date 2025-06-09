import '../services/notification_service.dart';

class NotificationHelper {
  // Tạo thông báo cập nhật trạng thái đơn hàng
  static Future<void> createOrderStatusNotification({
    required String orderId,
    required String status,
    String? message,
  }) async {
    await NotificationService.createOrderStatusNotification(
      orderId: orderId,
      status: status,
      message: message,
    );
  }

  // Tạo thông báo cho đơn hàng mới (khi khách đặt hàng)
  static Future<void> createNewOrderNotification({
    required String orderId,
    required String customerName,
    required double totalAmount,
  }) async {
    await NotificationService.createOrderStatusNotification(
      orderId: orderId,
      status: 'new',
      message: 'Đơn hàng mới từ $customerName - ${_formatPrice(totalAmount)}₫',
    );
  }

  // Tạo thông báo xác nhận đơn hàng
  static Future<void> createOrderConfirmedNotification({
    required String orderId,
    String? estimatedTime,
  }) async {
    final message = estimatedTime != null 
        ? 'Đơn hàng đã được xác nhận. Thời gian dự kiến: $estimatedTime'
        : null;
    
    await NotificationService.createOrderStatusNotification(
      orderId: orderId,
      status: 'confirmed',
      message: message,
    );
  }

  // Tạo thông báo đang chuẩn bị món
  static Future<void> createOrderPreparingNotification({
    required String orderId,
    String? estimatedTime,
  }) async {
    final message = estimatedTime != null 
        ? 'Đơn hàng đang được chuẩn bị. Thời gian dự kiến: $estimatedTime'
        : null;
    
    await NotificationService.createOrderStatusNotification(
      orderId: orderId,
      status: 'preparing',
      message: message,
    );
  }

  // Tạo thông báo đang giao hàng
  static Future<void> createOrderShippingNotification({
    required String orderId,
    String? driverName,
    String? estimatedTime,
  }) async {
    String message = 'Đơn hàng đang được giao đến bạn';
    if (driverName != null) {
      message = 'Tài xế $driverName đang giao đơn hàng đến bạn';
    }
    if (estimatedTime != null) {
      message += '. Dự kiến: $estimatedTime';
    }
    
    await NotificationService.createOrderStatusNotification(
      orderId: orderId,
      status: 'shipping',
      message: message,
    );
  }

  // Tạo thông báo giao hàng thành công
  static Future<void> createOrderDeliveredNotification({
    required String orderId,
  }) async {
    await NotificationService.createOrderStatusNotification(
      orderId: orderId,
      status: 'delivered',
      message: 'Đơn hàng đã được giao thành công. Cảm ơn bạn đã tin tưởng KFC!',
    );
  }

  // Tạo thông báo hủy đơn hàng
  static Future<void> createOrderCancelledNotification({
    required String orderId,
    String? reason,
  }) async {
    String message = 'Đơn hàng #${orderId.substring(0, 8)} đã bị hủy';
    if (reason != null) {
      message += '. Lý do: $reason';
    }
    
    await NotificationService.createOrderStatusNotification(
      orderId: orderId,
      status: 'cancelled',
      message: message,
    );
  }

  // Format giá tiền
  static String _formatPrice(double price) {
    return price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // Tạo thông báo test cho các trạng thái đơn hàng
  static Future<void> createTestOrderNotifications() async {
    final orderId = 'DH${DateTime.now().millisecondsSinceEpoch}';
    
    final notifications = [
      () => createNewOrderNotification(
        orderId: orderId,
        customerName: 'Nguyễn Văn A',
        totalAmount: 250000,
      ),
      () => createOrderConfirmedNotification(
        orderId: orderId,
        estimatedTime: '15-20 phút',
      ),
      () => createOrderPreparingNotification(
        orderId: orderId,
        estimatedTime: '10 phút',
      ),
      () => createOrderShippingNotification(
        orderId: orderId,
        driverName: 'Minh',
        estimatedTime: '15 phút',
      ),
      () => createOrderDeliveredNotification(orderId: orderId),
    ];

    for (int i = 0; i < notifications.length; i++) {
      await Future.delayed(Duration(milliseconds: 1000 * i));
      await notifications[i]();
    }
  }

  // Tạo một thông báo test ngẫu nhiên
  static Future<void> createRandomTestNotification() async {
    final orderId = 'DH${DateTime.now().millisecondsSinceEpoch}';
    final statuses = ['confirmed', 'preparing', 'shipping', 'delivered'];
    final randomStatus = statuses[DateTime.now().second % statuses.length];
    
    await createOrderStatusNotification(
      orderId: orderId,
      status: randomStatus,
    );
  }
}
