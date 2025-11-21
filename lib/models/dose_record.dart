import 'medication.dart';

/// 用药记录
class DoseRecord {
  final String id;
  final String userId;
  final String username; // 用户设置的显示名称
  final Medication medication;
  final DateTime doseTime;
  final bool peakAlertShown;
  final bool sleepReminderShown;

  DoseRecord({
    required this.id,
    required this.userId,
    String? username,
    required this.medication,
    required this.doseTime,
    this.peakAlertShown = false,
    this.sleepReminderShown = false,
  }) : username = username ?? '用户$userId';

  /// 获取距离用药的时长
  Duration get timeSinceDose => DateTime.now().difference(doseTime);

  /// 获取当前血药浓度
  double get currentConcentration => medication.concentrationAt(timeSinceDose);

  /// 获取当前浓度百分比
  double get currentPercentage =>
      medication.concentrationPercentageAt(timeSinceDose);

  /// 是否在有效期内
  bool get isEffective => medication.isEffectiveAt(timeSinceDose);

  /// 是否在峰值附近
  bool get isAtPeak => medication.isPeakAt(timeSinceDose);

  /// 是否超过安全浓度
  bool get isToxic => medication.isToxicAt(timeSinceDose);

  /// 计算建议睡眠时间
  DateTime get suggestedSleepTime {
    // 找到浓度降到有效浓度以下的时间
    for (int hours = 1; hours <= 24; hours++) {
      final testTime = Duration(hours: hours);
      if (!medication.isEffectiveAt(testTime)) {
        return doseTime.add(Duration(hours: hours));
      }
    }
    return doseTime.add(Duration(hours: 12)); // 默认12小时后
  }

  DoseRecord copyWith({
    String? id,
    String? userId,
    String? username,
    Medication? medication,
    DateTime? doseTime,
    bool? peakAlertShown,
    bool? sleepReminderShown,
  }) {
    return DoseRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      medication: medication ?? this.medication,
      doseTime: doseTime ?? this.doseTime,
      peakAlertShown: peakAlertShown ?? this.peakAlertShown,
      sleepReminderShown: sleepReminderShown ?? this.sleepReminderShown,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'medication': medication.toJson(),
      'doseTime': doseTime.toIso8601String(),
      'peakAlertShown': peakAlertShown,
      'sleepReminderShown': sleepReminderShown,
    };
  }

  factory DoseRecord.fromJson(Map<String, dynamic> json) {
    return DoseRecord(
      id: json['id'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String?,
      medication: Medication.fromJson(
        json['medication'] as Map<String, dynamic>,
      ),
      doseTime: DateTime.parse(json['doseTime'] as String),
      peakAlertShown: json['peakAlertShown'] as bool? ?? false,
      sleepReminderShown: json['sleepReminderShown'] as bool? ?? false,
    );
  }
}
