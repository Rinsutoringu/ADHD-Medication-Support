import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/dose_record.dart';

/// 局域网联机服务
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  HttpServer? _server;
  final List<DoseRecord> _networkUsers = [];
  Function(List<DoseRecord>)? _onDataCallback;
  Timer? _broadcastTimer;
  DoseRecord? _myDoseRecord;
  String _connectedServerIp = '';
  int _connectedServerPort = 0;

  String? _localIp;
  int _port = 8080;

  String get localIp => _localIp ?? '未获取';
  int get port => _port;
  bool get isServerRunning => _server != null;
  bool get isConnectedToServer => _connectedServerIp.isNotEmpty;

  /// 设置本机的用药记录
  void setMyDoseRecord(DoseRecord? record) {
    _myDoseRecord = record;
    if (record != null && _connectedServerIp.isNotEmpty) {
      pushData(_connectedServerIp, _connectedServerPort, record);
    }
  }

  /// 获取本机局域网IP
  Future<String?> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          // 优先选择192.168开头的地址
          if (addr.address.startsWith('192.168')) {
            _localIp = addr.address;
            return _localIp;
          }
        }
      }

      // 如果没有192.168的，选择其他私有地址
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.address.startsWith('10.') ||
              addr.address.startsWith('172.')) {
            _localIp = addr.address;
            return _localIp;
          }
        }
      }
    } catch (e) {
      debugPrint('获取本地IP失败: $e');
    }
    return null;
  }

  /// 启动HTTP服务器
  Future<bool> startServer({int port = 8080}) async {
    if (_server != null) {
      debugPrint('服务器已在运行');
      return true;
    }

    try {
      _port = port;
      await getLocalIp();

      // 绑定到所有IPv4地址，允许外部访问
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port, shared: true);
      debugPrint('✅ 服务器启动成功: $_localIp:$port (监听所有网卡)');

      _server!.listen((HttpRequest request) async {
        _handleRequest(request);
      });

      // 启动定期广播（如果有用药记录）
      _startBroadcast();

      return true;
    } catch (e) {
      debugPrint('启动服务器失败: $e');
      return false;
    }
  }

  /// 处理HTTP请求
  void _handleRequest(HttpRequest request) async {
    // 设置CORS头
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers
        .add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    try {
      if (request.uri.path == '/users' && request.method == 'GET') {
        // 获取所有用户（包括服务器自己）
        final allUsers = <DoseRecord>[];
        // 添加服务器自己的用药记录
        if (_myDoseRecord != null) {
          allUsers.add(_myDoseRecord!);
        }
        // 添加客户端的记录
        allUsers.addAll(_networkUsers);
        
        final response = jsonEncode({
          'users': allUsers.map((r) => r.toJson()).toList(),
        });
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(response);
      } else if (request.uri.path == '/update' && request.method == 'POST') {
        // 更新用户数据
        final content = await utf8.decoder.bind(request).join();
        final data = jsonDecode(content);
        final record = DoseRecord.fromJson(data);

        // 更新或添加
        final index = _networkUsers.indexWhere((r) => r.userId == record.userId);
        if (index != -1) {
          _networkUsers[index] = record;
        } else {
          _networkUsers.add(record);
        }

        // 通知监听器
        _onDataCallback?.call(_networkUsers);

        request.response
          ..statusCode = HttpStatus.ok
          ..write('OK');
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
    } catch (e) {
      debugPrint('处理请求失败: $e');
      request.response.statusCode = HttpStatus.internalServerError;
    }

    await request.response.close();
  }

  /// 连接到其他设备
  Future<bool> connectToServer(String ip, int port) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(Uri.parse('http://$ip:$port/users'));
      final response = await request.close().timeout(const Duration(seconds: 5));

      if (response.statusCode == HttpStatus.ok) {
        final content = await utf8.decoder.bind(response).join();
        final data = jsonDecode(content);
        // 过滤掉本机用户，避免重复显示
        final users = (data['users'] as List)
            .map((json) => DoseRecord.fromJson(json))
            .where((record) => _myDoseRecord == null || record.userId != _myDoseRecord!.userId)
            .toList();

        _networkUsers.clear();
        _networkUsers.addAll(users);
        _onDataCallback?.call(_networkUsers);

        // 保存服务器信息
        _connectedServerIp = ip;
        _connectedServerPort = port;

        // 启动定期获取和推送
        _startBroadcast();

        // 如果有用药记录，立即推送
        if (_myDoseRecord != null) {
          await pushData(ip, port, _myDoseRecord!);
        }

        debugPrint('✅ 成功连接到 $ip:$port');
        return true;
      }
    } catch (e) {
      debugPrint('连接服务器失败: $e');
    }
    return false;
  }

  /// 向服务器推送自己的数据
  Future<bool> pushData(String serverIp, int serverPort, DoseRecord record) async {
    try {
      final client = HttpClient();
      final request = await client.postUrl(
        Uri.parse('http://$serverIp:$serverPort/update'),
      );
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(record.toJson()));

      final response = await request.close();
      return response.statusCode == HttpStatus.ok;
    } catch (e) {
      debugPrint('推送数据失败: $e');
      return false;
    }
  }

  /// 订阅网络用户更新
  void subscribeToNetworkUsers(Function(List<DoseRecord>) onData) {
    _onDataCallback = onData;
  }

  /// 启动定期广播
  void _startBroadcast() {
    _broadcastTimer?.cancel();
    _broadcastTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      // 如果连接到服务器，定期获取数据
      if (_connectedServerIp.isNotEmpty) {
        await _fetchUsers(_connectedServerIp, _connectedServerPort);
        // 推送本机数据
        if (_myDoseRecord != null) {
          await pushData(_connectedServerIp, _connectedServerPort, _myDoseRecord!);
        }
      }
    });
  }

  /// 获取用户列表
  Future<void> _fetchUsers(String ip, int port) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('http://$ip:$port/users'));
      final response = await request.close();

      if (response.statusCode == HttpStatus.ok) {
        final content = await utf8.decoder.bind(response).join();
        final data = jsonDecode(content);
        // 过滤掉本机用户，避免重复显示
        final users = (data['users'] as List)
            .map((json) => DoseRecord.fromJson(json))
            .where((record) => _myDoseRecord == null || record.userId != _myDoseRecord!.userId)
            .toList();

        _networkUsers.clear();
        _networkUsers.addAll(users);
        _onDataCallback?.call(_networkUsers);
      }
    } catch (e) {
      debugPrint('获取用户列表失败: $e');
    }
  }

  /// 停止服务器
  Future<void> stopServer() async {
    _broadcastTimer?.cancel();
    await _server?.close();
    _server = null;
    _networkUsers.clear();
    _connectedServerIp = '';
    _connectedServerPort = 0;
    debugPrint('服务器已停止');
  }

  /// 获取当前网络用户
  List<DoseRecord> getNetworkUsers() => _networkUsers;

  /// 获取已连接的客户端数量（作为服务器时）
  int get connectedClientsCount => _networkUsers.length;

  /// 获取连接的服务器信息（作为客户端时）
  String get connectedServerInfo => 
      _connectedServerIp.isNotEmpty ? '$_connectedServerIp:$_connectedServerPort' : '';
}
