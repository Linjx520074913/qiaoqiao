# KAPI App

账单识别系统 Flutter 移动应用

## 状态

🚧 开发中...

## 计划功能

- 📷 拍照扫描账单
- 📁 从相册选择图片
- 🔍 实时识别显示
- 📊 历史记录管理
- 💾 本地数据存储
- 🌐 与后端API交互

## 技术栈

- Flutter
- Dart
- Provider / Riverpod（状态管理）
- Dio（网络请求）
- Camera Plugin（相机）
- Image Picker（相册）

## 开发计划

1. **Phase 1**: 基础UI框架
2. **Phase 2**: 相机和相册功能
3. **Phase 3**: API集成
4. **Phase 4**: 数据管理
5. **Phase 5**: 优化和测试

## 创建Flutter项目

```bash
cd app
flutter create .
flutter pub get
```

## API配置

在 `lib/config/api_config.dart` 中配置后端地址：
```dart
const String API_BASE_URL = 'http://localhost:8080';
```

## 运行

```bash
flutter run
```

## 注意事项

- iOS需要配置相机权限（Info.plist）
- Android需要配置相机和存储权限（AndroidManifest.xml）
- 确保后端服务已启动
