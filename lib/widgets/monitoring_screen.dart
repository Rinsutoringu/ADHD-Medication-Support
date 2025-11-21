import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/medication_provider.dart';
import '../widgets/concentration_chart.dart';

/// 监测界面 - 用药期间显示
class MonitoringScreen extends StatefulWidget {
  final VoidCallback onStop;

  const MonitoringScreen({
    Key? key,
    required this.onStop,
  }) : super(key: key);

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // 每秒刷新UI以更新时间显示和状态
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationProvider>(
      builder: (context, provider, child) {
        final dose = provider.currentDose!;
        final timeSince = provider.timeSinceDose!;
        final hours = timeSince.inHours;
        final minutes = timeSince.inMinutes % 60;
        final hasOnlineUsers = provider.otherUsersData.isNotEmpty;

        return Row(
          children: [
            // 主监测区域
            Expanded(
              flex: hasOnlineUsers ? 3 : 1,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context, provider, dose.medication.name),
                      const SizedBox(height: 20),
                      _buildTimeCard(hours, minutes),
                      const SizedBox(height: 20),
                      _buildConcentrationCard(provider),
                      const SizedBox(height: 20),
                      ConcentrationChart(provider: provider),
                      const SizedBox(height: 20),
                      _buildStatusIndicators(provider),
                      const SizedBox(height: 20),
                      _buildActionButtons(context, provider),
                    ],
                  ),
                ),
              ),
            ),
            // 在线用户侧边栏
            if (hasOnlineUsers)
              Container(
                width: 300,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  color: Colors.grey.shade50,
                ),
                child: _buildOnlineUsersSidebar(provider),
              ),
          ],
        );
      },
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

  Widget _buildStatusIndicators(MedicationProvider provider) {
    // 判断当前状态：未到有效期、有效期中、已结束
    final currentConc = provider.currentConcentration;
    final effectiveConc = provider.currentDose!.medication.effectiveConcentration;
    final timeSinceStart = provider.timeSinceDose!.inMinutes / 60.0;
    final peakTime = provider.currentDose!.medication.peakTime;
    
    String effectStatus;
    Color effectColor;
    IconData effectIcon;
    
    if (provider.isEffective) {
      // 当前在有效期
      effectStatus = '有效期中';
      effectColor = Colors.green;
      effectIcon = Icons.check_circle;
    } else if (timeSinceStart < peakTime && currentConc < effectiveConc) {
      // 还未到有效期（浓度未达到有效浓度且未过峰值时间）
      effectStatus = '未到有效期';
      effectColor = Colors.orange;
      effectIcon = Icons.hourglass_top;
    } else {
      // 已结束
      effectStatus = '已结束';
      effectColor = Colors.grey;
      effectIcon = Icons.cancel;
    }
    
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            '有效期',
            effectStatus,
            effectColor,
            effectIcon,
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
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onStop,
            icon: const Icon(Icons.stop),
            label: const Text('结束监测'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '建议睡眠时间: ${DateFormat('HH:mm').format(provider.currentDose!.suggestedSleepTime)}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineUsersSidebar(MedicationProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.shade600,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    '在线用户',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                '${provider.otherUsersData.length} 人在线',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: provider.otherUsersData.length,
            itemBuilder: (context, index) {
              final record = provider.otherUsersData[index];
              final timeSince = DateTime.now().difference(record.doseTime);
              final hours = timeSince.inHours;
              final minutes = timeSince.inMinutes % 60;
              final concentration = record.currentConcentration;
              final percentage = record.currentPercentage;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            radius: 20,
                            child: Text(
                              record.userId.substring(
                                record.userId.length >= 2
                                    ? record.userId.length - 2
                                    : 0,
                              ),
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.username,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  record.medication.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${hours}h ${minutes}m',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getConcentrationColor(percentage),
                        ),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${concentration.toStringAsFixed(2)} mg/L',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: record.isEffective
                                  ? Colors.green.shade100
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              record.isEffective ? '有效期' : '已结束',
                              style: TextStyle(
                                fontSize: 11,
                                color: record.isEffective
                                    ? Colors.green.shade700
                                    : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getConcentrationColor(double percentage) {
    if (percentage > 80) return Colors.red.shade600;
    if (percentage > 60) return Colors.orange.shade600;
    if (percentage > 40) return Colors.green.shade600;
    if (percentage > 20) return Colors.blue.shade600;
    return Colors.grey.shade600;
  }
}
