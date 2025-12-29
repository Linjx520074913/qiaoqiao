# 创建 Intent Definition 指南

## 步骤 1：在 Xcode 中创建 Intent Definition 文件

1. **打开 Xcode 项目**
   ```bash
   open /Users/linjx/Desktop/kapi/AppIntent/AppIntent.xcodeproj
   ```

2. **创建 Intent Definition 文件**
   - File → New → File...
   - 搜索并选择 **"SiriKit Intent Definition File"**
   - 文件名：`ShowExpenseIntent`
   - 保存位置：`AppIntent` 文件夹
   - **重要**：勾选所有 targets（AppIntent、ShowExpenseIntentUI）

3. **配置 Intent**

   点击左下角 **"+"** 添加新 Intent：

   **基本信息：**
   - Intent Name: `ShowExpense`
   - Category: `View`
   - Title: `显示消费卡片`
   - Description: `扫描账单图片并显示消费提醒卡片`

   **参数配置：**

   点击 **"Parameters"** 区域的 **"+"**，添加参数：
   - Parameter Name: `image`
   - Type: `File`
   - Display Name: `账单图片`
   - Description: `从快捷指令传入的截图`
   - ✅ 勾选 **"Intent is eligible for Siri Suggestions"**

   **Shortcuts App 配置：**
   - ✅ 勾选 **"Supports background execution"**
   - ❌ 取消勾选 **"Intent is user-configurable in Shortcuts app and Add to Siri"**（或根据需要）

   **Response 配置：**

   点击 **"Response"** 区域，添加属性：
   - Property Name: `merchant`
   - Type: `String`
   - Display Name: `商家`

   - Property Name: `amount`
   - Type: `Decimal Number`
   - Display Name: `金额`

   - Property Name: `message`
   - Type: `String`
   - Display Name: `消息`

   **Response Templates：**
   - Success: `识别完成：\${merchant} ¥\${amount}`
   - Failure: `识别失败：\${message}`

4. **保存文件**
   - ⌘S 保存

5. **检查生成的代码**
   - Xcode 会自动生成 `ShowExpenseIntent` 类
   - 在项目导航器中，展开 `ShowExpenseIntent.intentdefinition`
   - 应该看到自动生成的 Swift 文件

完成后回到终端继续下一步。
