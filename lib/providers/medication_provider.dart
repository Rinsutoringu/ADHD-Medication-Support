import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication.dart';
import '../models/dose_record.dart';
import '../services/notification_service.dart';
import '../services/firestore_service.dart';
import '../services/network_service.dart';

class MedicationProvider with ChangeNotifier {
  DoseRecord? _currentDose;
  List<DoseRecord> _history = [];
  List<DoseRecord> _otherUsersData = [];
  Timer? _updateTimer;
  final NotificationService _notificationService;
  final FirestoreService _firestoreService;
  final NetworkService _networkService = NetworkService();

  bool _peakAlertShown = false;
  bool _sleepReminderShown = false;

  MedicationProvider({
    required NotificationService notificationService,
    required FirestoreService firestoreService,
  }) : _notificationService = notificationService,
       _firestoreService = firestoreService {
    _initializeServices();
    _startPeriodicUpdate();
    _loadHistory();
    _subscribeToOtherUsers();
  }

  DoseRecord? get currentDose => _currentDose;
  List<DoseRecord> get history => _history;
  List<DoseRecord> get otherUsersData => _otherUsersData;

  bool get hasDose => _currentDose != null;

  Duration? get timeSinceDose => _currentDose?.timeSinceDose;

  double get currentConcentration => _currentDose?.currentConcentration ?? 0;

  double get currentPercentage => _currentDose?.currentPercentage ?? 0;

  bool get isEffective => _currentDose?.isEffective ?? false;

  Future<void> _initializeServices() async {
    await _notificationService.initialize();
  }

  void _startPeriodicUpdate() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_currentDose != null) {
        _checkAlerts();
        // 更新网络服务中的用药记录（时间会自动更新）
        _networkService.setMyDoseRecord(_currentDose);
        notifyListeners();
      }
    });
  }

  Future<void> _checkAlerts() async {
    if (_currentDose == null) return;

    // 检查峰值警告
    if (!_peakAlertShown && _currentDose!.isAtPeak) {
      await _notificationService.showPeakAlert(
        _currentDose!.medication.name,
        _currentDose!.currentConcentration,
      );
      _peakAlertShown = true;
      _currentDose = _currentDose!.copyWith(peakAlertShown: true);
      await _firestoreService.updateDoseRecord(_currentDose!);
    }

    // 检查睡眠提醒
    if (!_sleepReminderShown && !_currentDose!.isEffective) {
      await _notificationService.showSleepReminder(
        _currentDose!.suggestedSleepTime,
      );
      _sleepReminderShown = true;
      _currentDose = _currentDose!.copyWith(sleepReminderShown: true);
      await _firestoreService.updateDoseRecord(_currentDose!);
    }
  }

  Future<void> takeMedication(Medication medication) async {
    // 获取用户设置的用户名
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    
    final record = DoseRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _firestoreService.currentUserId,
      username: username,
      medication: medication,
      doseTime: DateTime.now(),
    );

    _currentDose = record;
    _history.insert(0, record);
    _peakAlertShown = false;
    _sleepReminderShown = false;

    // 保存到 Firestore
    await _firestoreService.addDoseRecord(record);

    // 推送到网络服务
    _networkService.setMyDoseRecord(record);

    // 安排峰值通知
    await _notificationService.schedulePeakNotification(
      medication.name,
      Duration(
        hours: medication.peakTime.floor(),
        minutes: ((medication.peakTime % 1) * 60).toInt(),
      ),
    );

    notifyListeners();
  }

  Future<void> stopCurrentDose() async {
    if (_currentDose != null) {
      // 保存到历史记录
      try {
        await _firestoreService.addDoseRecord(_currentDose!);
        _history.insert(0, _currentDose!);
        debugPrint('历史记录已保存');
      } catch (e) {
        debugPrint('保存历史记录失败: $e');
      }
      
      // 取消所有通知（忽略平台不支持的错误）
      try {
        await _notificationService.cancelAllNotifications();
      } catch (e) {
        debugPrint('取消通知失败（平台可能不支持）: $e');
      }
    }
    
    _currentDose = null;
    _peakAlertShown = false;
    _sleepReminderShown = false;
    // 清除网络服务中的用药记录
    _networkService.setMyDoseRecord(null);
    notifyListeners();
  }

  Future<void> _loadHistory() async {
    try {
      _history = await _firestoreService.getUserHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('加载历史记录失败: $e');
    }
  }

  void _subscribeToOtherUsers() {
    // 订阅Firestore用户更新（mock数据）
    _firestoreService.subscribeToOtherUsers((records) {
      // 只有在没有网络连接时才使用mock数据
      if (!_networkService.isConnectedToServer && !_networkService.isServerRunning) {
        _otherUsersData = records;
        notifyListeners();
      }
    });

    // 订阅网络服务的实时用户更新
    _networkService.subscribeToNetworkUsers((users) {
      _otherUsersData = users;
      notifyListeners();
    });
  }

  /// 更新网络用户数据（用于局域网联机）
  void updateNetworkUsers(List<DoseRecord> users) {
    _otherUsersData = users;
    notifyListeners();
  }

  /// 获取NetworkService实例（供设置页面使用）
  NetworkService get networkService => _networkService;

  /// 生成图表数据点
  List<ConcentrationPoint> getChartData({int hours = 12}) {
    if (_currentDose == null) return [];

    final points = <ConcentrationPoint>[];
    final medication = _currentDose!.medication;

    // 生成过去和未来的数据点
    for (int minutes = 0; minutes <= hours * 60; minutes += 10) {
      final duration = Duration(minutes: minutes);
      final concentration = medication.concentrationAt(duration);
      points.add(
        ConcentrationPoint(time: duration, concentration: concentration),
      );
    }

    return points;
  }

  /// 删除历史记录
  Future<void> deleteHistory(DoseRecord record) async {
    try {
      _history.remove(record);
      await _firestoreService.deleteDoseRecord(record.id);
      notifyListeners();
      debugPrint('历史记录已删除: ${record.id}');
    } catch (e) {
      debugPrint('删除历史记录失败: $e');
      // 删除失败时重新加载历史记录
      await _loadHistory();
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}

class ConcentrationPoint {
  final Duration time;
  final double concentration;

  ConcentrationPoint({required this.time, required this.concentration});
}
