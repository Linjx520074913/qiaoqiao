# ⚠️ 紧急：配置 Intent Definition

## 当前问题

`ShowExpenseIntent.intentdefinition` 文件是空的，需要在 Xcode 中配置。

## 📝 在 Xcode 中配置 Intent（必须手动完成）

### 1. 打开 Intent Definition 文件

在 Xcode 中：
- 项目导航器中找到 `ShowExpenseIntent.intentdefinition`
- 点击打开

### 2. 添加 Intent

点击左下角 **"+"** 按钮 → 选择 **"New Intent"**

### 3. 配置 Intent 基本信息

在右侧属性面板中：

**General 区域：**
- **Custom Class**: `ShowExpenseIntent` ⭐ 必须填写
- **Category**: 选择 `View`
- **Title**: `显示消费卡片`
- **Description**: `扫描账单图片并显示消费提醒卡片`

**Shortcuts App 区域：**
- ✅ 勾选 **"Supports background execution"**
- ✅ 勾选 **"Intent is user-configurable in Shortcuts app"**
- ✅ 勾选 **"Intent is eligible for Siri Suggestions"**

### 4. 添加参数 (Parameters)

在 **"Parameters"** 区域，点击 **"+"** 添加参数：

**参数配置：**
- **Parameter**: `image`
- **Type**: `File` （下拉选择）
- **Display Name**: `账单图片`
- **Siri Dialog Prompt**: `请提供账单图片`

**勾选选项：**
- ✅ **"Siri can ask for value when run"**

### 5. 配置 Response

在 **"Response"** 区域：

**添加 Property 1：**
- 点击 **"Properties"** 下的 **"+"**
- **Property**: `merchant`
- **Type**: `String`
- **Display Name**: `商家`

**添加 Property 2：**
- 点击 **"+"**
- **Property**: `amount`
- **Type**: `Decimal Number`
- **Display Name**: `金额`

**添加 Property 3：**
- 点击 **"+"**
- **Property**: `message`
- **Type**: `String`
- **Display Name**: `消息`

### 6. 配置 Response Template

在 **"Response"** 区域的 **"Templates"** 中：

**Success Template:**
```
识别完成：${merchant} ¥${amount}
```

**Failure Template:**
```
识别失败：${message}
```

### 7. 配置 Target Membership

**非常重要！** 选中 `ShowExpenseIntent.intentdefinition` 文件，在右侧 **File Inspector** (⌘⌥1) 中：

**Target Membership 必须勾选：**
- ✅ AppIntent
- ✅ ShowExpenseIntentExtension ⭐ 这个最重要
- ✅ ShowExpenseIntentUI

### 8. 保存并生成代码

- ⌘S 保存
- Xcode 会自动生成 Swift 代码
- 在 Product → Build (⌘B) 查看是否有错误

## 🔍 验证配置

配置完成后，在 Xcode 的项目导航器中：

展开 `ShowExpenseIntent.intentdefinition`，应该能看到：
```
ShowExpenseIntent.intentdefinition
  ├── ShowExpenseIntent
  ├── ShowExpenseIntentResponse
  └── ShowExpenseIntentHandling
```

如果看不到这些，说明配置有误。

## 🐛 常见错误

### 错误 1：cannot find type 'ShowExpenseIntent'

**原因**：Custom Class 没有设置或 Target Membership 没有勾选

**解决**：
1. 确认 Custom Class = `ShowExpenseIntent`
2. 确认 Target Membership 勾选了 ShowExpenseIntentExtension

### 错误 2：cannot find type 'ShowExpenseIntentHandling'

**原因**：Intent Definition 没有正确生成协议

**解决**：
1. 清理构建：Product → Clean Build Folder (⇧⌘K)
2. 重新保存 Intent Definition
3. 重新构建

### 错误 3：Target Membership 中找不到 ShowExpenseIntentExtension

**原因**：Extension target 未正确创建

**解决**：
1. 检查项目中是否有 ShowExpenseIntentExtension target
2. 如果没有，重新创建 Intents Extension target

## 📸 配置截图参考

### Intent 基本信息
```
┌─────────────────────────────────┐
│ Custom Class: ShowExpenseIntent │
│ Category: View                  │
│ Title: 显示消费卡片              │
└─────────────────────────────────┘
```

### Parameters
```
┌────────────────────────────────┐
│ + Parameters                   │
│   ├─ image (File)              │
│       Display Name: 账单图片    │
└────────────────────────────────┘
```

### Response
```
┌────────────────────────────────┐
│ + Properties                   │
│   ├─ merchant (String)         │
│   ├─ amount (Decimal Number)   │
│   └─ message (String)          │
└────────────────────────────────┘
```

## ✅ 完成检查清单

配置完成后，检查以下项：

- [ ] Custom Class = `ShowExpenseIntent`
- [ ] 添加了 image 参数（类型为 File）
- [ ] 添加了 3 个 Response Properties
- [ ] 配置了 Success/Failure Templates
- [ ] Target Membership 勾选了 3 个 targets
- [ ] 保存后能看到自动生成的 Swift 文件
- [ ] 构建没有错误

## 🚀 完成后

配置完成并保存后，回到终端运行：

```bash
cd /Users/linjx/Desktop/kapi/AppIntent
xcodebuild -scheme AppIntent -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

如果构建成功，您就可以测试了！
