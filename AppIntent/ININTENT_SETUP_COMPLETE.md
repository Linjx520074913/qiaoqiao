# INIntent 完整配置指南

## 📋 准备工作已完成

✅ 已创建以下文件：
- `ShowExpenseIntentExtension/IntentHandler.swift` - Intent 处理逻辑
- `ShowExpenseIntentExtension/Info.plist` - Extension 配置
- `ShowExpenseIntentExtension/ShowExpenseIntentExtension.entitlements` - App Group 权限
- `ShowExpenseIntentUI/IntentViewController.swift` - UI 控制器（已更新）

## 🔧 在 Xcode 中完成配置

### 步骤 1：创建 Intent Definition 文件

1. **打开 Xcode**
   ```bash
   open /Users/linjx/Desktop/kapi/AppIntent/AppIntent.xcodeproj
   ```

2. **创建 SiriKit Intent Definition 文件**
   - File → New → File... (⌘N)
   - 搜索 **"SiriKit Intent Definition File"**
   - 文件名：`ShowExpenseIntent`
   - 保存到：`AppIntent` 文件夹（主项目）
   - **重要**：勾选 **AppIntent** target

3. **配置 Intent**

   选中刚创建的 `ShowExpenseIntent.intentdefinition` 文件：

   **添加 Intent：**
   - 点击左下角 **"+"** → **"New Intent"**

   **基本信息：**
   - Custom Class: `ShowExpenseIntent`
   - Category: `View`
   - Title: `显示消费卡片`
   - Description: `扫描账单图片并显示消费提醒卡片`

   **参数配置（Parameters）：**

   点击 **"Parameters"** 下方的 **"+"** 添加：

   | Property | Value |
   |----------|-------|
   | Parameter | `image` |
   | Type | `File` |
   | Display Name | `账单图片` |

   勾选：
   - ✅ **"Siri can ask for value when run"**
   - ✅ **"Intent is eligible for Siri Suggestions"**

   **Shortcuts App：**
   - ✅ 勾选 **"Supports background execution"**
   - ✅ 勾选 **"Intent is user-configurable in Shortcuts app"**

   **Response Properties：**

   点击 **"Response"** 区域的 **"Properties"** 下的 **"+"**：

   添加属性 1：
   - Property: `merchant`
   - Type: `String`
   - Display Name: `商家`

   添加属性 2：
   - Property: `amount`
   - Type: `Decimal Number`
   - Display Name: `金额`

   添加属性 3：
   - Property: `message`
   - Type: `String`
   - Display Name: `消息`

   **Response Templates：**

   在 **"Response"** 区域的 **"Templates"** 中：
   - Success template: `识别完成：\${merchant} ¥\${amount}`
   - Failure template: `识别失败：\${message}`

4. **保存文件** (⌘S)

### 步骤 2：添加 Intents Extension Target

1. **创建新 Target**
   - File → New → Target...
   - 选择 **iOS → Intents Extension**
   - Product Name: `ShowExpenseIntentExtension`
   - Language: Swift
   - **取消勾选** "Include UI Extension"（我们已经有了）
   - 点击 **Finish**

2. **删除自动生成的文件**
   - Xcode 会创建一些默认文件
   - 删除自动生成的 `IntentHandler.swift`
   - 我们使用已准备好的文件

3. **添加准备好的文件**
   - 在项目导航器中，右键 `ShowExpenseIntentExtension` 文件夹
   - Add Files to "AppIntent"...
   - 选择以下文件：
     - `ShowExpenseIntentExtension/IntentHandler.swift`
     - `ShowExpenseIntentExtension/Info.plist`（覆盖）
     - `ShowExpenseIntentExtension/ShowExpenseIntentExtension.entitlements`
   - **重要**：Target 选择 `ShowExpenseIntentExtension`

4. **配置 Target**

   选择 `ShowExpenseIntentExtension` target：

   **General：**
   - Bundle Identifier: `com.dm.AppIntent.ShowExpenseIntentExtension`
   - Deployment Target: iOS 16.0+

   **Signing & Capabilities：**
   - 启用 Automatic Signing
   - 添加 **App Groups** capability
   - 勾选 `group.com.dm.AppIntent`

   **Build Settings：**
   - 搜索 "Code Signing Entitlements"
   - 设置为：`ShowExpenseIntentExtension/ShowExpenseIntentExtension.entitlements`

   **Build Phases → Link Binary With Libraries：**
   - 确保包含 `Intents.framework`

5. **链接 Intent Definition**

   **关键步骤：** 确保 `ShowExpenseIntent.intentdefinition` 被添加到正确的 targets：

   - 选中 `ShowExpenseIntent.intentdefinition` 文件
   - 在右侧 **File Inspector** (⌘⌥1) 中
   - 在 **Target Membership** 区域，勾选：
     - ✅ AppIntent
     - ✅ ShowExpenseIntentExtension
     - ✅ ShowExpenseIntentUI

### 步骤 3：配置 Intents UI Extension

`ShowExpenseIntentUI` 已经创建，只需确认配置：

1. **检查 Info.plist**
   - 打开 `ShowExpenseIntentUI/Info.plist`
   - 确认 `IntentsSupported` 包含：
     ```xml
     <key>IntentsSupported</key>
     <array>
         <string>ShowExpenseIntent</string>
     </array>
     ```

2. **确认 Target Membership**
   - 选中 `IntentViewController.swift`
   - 右侧确认 Target 为 `ShowExpenseIntentUI`

3. **确认 App Groups**
   - 选择 `ShowExpenseIntentUI` target
   - Signing & Capabilities
   - 确认勾选 `group.com.dm.AppIntent`

### 步骤 4：配置主 App

1. **链接 Intent Definition**
   - 确认 `ShowExpenseIntent.intentdefinition` 在主 App target 中
   - 确认 AppIntent target 的 Target Membership 已勾选

2. **确认 App Groups**
   - AppIntent target → Signing & Capabilities
   - 确认 `group.com.dm.AppIntent` 已配置

### 步骤 5：构建项目

1. **清理构建**
   ```bash
   cd /Users/linjx/Desktop/kapi/AppIntent
   xcodebuild clean
   ```

2. **构建所有 targets**
   ```bash
   xcodebuild -scheme AppIntent -configuration Debug \
     -destination 'platform=iOS Simulator,name=iPhone 16' build
   ```

   **预期输出：**
   - ✅ Building target: AppIntent
   - ✅ Building target: ShowExpenseIntentExtension
   - ✅ Building target: ShowExpenseIntentUI
   - ✅ ** BUILD SUCCEEDED **

## 🎯 完整架构

```
┌─────────────────────────────────────────┐
│          AppIntent.app                  │
│     (主应用，不需要运行)                  │
└─────────────────────────────────────────┘
                   ↑
                   │ 包含
         ┌─────────┴──────────┐
         │                    │
┌────────┴─────────┐  ┌───────┴──────────┐
│ ShowExpenseIntent│  │ ShowExpenseIntent│
│    Extension     │  │   UIExtension    │
│  (处理 Intent)   │  │   (显示 UI)      │
│                  │  │                  │
│ IntentHandler    │  │ IntentView-      │
│   .swift         │  │  Controller.swift│
└──────────────────┘  └──────────────────┘
         │                    │
         └────────┬───────────┘
                  │
                  ↓
      ┌─────────────────────┐
      │   App Group         │
      │ group.com.dm.       │
      │    AppIntent        │
      │ (共享数据)           │
      └─────────────────────┘
```

## 📱 执行流程

```
1. 用户触发快捷指令
   ↓
2. 系统启动 ShowExpenseIntentExtension
   IntentHandler.handle() 被调用
   ↓
3. 系统同时启动 ShowExpenseIntentUI
   IntentViewController.configureView() 被调用
   ↓
4. UI 立即显示"分析中..."（点点动画）
   ↓
5. IntentHandler 在后台执行 3 秒任务
   写入 App Group: status = "analyzing"
   ↓
6. IntentViewController 每 0.3 秒轮询 App Group
   检测到 status = "analyzing"，保持动画
   ↓
7. 3 秒后，IntentHandler 完成识别
   写入 App Group:
     - status = "success"
     - merchant = "星巴克咖啡"
     - amount = 45.50
   ↓
8. IntentViewController 检测到变化
   更新 UI 显示结果
   ↓
9. 用户看到最终结果
   IntentHandler 返回 response
```

## ✅ 验证清单

在构建前确认：

- [ ] `ShowExpenseIntent.intentdefinition` 已创建
- [ ] Intent 配置正确（名称、参数、响应）
- [ ] `ShowExpenseIntentExtension` target 已创建
- [ ] 所有文件的 Target Membership 正确
- [ ] 三个 targets 都配置了 App Groups
- [ ] Intent Definition 链接到所有相关 targets

## 🐛 常见问题

### 问题 1：找不到 ShowExpenseIntent 类

**原因**：Intent Definition 未正确生成代码

**解决**：
1. 选中 `ShowExpenseIntent.intentdefinition`
2. 检查 Target Membership
3. Product → Clean Build Folder (⇧⌘K)
4. 重新构建

### 问题 2：UI Extension 不显示

**原因**：Intent Name 不匹配

**解决**：
确保以下位置的名称一致：
- Intent Definition 中的 Custom Class: `ShowExpenseIntent`
- Info.plist 中的 IntentsSupported: `ShowExpenseIntent`

### 问题 3：App Groups 无法访问

**原因**：Entitlements 配置错误

**解决**：
1. 确认三个 targets 都添加了 App Groups capability
2. 确认 group ID 完全一致：`group.com.dm.AppIntent`
3. 重新签名并构建

## 📝 与 AppIntent 的区别

| 特性 | AppIntent (旧) | INIntent (新) |
|------|---------------|---------------|
| 框架 | `import AppIntents` | `import Intents` |
| 定义方式 | Swift struct | .intentdefinition |
| UI Extension | ❌ 不支持 | ✅ 支持 |
| 配置复杂度 | 简单 | 复杂 |
| Xcode 要求 | 现代 | 传统 |

## 🎉 完成后

构建成功后，您将拥有：

1. ✅ **Intents Extension** - 处理账单识别逻辑
2. ✅ **Intents UI Extension** - 显示实时更新的 UI
3. ✅ **App Group 共享** - 进程间通信
4. ✅ **不打开 App** - 完全后台执行
5. ✅ **系统托管 UI** - 屏幕顶部卡片
6. ✅ **点点动画** - 用户体验优化

请按照步骤完成配置，完成后回来测试！
