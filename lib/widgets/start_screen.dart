import 'package:flutter/material.dart';

/// 开始界面 - 未开始用药时显示
class StartScreen extends StatelessWidget {
  final VoidCallback onStartMedication;
  final VoidCallback onViewHistory;
  final VoidCallback onViewOnlineUsers;

  const StartScreen({
    Key? key,
    required this.onStartMedication,
    required this.onViewHistory,
    required this.onViewOnlineUsers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            onPressed: onStartMedication,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
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
                onPressed: onViewHistory,
                icon: const Icon(Icons.history),
                label: const Text('用药历史'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 20),
              TextButton.icon(
                onPressed: onViewOnlineUsers,
                icon: const Icon(Icons.people),
                label: const Text('在线用户'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
