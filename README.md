# 金融管理 App (Bill)

这是一个基于 SwiftUI 开发的 iOS 金融管理应用程序，实现了参考设计图中的所有功能。

## 功能特性

### 1. 首页 (HomeView)
- 用户问候和会员等级显示
- 多货币支持（美元、IDR等）
- 银行卡轮播展示
  - 显示余额和卡号
  - 支持隐藏/显示余额
  - 精美的渐变背景设计
- 快捷操作按钮：充值、撤回、转移
- 交易记录列表
  - 显示商家名称、图标
  - 交易描述和金额
  - 交易时间

### 2. 统计数据页面 (StatisticsView)
- 时间段切换（周/月/年）
- 动态圆环图表
  - 显示不同类别的消费占比
  - 支持多种分类（食物、账单、小玩意、其他）
  - 颜色编码的图例
- 交易列表展示

### 3. 个人资料页面 (ProfileView)
- 用户头像和相机更换功能
- 个人信息卡片
  - 姓名、电话号码
  - 密码显示/隐藏
  - 语言设置
- 财务概览
  - 净利润和费用统计
  - 本月预算进度条
- 客服邀请卡片
- 账户历史信息

### 4. 底部导航栏 (MainTabView)
- 5 个标签：家、统计数据、扫描、卡片、个人资料
- 中间浮动扫描按钮
- 自定义图标和颜色

## 项目结构

```
bill/
├── billApp.swift          # 应用入口
├── ContentView.swift      # 主视图入口
├── Models.swift           # 数据模型定义
├── HomeView.swift         # 首页视图
├── StatisticsView.swift   # 统计数据视图
├── ProfileView.swift      # 个人资料视图
└── MainTabView.swift      # 底部导航栏
```

## 技术栈

- SwiftUI
- iOS 18.5+
- Swift 5.0

## 安装和运行

1. 在 Xcode 中打开 `bill.xcodeproj`
2. 选择目标设备或模拟器
3. 点击运行按钮 (⌘+R)

## Bundle Identifier

已更新为：`com.linjx.bill`

## 主要组件

### 数据模型
- `Transaction`: 交易记录
- `BankCard`: 银行卡信息
- `UserProfile`: 用户信息
- `StatisticsData`: 统计数据
- `TransactionCategory`: 交易分类枚举

### 自定义组件
- `CardView`: 银行卡展示组件
- `QuickActionButton`: 快捷操作按钮
- `TransactionRow`: 交易行视图
- `DonutChart`: 圆环图表
- `ProfileInfoRow`: 个人信息行
- `CustomTabBar`: 自定义底部导航栏

## 设计特点

- 现代化的 UI 设计
- 流畅的动画效果
- 响应式布局
- 深色/浅色模式支持（系统自动）
- 中文本地化

## 未来扩展

- 添加真实的数据持久化
- 集成网络 API
- 添加更多交易分类
- 支持多语言
- 添加通知功能
- 实现扫描功能
- 添加图表动画

## 作者

linjx

## 许可

此项目仅供学习和演示使用。
