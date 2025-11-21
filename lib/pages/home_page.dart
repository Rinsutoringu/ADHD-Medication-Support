import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/medication_provider.dart';
import '../models/medication.dart';
import 'settings_page.dart';
import 'history_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('专注达药效监测'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const SettingsPage(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);
                    return SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            tooltip: '设置',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.purple.shade50],
          ),
        ),
        child: SafeArea(
          child: Consumer<MedicationProvider>(
            builder: (context, provider, child) {
              if (!provider.hasDose) {
                return _buildStartScreen(context, provider);
              }
              return _buildMonitoringScreen(context, provider);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStartScreen(BuildContext context, MedicationProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication, size: 100, color: Colors.blue.shade300),
          const SizedBox(height: 30),
          Text(
            '专注达药效监测',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '科学追踪，专注每一刻',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 60),
          ElevatedButton(
            onPressed: () => _showMedicationSelector(context, provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5,
            ),
            child: const Text(
              '开始用药',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const HistoryPage(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;
                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));
                        var offsetAnimation = animation.drive(tween);
                        return SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                },
                icon: const Icon(Icons.history),
                label: const Text('用药历史'),
                style: TextButton.styleFrom(foregroundColor: Colors.blue.shade700),
              ),
              const SizedBox(width: 20),
              TextButton.icon(
                onPressed: () => _showOtherUsers(context, provider),
                icon: const Icon(Icons.people),
                label: const Text('在线用户'),
                style: TextButton.styleFrom(foregroundColor: Colors.blue.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringScreen(
    BuildContext context,
    MedicationProvider provider,
  ) {
    final dose = provider.currentDose!;
    final timeSince = provider.timeSinceDose!;
    final hours = timeSince.inHours;
    final minutes = timeSince.inMinutes % 60;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 头部信息
            _buildHeader(context, provider, dose.medication.name),
            const SizedBox(height: 20),

            // 时间显示
            _buildTimeCard(hours, minutes),
            const SizedBox(height: 20),

            // 浓度显示
            _buildConcentrationCard(provider),
            const SizedBox(height: 20),

            // 曲线图
            _buildChart(provider),
            const SizedBox(height: 20),

            // 状态指示器
            _buildStatusIndicators(provider),
            const SizedBox(height: 20),

            // 操作按钮
            _buildActionButtons(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    MedicationProvider provider,
    String medicationName,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.medication, size: 40, color: Colors.blue.shade600),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicationName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '正在监测中...',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showOtherUsers(context, provider),
              icon: const Icon(Icons.people),
              color: Colors.blue.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(int hours, int minutes) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Text(
              '已用药时间',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  hours.toString(),
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '小时',
                  style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 20),
                Text(
                  minutes.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '分钟',
                  style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConcentrationCard(MedicationProvider provider) {
    final concentration = provider.currentConcentration;
    final percentage = provider.currentPercentage;

    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Text(
              '当前血药浓度',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  concentration.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _getConcentrationColor(percentage),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'mg/L',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 15),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getConcentrationColor(percentage),
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 10),
            Text(
              '${percentage.toStringAsFixed(1)}% 峰值',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(MedicationProvider provider) {
    final chartData = provider.getChartData(hours: 12);
    if (chartData.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = chartData.map((point) {
      return FlSpot(point.time.inMinutes / 60.0, point.concentration);
    }).toList();

    final maxY = chartData
        .map((p) => p.concentration)
        .reduce((a, b) => a > b ? a : b);

    // 计算当前已经过的时间（小时）
    final currentHours = (provider.currentDose?.timeSinceDose.inMinutes ?? 0) / 60.0;
    final doseTime = provider.currentDose?.doseTime ?? DateTime.now();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '血药浓度曲线',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: maxY / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 2,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}h',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  minX: 0,
                  maxX: 12,
                  minY: 0,
                  maxY: maxY * 1.1,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => Colors.blueGrey.withOpacity(0.9),
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.all(8),
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          final hours = spot.x;
                          final minutes = (hours * 60).round();
                          final targetTime = doseTime.add(Duration(minutes: minutes));
                          final timeStr = DateFormat('HH:mm').format(targetTime);
                          final concentration = spot.y.toStringAsFixed(2);
                          
                          return LineTooltipItem(
                            '时间: $timeStr\n浓度: $concentration mg/L',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    touchCallback: (FlTouchEvent event, LineTouchResponse? response) {},
                    handleBuiltInTouches: true,
                  ),
                  lineBarsData: [
                    // 已消耗时间部分（高亮显示）
                    if (currentHours > 0)
                      LineChartBarData(
                        spots: spots.where((s) => s.x <= currentHours).toList(),
                        isCurved: true,
                        color: Colors.blue.shade600,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.shade300.withOpacity(0.5),
                        ),
                      ),
                    // 未来时间部分（半透明显示）
                    LineChartBarData(
                      spots: spots.where((s) => s.x >= currentHours).toList(),
                      isCurved: true,
                      color: Colors.blue.shade600.withOpacity(0.4),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.shade100.withOpacity(0.2),
                      ),
                    ),
                    // 当前时间点标记
                    if (currentHours > 0 && currentHours <= 12)
                      LineChartBarData(
                        spots: [
                          FlSpot(
                            currentHours,
                            provider.currentDose?.currentConcentration ?? 0,
                          ),
                        ],
                        isCurved: false,
                        color: Colors.transparent,
                        barWidth: 0,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 6,
                              color: Colors.red.shade600,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicators(MedicationProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            '有效期',
            provider.isEffective ? '进行中' : '已结束',
            provider.isEffective ? Colors.green : Colors.grey,
            provider.isEffective ? Icons.check_circle : Icons.cancel,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatusCard(
            '峰值',
            provider.currentDose!.isAtPeak ? '已达到' : '未达到',
            provider.currentDose!.isAtPeak
                ? Colors.orange
                : Colors.blue.shade300,
            Icons.trending_up,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    MedicationProvider provider,
  ) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showSleepAdvice(context, provider),
            icon: const Icon(Icons.bedtime),
            label: const Text('睡眠建议'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _confirmStop(context, provider),
            icon: const Icon(Icons.stop),
            label: const Text('结束监测'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getConcentrationColor(double percentage) {
    if (percentage >= 80) return Colors.orange.shade600;
    if (percentage >= 50) return Colors.green.shade600;
    if (percentage >= 20) return Colors.blue.shade600;
    return Colors.grey.shade600;
  }

  void _showMedicationSelector(
    BuildContext context,
    MedicationProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '选择药物',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildMedicationOption(
              context,
              provider,
              Medication.methylphenidate(),
              '适用于注意力缺陷/多动障碍(ADHD)',
            ),
            const SizedBox(height: 10),
            _buildMedicationOption(
              context,
              provider,
              Medication.atomoxetine(),
              '非刺激性药物，适合长期使用',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationOption(
    BuildContext context,
    MedicationProvider provider,
    Medication medication,
    String description,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(Icons.medication, color: Colors.blue.shade600),
        title: Text(
          medication.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.pop(context);
          provider.takeMedication(medication);
        },
      ),
    );
  }

  void _showSleepAdvice(BuildContext context, MedicationProvider provider) {
    final suggestedTime = provider.currentDose!.suggestedSleepTime;
    final timeStr =
        '${suggestedTime.hour.toString().padLeft(2, '0')}:'
        '${suggestedTime.minute.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.bedtime, color: Colors.purple),
            SizedBox(width: 10),
            Text('睡眠建议'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基于当前药物代谢情况，建议您在以下时间入睡：',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 15),
            Center(
              child: Text(
                timeStr,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade600,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              '此时药效基本结束，大脑可以进入良好的休息状态。',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  void _confirmStop(BuildContext context, MedicationProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('确认结束'),
        content: const Text('确定要结束当前的药效监测吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.stopCurrentDose();
              Navigator.pop(context);
              // 停止后显示返回主菜单的确认对话框
              _showStopSuccessDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showStopSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
            const SizedBox(width: 10),
            const Text('监测已结束'),
          ],
        ),
        content: const Text('药效监测已成功停止，数据已保存到历史记录中。'),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // 关闭对话框，自动返回到已无currentDose的主界面
            },
            icon: const Icon(Icons.home),
            label: const Text('返回主菜单'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showOtherUsers(BuildContext context, MedicationProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '在线用户',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  '查看其他人的用药周期',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: provider.otherUsersData.isEmpty
                      ? Center(
                          child: Text(
                            '暂无其他在线用户',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: provider.otherUsersData.length,
                          itemBuilder: (context, index) {
                            final record = provider.otherUsersData[index];
                            final timeSince = DateTime.now().difference(
                              record.doseTime,
                            );
                            final hours = timeSince.inHours;
                            final minutes = timeSince.inMinutes % 60;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    record.userId.substring(
                                      record.userId.length - 2,
                                    ),
                                    style: TextStyle(
                                      color: Colors.blue.shade900,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(record.medication.name),
                                subtitle: Text(
                                  '已用药 ${hours}h ${minutes}m',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: record.isEffective
                                        ? Colors.green.shade100
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    record.isEffective ? '有效期' : '已结束',
                                    style: TextStyle(
                                      color: record.isEffective
                                          ? Colors.green.shade900
                                          : Colors.grey.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
