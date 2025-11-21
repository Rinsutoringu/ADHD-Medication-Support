import 'dart:math';

/// 药物模型
class Medication {
  final String id;
  final String name;
  final double dose; // 剂量（mg）
  final double absorptionRate; // 吸收速率常数（h^-1）
  final double eliminationHalfLife; // 消除半衰期（小时）
  final double peakTime; // 达峰时间（小时）
  final double effectiveConcentration; // 有效浓度阈值（mg/L）
  final double toxicConcentration; // 中毒浓度（mg/L）
  final double volumeOfDistribution; // 表观分布容积（L）

  Medication({
    required this.id,
    required this.name,
    required this.dose,
    this.absorptionRate = 1.5,
    this.eliminationHalfLife = 4.0,
    this.peakTime = 1.5,
    this.effectiveConcentration = 10.0,
    this.toxicConcentration = 50.0,
    this.volumeOfDistribution = 50.0,
  });

  /// 计算消除速率常数
  double get eliminationRate => 0.693 / eliminationHalfLife;

  /// 计算最大血药浓度 (Cmax)
  double get maxConcentration {
    // 专注达使用双室模型，需要搜索峰值
    if (id == 'mph') {
      double maxC = 0;
      // 在0-12小时内搜索峰值（以0.1小时为步长）
      for (double t = 0; t <= 12; t += 0.1) {
        final c = concentrationAt(Duration(minutes: (t * 60).round()));
        if (c > maxC) maxC = c;
      }
      return maxC;
    }
    
    // 其他药物使用单室模型公式
    return (dose / volumeOfDistribution) *
        (absorptionRate / (absorptionRate - eliminationRate)) *
        (exp(-eliminationRate * peakTime) - exp(-absorptionRate * peakTime));
  }

  /// 计算给定时间点的血药浓度（单室模型）
  double concentrationAt(Duration timeSinceDose) {
    final t = timeSinceDose.inMinutes / 60.0; // 转换为小时

    if (t < 0) return 0;

    // 专注达使用特殊的双室模型公式
    if (id == 'mph') {
      // C(t) = 20·(e^(-0.8t) - e^(-2.0t)) + 120·(e^(-0.15t) - e^(-0.2t))
      final fastRelease = 20 * (exp(-0.8 * t) - exp(-2.0 * t));
      final slowRelease = 120 * (exp(-0.15 * t) - exp(-0.2 * t));
      return max(0, fastRelease + slowRelease);
    }

    // 其他药物使用单室模型：C(t) = (D/Vd) * (ka/(ka-ke)) * (e^(-ke*t) - e^(-ka*t))
    final ka = absorptionRate;
    final ke = eliminationRate;
    final D = dose;
    final Vd = volumeOfDistribution;

    if (ka == ke) {
      // 特殊情况：ka = ke
      return (D / Vd) * ka * t * exp(-ke * t);
    }

    final concentration =
        (D / Vd) * (ka / (ka - ke)) * (exp(-ke * t) - exp(-ka * t));

    return max(0, concentration);
  }

  /// 计算浓度百分比（相对于峰值浓度）
  double concentrationPercentageAt(Duration timeSinceDose) {
    final current = concentrationAt(timeSinceDose);
    final max = maxConcentration;
    return max > 0 ? (current / max) * 100 : 0;
  }

  /// 判断当前是否在有效浓度范围内
  bool isEffectiveAt(Duration timeSinceDose) {
    return concentrationAt(timeSinceDose) >= effectiveConcentration;
  }

  /// 判断当前是否达到峰值
  bool isPeakAt(Duration timeSinceDose) {
    final t = timeSinceDose.inMinutes / 60.0;
    return (t - peakTime).abs() < 0.1; // 峰值前后6分钟
  }

  /// 判断当前是否超过安全浓度
  bool isToxicAt(Duration timeSinceDose) {
    return concentrationAt(timeSinceDose) >= toxicConcentration;
  }

  /// 预定义的药物模板
  static Medication methylphenidate() {
    return Medication(
      id: 'mph',
      name: '哌醋甲酯（专注达）',
      dose: 18.0,
      absorptionRate: 1.2, // 用于其他计算（双室模型直接使用公式）
      eliminationHalfLife: 2.5, // 用于其他计算
      peakTime: 2.0, // 峰值时间约2小时
      effectiveConcentration: 10.0, // 双室模型的有效浓度阈值（mg/L）
      toxicConcentration: 150.0, // 双室模型的中毒浓度阈值（mg/L）
      volumeOfDistribution: 200.0, // 分布容积（用于其他计算）
    );
  }

  static Medication atomoxetine() {
    return Medication(
      id: 'atx',
      name: '托莫西汀',
      dose: 40.0,
      absorptionRate: 0.8,
      eliminationHalfLife: 5.2,
      peakTime: 2.0,
      effectiveConcentration: 200.0,
      toxicConcentration: 1000.0,
      volumeOfDistribution: 63.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dose': dose,
      'absorptionRate': absorptionRate,
      'eliminationHalfLife': eliminationHalfLife,
      'peakTime': peakTime,
      'effectiveConcentration': effectiveConcentration,
      'toxicConcentration': toxicConcentration,
      'volumeOfDistribution': volumeOfDistribution,
    };
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      name: json['name'] as String,
      dose: (json['dose'] as num).toDouble(),
      absorptionRate: (json['absorptionRate'] as num).toDouble(),
      eliminationHalfLife: (json['eliminationHalfLife'] as num).toDouble(),
      peakTime: (json['peakTime'] as num).toDouble(),
      effectiveConcentration: (json['effectiveConcentration'] as num)
          .toDouble(),
      toxicConcentration: (json['toxicConcentration'] as num).toDouble(),
      volumeOfDistribution: (json['volumeOfDistribution'] as num).toDouble(),
    );
  }
}
