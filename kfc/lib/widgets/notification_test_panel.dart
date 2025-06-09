import 'package:flutter/material.dart';
import '../theme/mau_sac.dart';
import '../utils/notification_helper.dart';

class NotificationTestPanel extends StatelessWidget {
  const NotificationTestPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MauSac.denNhat,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MauSac.kfcRed.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MauSac.kfcRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.science,
                  color: MauSac.kfcRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Test Thông Báo Đơn Hàng',
                style: TextStyle(
                  color: MauSac.trang,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Order status notification buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTestButton(
                context,
                'Đơn mới',
                Icons.shopping_bag_outlined,
                MauSac.xanhLa,
                () => NotificationHelper.createNewOrderNotification(
                  orderId: 'DH${DateTime.now().millisecondsSinceEpoch}',
                  customerName: 'Nguyễn Văn A',
                  totalAmount: 250000,
                ),
              ),
              _buildTestButton(
                context,
                'Xác nhận',
                Icons.check_circle_outline,
                Colors.blue,
                () => NotificationHelper.createOrderConfirmedNotification(
                  orderId: 'DH${DateTime.now().millisecondsSinceEpoch}',
                  estimatedTime: '15-20 phút',
                ),
              ),
              _buildTestButton(
                context,
                'Chuẩn bị',
                Icons.restaurant,
                MauSac.vang,
                () => NotificationHelper.createOrderPreparingNotification(
                  orderId: 'DH${DateTime.now().millisecondsSinceEpoch}',
                  estimatedTime: '10 phút',
                ),
              ),
              _buildTestButton(
                context,
                'Đang giao',
                Icons.local_shipping,
                MauSac.cam,
                () => NotificationHelper.createOrderShippingNotification(
                  orderId: 'DH${DateTime.now().millisecondsSinceEpoch}',
                  driverName: 'Minh',
                  estimatedTime: '15 phút',
                ),
              ),
              _buildTestButton(
                context,
                'Đã giao',
                Icons.check_circle,
                MauSac.xanhLa,
                () => NotificationHelper.createOrderDeliveredNotification(
                  orderId: 'DH${DateTime.now().millisecondsSinceEpoch}',
                ),
              ),
              _buildTestButton(
                context,
                'Đã hủy',
                Icons.cancel,
                Colors.red,
                () => NotificationHelper.createOrderCancelledNotification(
                  orderId: 'DH${DateTime.now().millisecondsSinceEpoch}',
                  reason: 'Khách hàng yêu cầu hủy',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Control buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await NotificationHelper.createTestOrderNotifications();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Đã tạo chuỗi thông báo đơn hàng!'),
                          backgroundColor: MauSac.xanhLa,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Tạo chuỗi TB'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MauSac.kfcRed,
                    foregroundColor: MauSac.trang,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await NotificationHelper.createRandomTestNotification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Đã tạo thông báo ngẫu nhiên!'),
                          backgroundColor: MauSac.cam,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.shuffle),
                  label: const Text('TB ngẫu nhiên'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MauSac.cam.withOpacity(0.2),
                    foregroundColor: MauSac.cam,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Quick test button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await NotificationHelper.createOrderStatusNotification(
                  orderId: 'DH${DateTime.now().millisecondsSinceEpoch}',
                  status: 'test',
                  message: 'Thông báo test thành công!',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Test thông báo cơ bản!'),
                      backgroundColor: MauSac.kfcRed,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Test nhanh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MauSac.kfcRed.withOpacity(0.1),
                foregroundColor: MauSac.kfcRed,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: () async {
        onPressed();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tạo TB: $label'),
              backgroundColor: color,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(milliseconds: 800),
            ),
          );
        }
      },
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(0, 36),
      ),
    );
  }
}