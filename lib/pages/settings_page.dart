import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../services/network_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _usernameController = TextEditingController();
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '8080');
  
  NetworkService? _networkService;
  String _localIp = '获取中...';
  bool _isServerRunning = false;
  String _username = '未设置';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 从Provider获取NetworkService实例
    final provider = Provider.of<MedicationProvider>(context, listen: false);
    _networkService = provider.networkService;
    _updateLocalIp();
    _updateServerStatus();
  }

  void _updateServerStatus() {
    setState(() {
      _isServerRunning = _networkService?.isServerRunning ?? false;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '未设置';
      _usernameController.text = _username == '未设置' ? '' : _username;
      // 加载连接信息
      final savedIp = prefs.getString('server_ip');
      final savedPort = prefs.getInt('server_port');
      if (savedIp != null) {
        _ipController.text = savedIp;
      }
      if (savedPort != null) {
        _portController.text = savedPort.toString();
      }
    });
  }

  Future<void> _updateLocalIp() async {
    if (_networkService == null) return;
    final ip = await _networkService!.getLocalIp();
    setState(() {
      _localIp = ip ?? '无法获取';
    });
  }

  Future<void> _saveUsername() async {
    if (_usernameController.text.trim().isEmpty) {
      _showMessage('用户名不能为空');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _usernameController.text.trim());
    
    setState(() {
      _username = _usernameController.text.trim();
    });
    
    _showMessage('用户名已保存');
  }

  Future<void> _startServer() async {
    if (_networkService == null) return;
    final port = int.tryParse(_portController.text) ?? 8080;
    final success = await _networkService!.startServer(port: port);
    
    if (success) {
      setState(() {
        _isServerRunning = true;
        _localIp = _networkService!.localIp;
      });
      _showMessage('服务器启动成功\n其他设备可连接到:\n$_localIp:$port');
    } else {
      _showMessage('服务器启动失败');
    }
  }

  Future<void> _stopServer() async {
    if (_networkService == null) return;
    await _networkService!.stopServer();
    setState(() {
      _isServerRunning = false;
    });
    _showMessage('服务器已停止');
  }

  Future<void> _connectToServer() async {
    if (_networkService == null) return;
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text) ?? 8080;

    if (ip.isEmpty) {
      _showMessage('请输入服务器IP地址');
      return;
    }

    _showMessage('正在连接...');
    final success = await _networkService!.connectToServer(ip, port);
    
    if (success) {
      // 保存连接信息
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_ip', ip);
      await prefs.setInt('server_port', port);
      _showMessage('连接成功！');
    } else {
      _showMessage('连接失败，请检查IP和端口');
    }
  }

  Future<void> _disconnectFromServer() async {
    if (_networkService == null) return;
    await _networkService!.stopServer();
    _showMessage('已断开连接');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 用户名设置
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue.shade600),
                      const SizedBox(width: 10),
                      const Text(
                        '用户设置',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '当前用户名: $_username',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: '新用户名',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.edit),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: _saveUsername,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('保存用户名'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 局域网联机设置
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wifi, color: Colors.green.shade600),
                      const SizedBox(width: 10),
                      const Text(
                        '局域网联机',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // 本机信息
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '本机信息',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('IP地址: $_localIp'),
                        Text('端口: ${_portController.text}'),
                        if (_isServerRunning) ...[
                          Text(
                            '状态: 运行中 (服务器)',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '已连接客户端: ${_networkService?.connectedClientsCount ?? 0}',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else if (_networkService?.isConnectedToServer ?? false) ...[
                          Text(
                            '状态: 已连接到服务器',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '服务器: ${_networkService?.connectedServerInfo ?? ""}',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else
                          Text(
                            '状态: 未连接',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 端口设置
                  TextField(
                    controller: _portController,
                    decoration: InputDecoration(
                      labelText: '端口',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.settings_ethernet),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),

                  // 启动/停止服务器
                  ElevatedButton.icon(
                    onPressed: _isServerRunning ? _stopServer : _startServer,
                    icon: Icon(_isServerRunning ? Icons.stop : Icons.play_arrow),
                    label: Text(_isServerRunning ? '停止服务器' : '启动服务器'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isServerRunning
                          ? Colors.red.shade600
                          : Colors.green.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Divider(),
                  const SizedBox(height: 20),

                  // 连接其他设备
                  const Text(
                    '连接到其他设备',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      labelText: '服务器IP地址',
                      hintText: '例如: 192.168.1.100 或 127.0.0.1',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.computer),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _portController,
                    decoration: InputDecoration(
                      labelText: '服务器端口',
                      hintText: '8080',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.settings_ethernet),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _connectToServer,
                          icon: const Icon(Icons.link),
                          label: const Text('连接'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade600,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _disconnectFromServer,
                          icon: const Icon(Icons.link_off),
                          label: const Text('断开'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 使用说明
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade600),
                      const SizedBox(width: 10),
                      const Text(
                        '使用说明',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    '1. 设置用户名后，其他用户可以看到你的昵称\n\n'
                    '2. 启动服务器后，其他设备可以连接到你\n\n'
                    '3. 要连接其他设备，输入对方的IP地址和端口\n\n'
                    '4. 确保设备在同一局域网内\n\n'
                    '5. 防火墙可能会阻止连接，请允许应用访问网络',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }
}
