import 'package:flutter/material.dart';
import '../models/thong_bao.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<ThongBao> _danhSachThongBao = [];
  bool _dangTai = false;
  String? _loi;

  List<ThongBao> get danhSachThongBao => _danhSachThongBao;
  bool get dangTai => _dangTai;
  String? get loi => _loi;

  // Lấy số lượng thông báo chưa đọc
  int get soThongBaoChuaDoc {
    return _danhSachThongBao.where((tb) => !tb.daDoc).length;
  }

  // Lấy thông báo mới nhất chưa đọc
  List<ThongBao> get thongBaoChuaDoc {
    return _danhSachThongBao.where((tb) => !tb.daDoc).toList();
  }

  // Khởi tạo và lắng nghe thông báo real-time
  void initialize() {
    _listenToNotifications();
  }

  void _listenToNotifications() {
    NotificationService.streamUserNotifications().listen(
      (danhSach) {
        _danhSachThongBao = danhSach;
        _dangTai = false;
        _loi = null;
        notifyListeners();
      },
      onError: (error) {
        _loi = error.toString();
        _dangTai = false;
        notifyListeners();
      },
    );
  }

  // Tải danh sách thông báo
  Future<void> taiDanhSachThongBao() async {
    _dangTai = true;
    _loi = null;
    notifyListeners();

    try {
      _danhSachThongBao = await NotificationService.getUserNotifications();
      _dangTai = false;
      notifyListeners();
    } catch (e) {
      _loi = e.toString();
      _dangTai = false;
      notifyListeners();
    }
  }

  // Đánh dấu thông báo đã đọc
  Future<void> danhDauDaDoc(String notificationId) async {
    try {
      await NotificationService.markAsRead(notificationId);
      
      // Cập nhật local state
      final index = _danhSachThongBao.indexWhere((tb) => tb.id == notificationId);
      if (index != -1) {
        _danhSachThongBao[index] = _danhSachThongBao[index].copyWith(daDoc: true);
        notifyListeners();
      }
    } catch (e) {
      print('Lỗi khi đánh dấu đã đọc: $e');
    }
  }

  // Đánh dấu tất cả đã đọc
  Future<void> danhDauTatCaDaDoc() async {
    try {
      final chuaDoc = thongBaoChuaDoc;
      for (final thongBao in chuaDoc) {
        await NotificationService.markAsRead(thongBao.id);
      }
      
      // Cập nhật local state
      _danhSachThongBao = _danhSachThongBao.map((tb) => 
          tb.copyWith(daDoc: true)).toList();
      notifyListeners();
    } catch (e) {
      print('Lỗi khi đánh dấu tất cả đã đọc: $e');
    }
  }

  // Xóa thông báo
  Future<void> xoaThongBao(String notificationId) async {
    try {
      await NotificationService.deleteNotification(notificationId);
      
      // Cập nhật local state
      _danhSachThongBao.removeWhere((tb) => tb.id == notificationId);
      notifyListeners();
    } catch (e) {
      print('Lỗi khi xóa thông báo: $e');
    }
  }

  // Thêm thông báo mới (cho testing)
  void themThongBaoMoi(ThongBao thongBao) {
    _danhSachThongBao.insert(0, thongBao);
    notifyListeners();
    
    // Hiển thị local notification
    NotificationService.sendLocalNotification(
      title: thongBao.tieuDe,
      body: thongBao.noiDung,
    );
  }

  // Lọc thông báo theo loại
  List<ThongBao> layThongBaoTheoLoai(String loai) {
    return _danhSachThongBao.where((tb) => tb.loai == loai).toList();
  }

  // Reset provider
  void reset() {
    _danhSachThongBao = [];
    _dangTai = false;
    _loi = null;
    notifyListeners();
  }
}
