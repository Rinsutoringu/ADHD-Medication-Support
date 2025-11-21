# Firebase 配置指南

## 如果需要联机功能，请按以下步骤配置 Firebase

### 步骤 1: 创建 Firebase 项目

1. 访问 [Firebase Console](https://console.firebase.google.com/)
2. 点击"添加项目"
3. 输入项目名称（例如：medication-tracker）
4. 完成项目创建

### 步骤 2: 启用 Cloud Firestore

1. 在 Firebase Console 左侧菜单选择 "Firestore Database"
2. 点击"创建数据库"
3. 选择"测试模式"（开发阶段）
4. 选择服务器位置（建议选择亚洲服务器）

### 步骤 3: 配置 Android

1. 在 Firebase Console 点击"添加应用" -> "Android"
2. 输入包名：`com.example.flutter_application_1`
3. 下载 `google-services.json`
4. 将文件复制到 `android/app/` 目录

5. 编辑 `android/build.gradle.kts`，在 `buildscript` 中添加：
```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

6. 编辑 `android/app/build.gradle.kts`，在文件开头添加：
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // 添加这一行
}
```

### 步骤 4: 配置 iOS（如果需要）

1. 在 Firebase Console 点击"添加应用" -> "iOS"
2. 输入 Bundle ID：`com.example.flutterApplication1`
3. 下载 `GoogleService-Info.plist`
4. 在 Xcode 中打开 `ios/Runner.xcworkspace`
5. 将 `GoogleService-Info.plist` 拖入 Runner 文件夹

### 步骤 5: 启用代码中的 Firebase

在 `lib/main.dart` 中取消注释：

```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();  // 取消注释这一行
  
  runApp(const MyApp());
}
```

### 步骤 6: 设置 Firestore 安全规则

在 Firebase Console 的 Firestore 中，设置以下规则：

#### 开发环境（测试用）：
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

#### 生产环境（推荐）：
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /dose_records/{recordId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null 
                          && request.auth.uid == resource.data.userId;
    }
  }
}
```

## 如果不需要联机功能

如果暂时不需要联机功能，应用仍可正常运行本地功能：
- ✅ 药效监测
- ✅ 峰值警告
- ✅ 睡眠建议
- ❌ 查看其他用户（此功能需要 Firebase）

只需保持 `lib/main.dart` 中的 Firebase 初始化代码为注释状态即可。

## 测试 Firebase 连接

运行应用后，如果 Firebase 配置成功：
1. 点击"开始用药"
2. 选择药物并开始监测
3. 打开 Firebase Console -> Firestore Database
4. 应该能看到 `dose_records` 集合中的新记录

## 常见问题

### Android 构建失败
确保：
- `google-services.json` 在正确的位置
- Gradle 插件已正确配置
- 运行 `flutter clean` 后重新构建

### iOS 构建失败
确保：
- `GoogleService-Info.plist` 已添加到 Xcode 项目
- 在 Xcode 中的文件引用正确
- Bundle ID 匹配

### Firebase 初始化失败
- 检查网络连接
- 确认配置文件正确
- 查看控制台错误日志
