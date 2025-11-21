// import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/dose_record.dart';

/// Firestore 服务（无 Firebase 版本 - 仅本地存储）
/// 如需启用联机功能，请取消注释 Firebase 依赖并替换实现
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // 本地存储（临时解决方案）
  final List<DoseRecord> _localRecords = [];

  // 模拟用户ID
  final String currentUserId = 'user_${Random().nextInt(10000)}';

  /// 添加用药记录
  Future<void> addDoseRecord(DoseRecord record) async {
    try {
      _localRecords.add(record);
      print('✅ 用药记录已保存（本地）');
    } catch (e) {
      print('添加用药记录失败: $e');
    }
  }

  /// 更新用药记录
  Future<void> updateDoseRecord(DoseRecord record) async {
    try {
      final index = _localRecords.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _localRecords[index] = record;
      }
    } catch (e) {
      print('更新用药记录失败: $e');
    }
  }

  /// 删除用药记录
  Future<void> deleteDoseRecord(String recordId) async {
    try {
      _localRecords.removeWhere((r) => r.id == recordId);
      print('✅ 用药记录已删除（本地）: $recordId');
    } catch (e) {
      print('删除用药记录失败: $e');
      rethrow;
    }
  }

  /// 获取当前用户的历史记录
  Future<List<DoseRecord>> getUserHistory({int limit = 50}) async {
    try {
      return _localRecords
          .where((r) => r.userId == currentUserId)
          .take(limit)
          .toList();
    } catch (e) {
      print('获取历史记录失败: $e');
      return [];
    }
  }

  /// 订阅其他用户的实时数据（用于联机功能）
  /// 注意：无 Firebase 版本不返回模拟数据，由NetworkService提供实时数据
  void subscribeToOtherUsers(Function(List<DoseRecord>) onData) {
    // 不再生成mock数据，仅保留接口供NetworkService使用
  }

  /// 获取所有活跃用户（最近24小时内用药的）
  Future<List<DoseRecord>> getActiveUsers() async {
    return []; // 不再返回mock数据
  }
}
