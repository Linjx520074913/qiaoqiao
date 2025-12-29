# 替代方案：通过拖拽添加文件

## 问题

`ShowExpenseIntentIntent.swift` 在文件选择对话框中显示为灰色，无法选中。

## 解决方案

### 方法 1：使用拖拽（推荐）

1. **取消当前的对话框**（点击 Cancel）

2. **打开 Finder**
   - 导航到：`/Users/linjx/Desktop/kapi/AppIntent/AppIntent/`
   - 找到文件：`ShowExpenseIntentIntent.swift`

3. **拖拽文件到 Xcode**
   - 将 `ShowExpenseIntentIntent.swift` 文件
   - 拖拽到 Xcode 左侧项目导航器中的 `AppIntent` 文件夹上
   - **松开鼠标**

4. **在弹出的对话框中**
   - ✅ 勾选 **"Copy items if needed"**
   - ✅ 勾选 **"Create groups"**
   - **Add to targets** 勾选所有：
     - ✅ AppIntent
     - ✅ ShowExpenseIntentExtension
     - ✅ ShowExpenseIntentUI
   - 点击 **"Finish"**

### 方法 2：从其他位置复制

如果文件已经在项目目录但显示灰色，可能是因为 Xcode 认为它已存在。

1. **将文件移到其他位置**
   ```bash
   mv /Users/linjx/Desktop/kapi/AppIntent/AppIntent/ShowExpenseIntentIntent.swift \
      /Users/linjx/Desktop/ShowExpenseIntentIntent.swift
   ```

2. **在 Xcode 中添加**
   - File → Add Files to "AppIntent"...
   - 选择桌面上的 `ShowExpenseIntentIntent.swift`
   - 勾选所有 targets
   - 点击 Add

### 方法 3：通过命令行直接添加到项目

取消对话框，然后我帮您通过命令行修改项目文件。

## 推荐步骤

**请先尝试方法 1（拖拽）**，这是最简单可靠的方式。

完成后告诉我结果！
