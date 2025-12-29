# Intents UI Extension 配置指南

## 已完成的准备工作

✅ 已创建 `ShowExpenseIntentUI` 文件夹及所有必要文件：
- `IntentViewController.swift` - 主视图控制器（含动画和数据监听）
- `Info.plist` - Extension 配置
- `MainInterface.storyboard` - UI 界面
- `ShowExpenseIntentUI.entitlements` - App Group 权限配置

✅ 已修改 `ShowExpenseIntent.swift`：
- `openAppWhenRun = false` - 不打开 App
- 添加 App Group 数据共享逻辑
- 添加 3 秒模拟识别任务

## 需要在 Xcode 中手动完成的步骤

### 方法 1：通过 Xcode 添加 Target（推荐）

1. **打开 Xcode 项目**
   ```bash
   open /Users/linjx/Desktop/kapi/AppIntent/AppIntent.xcodeproj
   ```

2. **添加新 Target**
   - File → New → Target...
   - 选择 **Intents UI Extension**
   - Product Name: `ShowExpenseIntentUI`
   - Language: Swift
   - 点击 Finish

3. **删除自动生成的文件**
   - Xcode 会自动创建一些文件，删除它们
   - 我们使用已经准备好的文件

4. **添加已准备好的文件到 Target**
   - 在项目导航器中，选中 `ShowExpenseIntentUI` 文件夹
   - 右键 → Add Files to "AppIntent"...
   - 选择 `/Users/linjx/Desktop/kapi/AppIntent/ShowExpenseIntentUI` 文件夹
   - **重要**：勾选 "Copy items if needed"
   - **重要**：在 "Add to targets" 中勾选 `ShowExpenseIntentUI`

5. **配置 Target Settings**
   - 选择项目 → 选择 `ShowExpenseIntentUI` target
   - **General** 标签页：
     - Bundle Identifier: `com.dm.AppIntent.ShowExpenseIntentUI`（或您的 Bundle ID）
     - Deployment Target: iOS 16.0 或更高

   - **Signing & Capabilities** 标签页：
     - 启用 Automatic Signing
     - 添加 **App Groups** capability
     - 勾选 `group.com.dm.AppIntent`

   - **Build Settings** 标签页：
     - 搜索 "Code Signing Entitlements"
     - 设置为：`ShowExpenseIntentUI/ShowExpenseIntentUI.entitlements`

6. **配置 Info.plist**
   - 确保 `ShowExpenseIntentUI/Info.plist` 中的 `IntentsSupported` 包含 `ShowExpenseIntent`
   - （已在文件中配置好）

7. **链接 IntentsUI 框架**
   - 选择 `ShowExpenseIntentUI` target
   - Build Phases → Link Binary With Libraries
   - 添加 `IntentsUI.framework`

### 方法 2：使用现有文件快速配置

如果 Xcode 创建的 target 已经存在，只需：

1. 替换自动生成的文件：
   ```bash
   # 假设 Xcode 创建的目录是 ShowExpenseIntentUI
   # 确认文件已在正确位置，无需额外操作
   ```

2. 在 Xcode 中刷新项目：
   - 右键项目根目录 → "Add Files to..."
   - 选择 `ShowExpenseIntentUI` 文件夹
   - 确保添加到正确的 target

## 核心实现说明

### 1. Intent 执行流程

```swift
ShowExpenseIntent.perform() {
    1. 设置共享数据状态 = "analyzing"
    2. 立即返回（Intent 结束）
    3. 启动后台 Task：
       - 等待 3 秒
       - 更新共享数据状态 = "success"
       - 写入识别结果
}
```

### 2. UI Extension 显示流程

```swift
IntentViewController {
    1. 系统启动 UI Extension
    2. 显示"分析中..."（带点点动画）
    3. 每 0.3 秒检查共享数据
    4. 检测到 status = "success"
    5. 更新界面显示结果
    6. UI 保持显示直到用户关闭
}
```

### 3. App Group 数据格式

```
group.com.dm.AppIntent (UserDefaults)
├── expense_status: "analyzing" | "success" | "error"
├── expense_merchant: String (商家名称)
├── expense_amount: Double (金额)
└── expense_error: String (错误信息)
```

### 4. 关键点

- ✅ **UI 生命周期 > Intent return**
  Intent 返回后，UI Extension 继续运行并监听数据变化

- ✅ **不打开 App**
  `openAppWhenRun = false`

- ✅ **系统托管 UI**
  显示在屏幕顶部的系统卡片中

- ✅ **实时更新**
  通过定时器轮询共享数据，检测到变化后更新 UI

- ✅ **点点动画**
  0.5 秒更新一次，循环显示 "", ".", "..", "..."

## 测试步骤

1. **构建项目**
   ```bash
   cd /Users/linjx/Desktop/kapi/AppIntent
   xcodebuild -scheme AppIntent -configuration Debug
   ```

2. **在快捷指令中配置**
   - 添加"运行快捷指令"动作
   - 选择 `ShowExpenseIntent`
   - 传入一张图片

3. **运行测试**
   - 触发快捷指令
   - 观察屏幕顶部弹出卡片
   - 确认显示"分析中..."（点点变化）
   - 3 秒后确认显示结果：
     ```
     识别完成
     星巴克咖啡
     ¥45.50
     ```

## 后续优化

完成测试后，可以恢复真实的后端调用：

1. 将 `ShowExpenseIntent.swift` 中的模拟代码替换为真实 HTTP 请求
2. 使用 `BillScanService.shared.scanBill(image: uiImage)`
3. 根据返回结果更新共享数据

## 故障排查

### 如果 UI 没有显示

1. 检查 Info.plist 中 `IntentsSupported` 是否包含 `ShowExpenseIntent`
2. 检查 Bundle ID 是否正确
3. 检查 Signing & Capabilities 中是否添加了 App Groups
4. 重新构建项目并重启设备

### 如果数据没有更新

1. 检查 App Group ID 是否一致（`group.com.dm.AppIntent`）
2. 查看控制台日志确认共享数据写入成功
3. 确认 UI Extension 的轮询定时器正在运行

### 如果点点动画不显示

1. 检查 `startDotAnimation()` 是否被调用
2. 确认定时器没有被过早释放
3. 查看控制台是否有错误日志
