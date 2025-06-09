import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../models/thong_bao.dart';
import '../theme/mau_sac.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ManHinhThongBao extends StatefulWidget {
  const ManHinhThongBao({Key? key}) : super(key: key);

  @override
  State<ManHinhThongBao> createState() => _ManHinhThongBaoState();
}

class _ManHinhThongBaoState extends State<ManHinhThongBao>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedFilter = 'all'; // all, don_hang, giao_hang

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
    
    // Cấu hình timeago cho tiếng Việt
    timeago.setLocaleMessages('vi', timeago.ViMessages());

    // Khởi tạo Firebase notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFirebaseNotifications();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeFirebaseNotifications() async {
    try {
      // Yêu cầu quyền thông báo
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Đã cấp quyền thông báo Firebase');
        
        // Lắng nghe thông báo real-time từ Firebase
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('📱 Nhận thông báo Firebase: ${message.notification?.title}');
          
          // Refresh danh sách thông báo
          if (mounted) {
            Provider.of<NotificationProvider>(context, listen: false)
                .taiDanhSachThongBao();
          }
        });
      }
    } catch (e) {
      print('❌ Lỗi khởi tạo Firebase notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MauSac.denNen,
      appBar: AppBar(
        backgroundColor: MauSac.denNen,
        foregroundColor: MauSac.trang,
        title: const Text(
          'Thông báo giao hàng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.soThongBaoChuaDoc > 0) {
                return TextButton(
                  onPressed: () => provider.danhDauTatCaDaDoc(),
                  child: Text(
                    'Đọc tất cả (${provider.soThongBaoChuaDoc})',
                    style: const TextStyle(color: MauSac.kfcRed),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Filter tabs
            _buildFilterTabs(),
            
            // Notification list
            Expanded(
              child: Consumer<NotificationProvider>(
                builder: (context, provider, child) {
                  if (provider.dangTai) {
                    return const Center(
                      child: CircularProgressIndicator(color: MauSac.kfcRed),
                    );
                  }

                  if (provider.loi != null) {
                    return _buildErrorWidget(provider.loi!);
                  }

                  final filteredNotifications = _getFilteredNotifications(provider.danhSachThongBao);

                  if (filteredNotifications.isEmpty) {
                    return _buildEmptyWidget();
                  }

                  return RefreshIndicator(
                    onRefresh: provider.taiDanhSachThongBao,
                    color: MauSac.kfcRed,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredNotifications.length,
                      itemBuilder: (context, index) {
                        final thongBao = filteredNotifications[index];
                        return _buildDeliveryNotificationCard(thongBao, provider);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MauSac.denNhat,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildFilterTab('all', 'Tất cả', Icons.notifications),
          _buildFilterTab('don_hang', 'Đơn hàng', Icons.shopping_bag),
          _buildFilterTab('giao_hang', 'Giao hàng', Icons.local_shipping),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String filter, String label, IconData icon) {
    final isSelected = _selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? MauSac.kfcRed : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? MauSac.trang : MauSac.xam,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? MauSac.trang : MauSac.xam,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ThongBao> _getFilteredNotifications(List<ThongBao> notifications) {
    switch (_selectedFilter) {
      case 'don_hang':
        return notifications.where((tb) => tb.loai == 'don_hang').toList();
      case 'giao_hang':
        return notifications.where((tb) => 
          tb.loai == 'don_hang' && 
          tb.duLieuThem?['status'] != null &&
          ['shipping', 'delivered'].contains(tb.duLieuThem!['status'])
        ).toList();
      default:
        return notifications;
    }
  }

  Widget _buildDeliveryNotificationCard(ThongBao thongBao, NotificationProvider provider) {
    final status = thongBao.duLieuThem?['status'] ?? '';
    final orderId = thongBao.duLieuThem?['donHangId'] ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: thongBao.daDoc ? MauSac.denNhat : MauSac.denNhat.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: thongBao.daDoc 
              ? MauSac.xam.withOpacity(0.2)
              : _getStatusColor(status).withOpacity(0.5),
          width: thongBao.daDoc ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!thongBao.daDoc) {
              provider.danhDauDaDoc(thongBao.id);
            }
            _handleDeliveryNotificationTap(thongBao);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status and time
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getStatusIcon(status),
                        color: _getStatusColor(status),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.cloud_done,
                        color: Colors.blue,
                        size: 10,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(status),
                                  style: const TextStyle(
                                    color: MauSac.trang,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (!thongBao.daDoc)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: MauSac.kfcRed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (orderId.isNotEmpty)
                            Text(
                              'Đơn hàng #${orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId}',
                              style: TextStyle(
                                color: MauSac.xam.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Title
                Text(
                  thongBao.tieuDe,
                  style: TextStyle(
                    color: MauSac.trang,
                    fontSize: 16,
                    fontWeight: thongBao.daDoc 
                        ? FontWeight.w500 
                        : FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Content
                Text(
                  thongBao.noiDung,
                  style: TextStyle(
                    color: MauSac.xam.withOpacity(0.9),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Footer with time and actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: MauSac.xam.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeago.format(thongBao.thoiGian, locale: 'vi'),
                          style: TextStyle(
                            color: MauSac.xam.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    
                    Row(
                      children: [
                        if (status == 'shipping' || status == 'delivered')
                          GestureDetector(
                            onTap: () => _trackOrder(orderId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: MauSac.kfcRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Theo dõi',
                                style: TextStyle(
                                  color: MauSac.kfcRed,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showDeleteDialog(thongBao, provider),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.delete_outline,
                              color: MauSac.xam.withOpacity(0.6),
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: MauSac.denNhat,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              size: 64,
              color: MauSac.xam,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chưa có thông báo giao hàng',
            style: TextStyle(
              color: MauSac.trang,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thông báo sẽ được gửi real-time từ Firebase\nkhi admin cập nhật trạng thái đơn hàng',
            style: TextStyle(
              color: MauSac.xam.withOpacity(0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MauSac.kfcRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: MauSac.kfcRed.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: MauSac.kfcRed,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Đặt hàng để nhận thông báo giao hàng',
                  style: TextStyle(
                    color: MauSac.kfcRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: MauSac.kfcRed,
          ),
          const SizedBox(height: 16),
          const Text(
            'Lỗi tải thông báo',
            style: TextStyle(
              color: MauSac.trang,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: MauSac.xam.withOpacity(0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Provider.of<NotificationProvider>(context, listen: false)
                  .taiDanhSachThongBao();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MauSac.kfcRed,
              foregroundColor: MauSac.trang,
            ),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  // Helper methods for delivery status
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'ĐÃ XÁC NHẬN';
      case 'preparing':
        return 'ĐANG CHUẨN BỊ';
      case 'shipping':
        return 'ĐANG GIAO';
      case 'delivered':
        return 'ĐÃ GIAO';
      case 'cancelled':
        return 'ĐÃ HỦY';
      default:
        return 'CẬP NHẬT';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.restaurant;
      case 'shipping':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return MauSac.vang;
      case 'shipping':
        return MauSac.cam;
      case 'delivered':
        return MauSac.xanhLa;
      case 'cancelled':
        return Colors.red;
      default:
        return MauSac.kfcRed;
    }
  }

  void _handleDeliveryNotificationTap(ThongBao thongBao) {
    // Navigate to order detail or tracking page
    final orderId = thongBao.duLieuThem?['donHangId'];
    if (orderId != null) {
      Navigator.pushNamed(
        context, 
        '/don-hang',
        arguments: {'orderId': orderId},
      );
    }
  }

  void _trackOrder(String orderId) {
    // Navigate to order tracking
    Navigator.pushNamed(
      context, 
      '/don-hang',
      arguments: {'orderId': orderId, 'showTracking': true},
    );
  }

  void _showDeleteDialog(ThongBao thongBao, NotificationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MauSac.denNhat,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xóa thông báo',
          style: TextStyle(color: MauSac.trang),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa thông báo này?',
          style: TextStyle(color: MauSac.xam),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: MauSac.xam)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.xoaThongBao(thongBao.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MauSac.kfcRed,
              foregroundColor: MauSac.trang,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
