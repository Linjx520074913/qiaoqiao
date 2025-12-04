//
//  HomeView.swift
//  bill
//
//  Created by linjx on 2025/12/3.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedAccount = "全部账户"
    @State private var isShowingAddTransaction = false

    private var transactions: [Transaction] {
        appState.transactions
    }

    // 动态计算账户信息
    private var currentAccount: Account {
        Account(
            name: "我的账本",
            balance: appState.totalBalance,
            accountType: "总资产",
            backgroundColor: [Color.blue.opacity(0.8), Color.blue.opacity(0.4)]
        )
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 24) {
                    // 顶部问候语
                    greetingHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    // 横向滚动卡片
                    horizontalCardsView

                    // 交易列表
                    transactionList

                    // 底部占位
                    Color.clear.frame(height: 80)
                }
            }
            .background(Color(red: 0.97, green: 0.97, blue: 0.98))

            // 悬浮添加按钮
            floatingAddButton
                .padding(.trailing, 20)
                .padding(.bottom, 100)
        }
        .sheet(isPresented: $isShowingAddTransaction) {
            AddTransactionView(onSave: { transaction in
                addTransaction(transaction)
            })
        }
    }

    // MARK: - 视图组件

    // 横向滚动卡片视图（禁用手势滑动，只能点击指示器切换）
    @State private var selectedCardIndex = 0

    private var horizontalCardsView: some View {
        VStack(spacing: 12) {
            // 卡片显示区域 - 禁用TabView的滑动交互
            TabView(selection: $selectedCardIndex) {
                // 卡片1: 今日支出 + 预算（合并）
                todayExpenseAndBudgetCard
                    .padding(.horizontal, 20)
                    .tag(0)

                // 卡片2: 本月收入支出
                monthlyIncomeExpenseCard
                    .padding(.horizontal, 20)
                    .tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 220)
            .allowsHitTesting(false)  // 禁用TabView滑动，但不影响卡片内的按钮
            .background(
                // 透明层接收卡片内容的点击
                Color.clear
                    .allowsHitTesting(true)
            )

            // 自定义页面指示器
            HStack(spacing: 8) {
                ForEach(0..<2) { index in
                    Circle()
                        .fill(selectedCardIndex == index ? Color(red: 0.35, green: 0.45, blue: 0.95) : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedCardIndex = index
                            }
                        }
                }
            }
            .padding(.top, 4)
        }
    }

    // 今日支出 + 预算 合并卡片 - 专业iOS设计
    private var todayExpenseAndBudgetCard: some View {
        BudgetCardWrapper()
    }

    // MARK: - 预算卡片包装器（支持点击设置预算）
    private struct BudgetCardWrapper: View {
    @EnvironmentObject var appState: AppState
    @State private var isShowingBudgetEditor = false

    var body: some View {
        ZStack {
            // 柔和的渐变背景（珊瑚红+金橙混合）
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.47, blue: 0.45),
                    Color(red: 0.97, green: 0.45, blue: 0.35)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 精致的装饰元素
            GeometryReader { geo in
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 180, height: 180)
                    .offset(x: geo.size.width - 70, y: -40)

                Circle()
                    .fill(.white.opacity(0.05))
                    .frame(width: 100, height: 100)
                    .offset(x: -30, y: geo.size.height - 30)
            }

            VStack(spacing: 0) {
                // 顶部标题区
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("今日支出")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))

                        Text(currentDateText)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.65))
                    }

                    Spacer()

                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                // 计算预算数据（在外部作用域）
                let budgetUsagePercent = appState.monthlyBudget > 0 ? (appState.monthlyExpense / appState.monthlyBudget) * 100 : 0
                let remainingBudget = appState.monthlyBudget - appState.monthlyExpense
                let dailyAvailable = remainingBudget / Double(max(appState.daysRemainingInMonth, 1))

                // 中心：今日支出 + 预算进度 并排
                HStack(spacing: 0) {
                    // 左侧：今日支出金额
                    VStack(spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("¥")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                                .offset(y: -5)
                            Text(String(format: "%.0f", appState.todayExpense))
                                .font(.system(size: 46, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        }

                        if appState.todayExpense.truncatingRemainder(dividingBy: 1) > 0 {
                            Text(String(format: ".%02d", Int((appState.todayExpense.truncatingRemainder(dividingBy: 1)) * 100)))
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                                .offset(y: -6)
                        }

                        Text("今日支出")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .offset(y: -4)
                    }
                    .frame(maxWidth: .infinity)

                    // 竖向分割线
                    Rectangle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 1, height: 80)

                    // 右侧：预算进度环（可点击）
                    Button(action: {
                        isShowingBudgetEditor = true
                    }) {
                        VStack(spacing: 8) {
                            // 精致的环形进度
                            ZStack {
                                // 背景环
                                Circle()
                                    .stroke(.white.opacity(0.25), lineWidth: 5)
                                    .frame(width: 70, height: 70)

                                // 进度环
                                Circle()
                                    .trim(from: 0, to: min(budgetUsagePercent / 100, 1.0))
                                    .stroke(
                                        .white,
                                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                                    )
                                    .frame(width: 70, height: 70)
                                    .rotationEffect(.degrees(-90))

                                // 中心百分比
                                VStack(spacing: 1) {
                                    Text(String(format: "%.0f", budgetUsagePercent))
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("%")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }

                            HStack(spacing: 4) {
                                Text("本月预算")
                                    .font(.system(size: 12, weight: .medium))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)

                Spacer()

                // 底部信息条
                HStack(spacing: 0) {
                    // 左侧：今日交易信息
                    HStack(spacing: 16) {
                        if appState.todayTransactionCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 11))
                                Text("\(appState.todayTransactionCount) 笔")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.75))
                        }

                        if appState.yesterdayExpense > 0 {
                            let change = appState.todayExpense - appState.yesterdayExpense
                            let changePercent = (change / appState.yesterdayExpense) * 100

                            HStack(spacing: 4) {
                                Text("较昨日")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.65))

                                HStack(spacing: 2) {
                                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                                        .font(.system(size: 9, weight: .bold))
                                    Text(String(format: "%.0f%%", abs(changePercent)))
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(change >= 0 ? .white.opacity(0.95) : Color(red: 0.6, green: 1.0, blue: 0.8))
                            }
                        }
                    }

                    Spacer()

                    // 右侧：预算剩余信息
                    HStack(spacing: 8) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("剩余")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.65))
                            HStack(alignment: .firstTextBaseline, spacing: 1) {
                                Text("¥")
                                    .font(.system(size: 10))
                                Text(String(format: "%.0f", abs(remainingBudget)))
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white.opacity(0.9))
                        }

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("日均")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.65))
                            HStack(alignment: .firstTextBaseline, spacing: 1) {
                                Text("¥")
                                    .font(.system(size: 10))
                                Text(String(format: "%.0f", abs(dailyAvailable)))
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .frame(height: 200)
        .cornerRadius(28)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        .shadow(color: Color(red: 1.0, green: 0.47, blue: 0.45).opacity(0.15), radius: 24, x: 0, y: 8)
        .sheet(isPresented: $isShowingBudgetEditor) {
            BudgetEditorView()
                .environmentObject(appState)
        }
    }

        // 当前日期文本
        private var currentDateText: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日 EEEE"
            formatter.locale = Locale(identifier: "zh_CN")
            return formatter.string(from: Date())
        }
    }

    // 今日支出卡片 - 专业iOS设计（保留以备用）
    private var todaySummaryCard: some View {
        ZStack {
            // 柔和的渐变背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.45, blue: 0.45),
                    Color(red: 0.95, green: 0.40, blue: 0.50)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 精致的装饰元素
            GeometryReader { geo in
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 180, height: 180)
                    .offset(x: geo.size.width - 70, y: -40)

                Circle()
                    .fill(.white.opacity(0.05))
                    .frame(width: 100, height: 100)
                    .offset(x: -30, y: geo.size.height - 30)
            }

            VStack(spacing: 0) {
                // 顶部标题区
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("今日支出")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))

                        Text(currentDateText)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.65))
                    }

                    Spacer()

                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                // 中心金额 - 视觉焦点
                VStack(spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("¥")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .offset(y: -6)
                        Text(String(format: "%.0f", appState.todayExpense))
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }

                    if appState.todayExpense.truncatingRemainder(dividingBy: 1) > 0 {
                        Text(String(format: ".%02d", Int((appState.todayExpense.truncatingRemainder(dividingBy: 1)) * 100)))
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .offset(y: -8)
                    }
                }

                Spacer()

                // 底部信息条
                HStack(spacing: 0) {
                    if appState.todayTransactionCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 11))
                            Text("\(appState.todayTransactionCount) 笔")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.75))
                    }

                    Spacer()

                    if appState.yesterdayExpense > 0 {
                        let change = appState.todayExpense - appState.yesterdayExpense
                        let changePercent = (change / appState.yesterdayExpense) * 100

                        HStack(spacing: 5) {
                            Text("较昨日")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.65))

                            HStack(spacing: 3) {
                                Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    .font(.system(size: 10, weight: .bold))
                                Text(String(format: "%.0f%%", abs(changePercent)))
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(change >= 0 ? .white.opacity(0.95) : Color(red: 0.6, green: 1.0, blue: 0.8))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .frame(height: 200)
        .cornerRadius(28)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        .shadow(color: Color(red: 1.0, green: 0.45, blue: 0.45).opacity(0.15), radius: 24, x: 0, y: 8)
    }

    // 当前日期文本
    private var currentDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: Date())
    }

    // 问候语头部
    private var greetingHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greetingText)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)

                Text(dateText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 头像
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.35, green: 0.45, blue: 0.95),
                                Color(red: 0.55, green: 0.35, blue: 0.85)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: "person.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }
            .shadow(color: Color(red: 0.35, green: 0.45, blue: 0.95).opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }

    // 本月账单卡片 - 专业iOS设计
    private var monthlyIncomeExpenseCard: some View {
        ZStack {
            // 深邃的紫色渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.42, green: 0.51, blue: 0.94),
                    Color(red: 0.48, green: 0.32, blue: 0.68)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 装饰圆形
            GeometryReader { geo in
                Circle()
                    .fill(.white.opacity(0.06))
                    .frame(width: 200, height: 200)
                    .offset(x: -50, y: geo.size.height - 70)

                Circle()
                    .fill(.white.opacity(0.04))
                    .frame(width: 120, height: 120)
                    .offset(x: geo.size.width - 40, y: -20)
            }

            VStack(spacing: 0) {
                // 顶部标题
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("本月账单")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))

                        Text(currentMonthText)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.65))
                    }

                    Spacer()

                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                // 中心：收入支出对比（添加竖向分割线）
                HStack(spacing: 0) {
                    // 收入侧
                    VStack(spacing: 8) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 14))
                            Text("收入")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.75))

                        HStack(alignment: .firstTextBaseline, spacing: 1) {
                            Text("¥")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                            Text(String(format: "%.0f", appState.monthlyIncome))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // 竖向分割线
                    Rectangle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 1, height: 60)

                    // 支出侧
                    VStack(spacing: 8) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 14))
                            Text("支出")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.75))

                        HStack(alignment: .firstTextBaseline, spacing: 1) {
                            Text("¥")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                            Text(String(format: "%.0f", appState.monthlyExpense))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)

                Spacer()

                // 底部结余信息
                let balance = appState.monthlyIncome - appState.monthlyExpense
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: balance >= 0 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.system(size: 12))
                        Text(balance >= 0 ? "本月结余" : "本月赤字")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(balance >= 0 ? Color(red: 0.6, green: 1.0, blue: 0.8) : Color(red: 1.0, green: 0.7, blue: 0.7))

                    Spacer()

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("¥")
                            .font(.system(size: 12))
                        Text(String(format: "%.0f", abs(balance)))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .frame(height: 200)
        .cornerRadius(28)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        .shadow(color: Color(red: 0.42, green: 0.51, blue: 0.94).opacity(0.15), radius: 24, x: 0, y: 8)
    }

    // 预算卡片（用于横向滚动）
    private var budgetCard: some View {
        BudgetProgressCard(
            expense: appState.monthlyExpense,
            budget: appState.monthlyBudget,
            budgetUsagePercent: (appState.monthlyBudget > 0 ? min((appState.monthlyExpense / appState.monthlyBudget) * 100, 100) : 0),
            remainingBudget: max(appState.monthlyBudget - appState.monthlyExpense, 0)
        )
    }

    // 交易列表
    private var transactionList: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet.rectangle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.35, green: 0.45, blue: 0.95))
                    Text("最近交易")
                        .font(.system(size: 18, weight: .bold))
                }
                Spacer()
                if !transactions.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "number")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("\(transactions.count) 笔")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 20)

            if transactions.isEmpty {
                emptyStateView
            } else {
                transactionListContent
            }
        }
    }

    // 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.35, green: 0.45, blue: 0.95).opacity(0.15),
                                Color(red: 0.25, green: 0.35, blue: 0.85).opacity(0.08)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "tray.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(Color(red: 0.35, green: 0.45, blue: 0.95).opacity(0.5))
            }

            VStack(spacing: 8) {
                Text("暂无交易记录")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                Text("点击右下角按钮开始记账")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
    }

    // 交易列表内容
    private var transactionListContent: some View {
        VStack(spacing: 16) {
            ForEach(groupedTransactions, id: \.key) { group in
                VStack(alignment: .leading, spacing: 12) {
                    // 日期标题
                    HStack(spacing: 6) {
                        Image(systemName: dateIcon(for: group.key))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(red: 0.35, green: 0.45, blue: 0.95))

                        Text(group.key)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 0.35, green: 0.45, blue: 0.95))

                        Spacer()

                        // 当日小计
                        let dayTotal = group.value.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) }
                        if dayTotal > 0 {
                            Text(String(format: "支出 ¥%.2f", dayTotal))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                    // 该日期的交易列表
                    VStack(spacing: 0) {
                        ForEach(group.value) { transaction in
                            SwipeableTransactionRow(
                                transaction: transaction,
                                onDelete: {
                                    deleteTransaction(transaction)
                                }
                            )

                            if transaction.id != group.value.last?.id {
                                Divider()
                                    .padding(.leading, 70)
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // 分组交易记录
    private var groupedTransactions: [(key: String, value: [Transaction])] {
        let calendar = Calendar.current
        let now = Date()

        var groups: [String: [Transaction]] = [:]

        for transaction in transactions.prefix(10) {
            let dateKey: String

            if calendar.isDateInToday(transaction.date) {
                dateKey = "今天"
            } else if calendar.isDateInYesterday(transaction.date) {
                dateKey = "昨天"
            } else if calendar.isDate(transaction.date, equalTo: now, toGranularity: .weekOfYear) {
                // 本周内的日期显示"星期X"
                let weekday = calendar.component(.weekday, from: transaction.date)
                let weekdayNames = ["", "星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"]
                dateKey = weekdayNames[weekday]
            } else {
                // 更早的日期显示"MM月DD日"
                let month = calendar.component(.month, from: transaction.date)
                let day = calendar.component(.day, from: transaction.date)
                dateKey = String(format: "%d月%d日", month, day)
            }

            if groups[dateKey] == nil {
                groups[dateKey] = []
            }
            groups[dateKey]?.append(transaction)
        }

        // 按日期排序（今天 > 昨天 > 其他）
        let sortedKeys = groups.keys.sorted { key1, key2 in
            let priority1 = datePriority(for: key1)
            let priority2 = datePriority(for: key2)

            if priority1 != priority2 {
                return priority1 < priority2
            }

            // 如果优先级相同，按日期字符串排序（用于"更早"的日期）
            return key1 > key2
        }

        return sortedKeys.map { ($0, groups[$0]!) }
    }

    // 日期优先级（数字越小越靠前）
    private func datePriority(for dateKey: String) -> Int {
        switch dateKey {
        case "今天": return 0
        case "昨天": return 1
        case let key where key.hasPrefix("星期"): return 2
        default: return 3
        }
    }

    // 日期图标
    private func dateIcon(for dateKey: String) -> String {
        switch dateKey {
        case "今天": return "calendar.badge.clock"
        case "昨天": return "clock.arrow.circlepath"
        default: return "calendar"
        }
    }

    // 悬浮添加按钮
    private var floatingAddButton: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            isShowingAddTransaction = true
        }) {
            ZStack {
                // 外层光晕
                Circle()
                    .fill(Color(red: 0.35, green: 0.45, blue: 0.95).opacity(0.2))
                    .frame(width: 68, height: 68)
                    .blur(radius: 8)

                // 主按钮
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.35, green: 0.45, blue: 0.95),
                                Color(red: 0.25, green: 0.35, blue: 0.85)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: Color(red: 0.35, green: 0.45, blue: 0.95).opacity(0.4), radius: 12, x: 0, y: 6)

                // 加号图标
                Image(systemName: "plus")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Helper Properties

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<6:
            return "夜深了"
        case 6..<12:
            return "早上好"
        case 12..<14:
            return "中午好"
        case 14..<18:
            return "下午好"
        case 18..<22:
            return "晚上好"
        default:
            return "夜深了"
        }
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: Date())
    }

    private var currentMonthText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: Date())
    }

    // MARK: - Actions

    // 添加交易记录
    private func addTransaction(_ transaction: Transaction) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            appState.addTransaction(transaction)
        }
    }

    // 删除交易记录
    private func deleteTransaction(_ transaction: Transaction) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            appState.deleteTransaction(transaction)
        }
    }
}

// MARK: - 月度财务卡片（收入、支出、预算整合）
struct MonthlyFinanceCard: View {
    let income: Double
    let expense: Double
    let budget: Double

    // 计算预算使用百分比
    private var budgetUsagePercent: Double {
        guard budget > 0 else { return 0 }
        return min((expense / budget) * 100, 100)
    }

    // 剩余预算
    private var remainingBudget: Double {
        return max(budget - expense, 0)
    }

    var body: some View {
        VStack(spacing: 12) {
            // 收入和支出卡片
            HStack(spacing: 12) {
                // 收入卡片
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("收入")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.9))
                    }

                    Text(String(format: "¥%.2f", income))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.2, green: 0.78, blue: 0.35),
                                Color(red: 0.15, green: 0.68, blue: 0.30)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        GeometryReader { geo in
                            Circle()
                                .fill(.white.opacity(0.1))
                                .frame(width: 80, height: 80)
                                .offset(x: geo.size.width - 40, y: -20)
                        }
                    }
                )
                .cornerRadius(20)
                .shadow(color: Color(red: 0.2, green: 0.78, blue: 0.35).opacity(0.4), radius: 12, x: 0, y: 6)

                // 支出卡片
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("支出")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.9))
                    }

                    Text(String(format: "¥%.2f", expense))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.35, green: 0.45, blue: 0.95),
                                Color(red: 0.25, green: 0.35, blue: 0.85)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        GeometryReader { geo in
                            Circle()
                                .fill(.white.opacity(0.1))
                                .frame(width: 80, height: 80)
                                .offset(x: geo.size.width - 40, y: -20)
                        }
                    }
                )
                .cornerRadius(20)
                .shadow(color: Color(red: 0.35, green: 0.45, blue: 0.95).opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .frame(height: 120)

            // 预算卡片 - 使用圆形进度环
            BudgetProgressCard(
                expense: expense,
                budget: budget,
                budgetUsagePercent: budgetUsagePercent,
                remainingBudget: remainingBudget
            )
        }
    }
}

// 财务项目组件
struct FinanceItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let amount: Double
    let backgroundColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }

            Text(String(format: "¥%.2f", amount))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)
        )
    }
}

// MARK: - 本月卡片
struct MonthlyCard: View {
    enum CardType {
        case income
        case expense

        var title: String {
            switch self {
            case .income: return "收入"
            case .expense: return "支出"
            }
        }

        var icon: String {
            switch self {
            case .income: return "arrow.down.left.circle.fill"
            case .expense: return "arrow.up.right.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .income: return .green
            case .expense: return .red
            }
        }
    }

    let type: CardType
    let amount: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 16))
                    .foregroundColor(type.color)

                Text(type.title)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }

            Text(String(format: "¥%.2f", amount))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(type.color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(type.color.opacity(0.08))
        .cornerRadius(16)
    }
}

// 账户卡片视图
struct AccountCardView: View {
    let account: Account
    var monthlyExpense: Double = 0
    var monthlyIncome: Double = 0
    @State private var isBalanceHidden = false

    var body: some View {
        VStack(spacing: 0) {
            // 总资产部分 - 添加渐变背景
            ZStack {
                // 多层渐变背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.2, green: 0.5, blue: 1.0),
                        Color(red: 0.4, green: 0.6, blue: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // 装饰性圆形
                GeometryReader { geometry in
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .offset(x: geometry.size.width - 80, y: -60)
                        .blur(radius: 20)

                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 150, height: 150)
                        .offset(x: -40, y: geometry.size.height - 60)
                        .blur(radius: 15)
                }

                VStack(spacing: 16) {
                    HStack {
                        Text("总资产")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.95))

                        Spacer()

                        // 眼睛图标 - 隐藏/显示余额
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isBalanceHidden.toggle()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 32, height: 32)

                                Image(systemName: isBalanceHidden ? "eye.slash.fill" : "eye.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                        }
                    }

                    Spacer()

                    VStack(spacing: 8) {
                        if isBalanceHidden {
                            Text("****")
                                .font(.system(size: 44, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text(String(format: "¥%.2f", account.balance))
                                .font(.system(size: 44, weight: .bold))
                                .foregroundColor(.white)
                        }

                        Text("点击眼睛图标可隐藏金额")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.75))
                    }

                    Spacer()
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
            }
            .frame(height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            // 收支统计 - 优化布局
            HStack(spacing: 0) {
                // 本月支出
                VStack(spacing: 10) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.red.opacity(0.8))
                        Text("本月支出")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }

                    Text(String(format: "¥%.2f", monthlyExpense))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)

                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1, height: 50)

                // 本月收入
                VStack(spacing: 10) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green.opacity(0.8))
                        Text("本月收入")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }

                    Text(String(format: "¥%.2f", monthlyIncome))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .background(Color.white)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 5)
    }
}


// 可滑动的交易行视图（支持右滑删除）
struct SwipeableTransactionRow: View {
    let transaction: Transaction
    var onDelete: (() -> Void)? = nil
    @State private var offset: CGFloat = 0
    @State private var showDetail = false

    private let deleteButtonWidth: CGFloat = 80

    var body: some View {
        ZStack(alignment: .trailing) {
            // 删除按钮背景
            Rectangle()
                .fill(Color.red)
                .frame(width: deleteButtonWidth)
                .overlay(
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            onDelete?()
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 20, weight: .semibold))
                            Text("删除")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(width: deleteButtonWidth)
                    }
                )

            // 交易内容
            TransactionRowContent(transaction: transaction, showDetail: $showDetail)
                .background(Color.white)
                .offset(x: offset)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            // 判断滑动方向
                            let horizontalMovement = abs(value.translation.width)
                            let verticalMovement = abs(value.translation.height)

                            // 如果水平移动明显大于垂直移动（至少1.5倍），才认为是横向滑动
                            if horizontalMovement > verticalMovement * 1.5 {
                                if value.translation.width < 0 {
                                    // 向左滑动
                                    offset = max(value.translation.width, -deleteButtonWidth)
                                } else if offset < 0 {
                                    // 已经滑出，允许向右滑回去
                                    offset = min(0, offset + value.translation.width)
                                }
                            }
                        }
                        .onEnded { value in
                            let horizontalMovement = abs(value.translation.width)
                            let verticalMovement = abs(value.translation.height)

                            // 同样的方向判断
                            if horizontalMovement > verticalMovement * 1.5 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    if value.translation.width < -50 {
                                        offset = -deleteButtonWidth
                                    } else {
                                        offset = 0
                                    }
                                }
                            }
                        }
                )
                .onTapGesture {
                    if offset < 0 {
                        // 如果已滑出，点击收回
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            offset = 0
                        }
                    }
                }
        }
        .sheet(isPresented: $showDetail) {
            TransactionDetailView(transaction: transaction)
        }
    }
}

// 交易行内容视图
struct TransactionRowContent: View {
    let transaction: Transaction
    @Binding var showDetail: Bool

    var body: some View {
        HStack(spacing: 14) {
            // 分类图标
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(transaction.category.color.opacity(0.12))
                    .frame(width: 52, height: 52)

                Image(systemName: transaction.category.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(transaction.category.color)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(transaction.merchantName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Text(transaction.category.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)

                    if !transaction.description.isEmpty && transaction.description != "无备注" {
                        Text("·")
                            .foregroundColor(.gray.opacity(0.5))
                            .font(.system(size: 12))

                        Text(transaction.description)
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.8))
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(String(format: "%@¥%.2f", transaction.amount >= 0 ? "+" : "-", abs(transaction.amount)))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(transaction.amount >= 0 ? .green : .primary)

                Text(formatTime(transaction.date))
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture {
            showDetail = true
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// 交易行视图（保留原有的长按删除功能）
struct TransactionRow: View {
    let transaction: Transaction
    var onDelete: (() -> Void)? = nil
    @State private var showDeleteButton = false
    @State private var showDetail = false

    var body: some View {
        HStack(spacing: 14) {
            // 分类图标 - 更现代的设计
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(transaction.category.color.opacity(0.12))
                    .frame(width: 52, height: 52)

                Image(systemName: transaction.category.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(transaction.category.color)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(transaction.merchantName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Text(transaction.category.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)

                    if !transaction.description.isEmpty && transaction.description != "无备注" {
                        Text("·")
                            .foregroundColor(.gray.opacity(0.5))
                            .font(.system(size: 12))

                        Text(transaction.description)
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.8))
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            if showDeleteButton {
                // 删除按钮
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onDelete?()
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 44, height: 44)

                        Image(systemName: "trash.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                    }
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                VStack(alignment: .trailing, spacing: 6) {
                    Text(String(format: "%@¥%.2f", transaction.amount >= 0 ? "+" : "-", abs(transaction.amount)))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(transaction.amount >= 0 ? .green : .primary)

                    Text(formatTime(transaction.date))
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showDeleteButton.toggle()
            }
        }
        .onTapGesture {
            if showDeleteButton {
                withAnimation {
                    showDeleteButton = false
                }
            } else {
                showDetail = true
            }
        }
        .sheet(isPresented: $showDetail) {
            TransactionDetailView(transaction: transaction)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 预算进度卡片 - 卡片式分组布局
struct BudgetProgressCard: View {
    let expense: Double
    let budget: Double
    let budgetUsagePercent: Double
    let remainingBudget: Double
    @EnvironmentObject var appState: AppState
    @State private var isShowingBudgetEditor = false

    var body: some View {
        Button(action: {
            isShowingBudgetEditor = true
        }) {
            ZStack {
                // 温暖的金橙渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.98, green: 0.87, blue: 0.42),
                        Color(red: 0.97, green: 0.45, blue: 0.14)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // 装饰圆形
                GeometryReader { geo in
                    Circle()
                        .fill(.white.opacity(0.06))
                        .frame(width: 190, height: 190)
                        .offset(x: geo.size.width - 60, y: -30)

                    Circle()
                        .fill(.white.opacity(0.04))
                        .frame(width: 110, height: 110)
                        .offset(x: -20, y: geo.size.height - 40)
                }

                VStack(spacing: 0) {
                    // 顶部标题
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("本月预算")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))

                            Text("预算 ¥\(String(format: "%.0f", budget))")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.white.opacity(0.65))
                        }

                        Spacer()

                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    Spacer()

                    // 中心：环形进度 + 剩余金额
                    HStack(spacing: 24) {
                        // 精致的环形进度
                        ZStack {
                            // 背景环
                            Circle()
                                .stroke(.white.opacity(0.25), lineWidth: 6)
                                .frame(width: 80, height: 80)

                            // 进度环
                            Circle()
                                .trim(from: 0, to: min(budgetUsagePercent / 100, 1.0))
                                .stroke(
                                    .white,
                                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                )
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))

                            // 中心百分比
                            VStack(spacing: 2) {
                                Text(String(format: "%.0f", budgetUsagePercent))
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("%")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }

                        // 剩余预算信息
                        VStack(alignment: .leading, spacing: 8) {
                            Text(remainingBudget >= 0 ? "还能花" : "超支了")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.75))

                            HStack(alignment: .firstTextBaseline, spacing: 1) {
                                Text("¥")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                Text(String(format: "%.0f", abs(remainingBudget)))
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .minimumScaleFactor(0.6)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    // 底部日均信息
                    let dailyAvailable = remainingBudget / Double(max(appState.daysRemainingInMonth, 1))
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 12))
                            Text("剩余 \(appState.daysRemainingInMonth) 天")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.75))

                        Spacer()

                        HStack(spacing: 5) {
                            Text("日均可用")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.65))

                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("¥")
                                    .font(.system(size: 12))
                                Text(String(format: "%.0f", abs(dailyAvailable)))
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .frame(height: 200)
            .cornerRadius(28)
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            .shadow(color: Color(red: 0.98, green: 0.87, blue: 0.42).opacity(0.15), radius: 24, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $isShowingBudgetEditor) {
            BudgetEditorView()
                .environmentObject(appState)
        }
    }
}

// MARK: - 预算编辑器
struct BudgetEditorView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var budgetInput: String = ""
    @State private var selectedPreset: Double?

    // 预设预算选项
    let presetBudgets: [Double] = [3000, 5000, 8000, 10000, 15000, 20000]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 当前预算显示
                    VStack(spacing: 12) {
                        Text("当前预算")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("¥")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(Color(red: 0.35, green: 0.45, blue: 0.95))
                            Text(String(format: "%.0f", appState.monthlyBudget))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.35, green: 0.45, blue: 0.95))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.35, green: 0.45, blue: 0.95).opacity(0.1),
                                Color(red: 0.45, green: 0.55, blue: 1.0).opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)

                    // 预设预算选项
                    VStack(alignment: .leading, spacing: 16) {
                        Text("快速选择")
                            .font(.system(size: 17, weight: .semibold))
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(presetBudgets, id: \.self) { preset in
                                Button(action: {
                                    selectedPreset = preset
                                    budgetInput = String(format: "%.0f", preset)
                                }) {
                                    VStack(spacing: 8) {
                                        Text("¥\(Int(preset))")
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundColor(selectedPreset == preset ? .white : Color(red: 0.35, green: 0.45, blue: 0.95))

                                        Text(budgetLabel(for: preset))
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(selectedPreset == preset ? .white.opacity(0.9) : .secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        selectedPreset == preset ?
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.35, green: 0.45, blue: 0.95),
                                                Color(red: 0.45, green: 0.55, blue: 1.0)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.96, green: 0.96, blue: 0.98),
                                                Color(red: 0.96, green: 0.96, blue: 0.98)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(16)
                                    .shadow(color: selectedPreset == preset ? Color(red: 0.35, green: 0.45, blue: 0.95).opacity(0.3) : .black.opacity(0.03), radius: selectedPreset == preset ? 10 : 4, x: 0, y: selectedPreset == preset ? 4 : 2)
                                }
                            }
                        }
                    }

                    // 自定义输入
                    VStack(alignment: .leading, spacing: 16) {
                        Text("自定义金额")
                            .font(.system(size: 17, weight: .semibold))
                            .padding(.horizontal, 4)

                        HStack(spacing: 12) {
                            Text("¥")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(Color(red: 0.35, green: 0.45, blue: 0.95))

                            TextField("输入预算金额", text: $budgetInput)
                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                                .keyboardType(.decimalPad)
                                .onChange(of: budgetInput) { _ in
                                    selectedPreset = nil
                                }
                        }
                        .padding(20)
                        .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                        .cornerRadius(16)
                    }

                    // 预算建议
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color.orange)
                            Text("预算建议")
                                .font(.system(size: 15, weight: .semibold))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            BudgetTipRow(icon: "chart.line.uptrend.xyaxis", text: "建议预算为月收入的60-70%")
                            BudgetTipRow(icon: "calendar", text: "可根据每月实际支出调整")
                            BudgetTipRow(icon: "bell.badge", text: "超过90%时会收到提醒")
                        }
                    }
                    .padding(20)
                    .background(Color.orange.opacity(0.05))
                    .cornerRadius(16)
                }
                .padding(20)
            }
            .background(Color(red: 0.97, green: 0.97, blue: 0.98))
            .navigationTitle("设置预算")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        saveBudget()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValidInput)
                }
            }
        }
        .onAppear {
            budgetInput = String(format: "%.0f", appState.monthlyBudget)
            if presetBudgets.contains(appState.monthlyBudget) {
                selectedPreset = appState.monthlyBudget
            }
        }
    }

    private var isValidInput: Bool {
        guard let value = Double(budgetInput), value > 0 else {
            return false
        }
        return true
    }

    private func saveBudget() {
        if let value = Double(budgetInput), value > 0 {
            appState.monthlyBudget = value
            dismiss()

            // 触觉反馈
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }

    private func budgetLabel(for amount: Double) -> String {
        switch amount {
        case 3000: return "节约型"
        case 5000: return "标准型"
        case 8000: return "舒适型"
        case 10000: return "宽松型"
        case 15000: return "充裕型"
        case 20000: return "自由型"
        default: return ""
        }
    }
}

// MARK: - 预算建议行
struct BudgetTipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    HomeView()
}
