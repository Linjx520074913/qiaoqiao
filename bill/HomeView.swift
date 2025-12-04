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
                VStack(spacing: 20) {
                    // 顶部问候语
                    greetingHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // 本月概览
                    monthlyOverview
                        .padding(.horizontal, 20)

                    // 交易列表
                    transactionList

                    // 底部占位
                    Color.clear.frame(height: 80)
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color.white
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

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

    // 问候语头部
    private var greetingHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)

                Text(dateText)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }

            Spacer()

            // 头像
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.6),
                            Color.purple.opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                )
        }
    }

    // 本月概览
    private var monthlyOverview: some View {
        VStack(spacing: 16) {
            HStack {
                Text("本月概览")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Text(currentMonthText)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }

            // 整合的月度财务卡片
            MonthlyFinanceCard(
                income: appState.monthlyIncome,
                expense: appState.monthlyExpense,
                budget: 5000.0 // 暂时硬编码预算值
            )
        }
    }

    // 交易列表
    private var transactionList: some View {
        VStack(spacing: 12) {
            HStack {
                Text("最近交易")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                if !transactions.isEmpty {
                    Text("\(transactions.count) 笔")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
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
            Image(systemName: "tray")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.3))

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
        VStack(spacing: 0) {
            ForEach(transactions.prefix(10)) { transaction in
                TransactionRow(
                    transaction: transaction,
                    onDelete: {
                        deleteTransaction(transaction)
                    }
                )

                if transaction.id != transactions.prefix(10).last?.id {
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

    // 悬浮添加按钮
    private var floatingAddButton: some View {
        Button(action: {
            isShowingAddTransaction = true
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue,
                                Color.blue.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)

                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
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
        VStack(spacing: 20) {
            // 收入和支出行
            HStack(spacing: 16) {
                // 收入
                FinanceItem(
                    icon: "arrow.down.circle.fill",
                    iconColor: Color(red: 0.4, green: 0.78, blue: 0.47),
                    title: "收入",
                    amount: income,
                    backgroundColor: Color(red: 0.4, green: 0.78, blue: 0.47).opacity(0.12)
                )

                // 支出
                FinanceItem(
                    icon: "arrow.up.circle.fill",
                    iconColor: Color(red: 0.95, green: 0.47, blue: 0.45),
                    title: "支出",
                    amount: expense,
                    backgroundColor: Color(red: 0.95, green: 0.47, blue: 0.45).opacity(0.12)
                )
            }

            // 预算部分
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))

                        Text("预算")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Text(String(format: "%.0f%%", budgetUsagePercent))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(budgetUsagePercent > 90 ? Color(red: 0.95, green: 0.47, blue: 0.45) : .gray)
                }

                // 预算进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 8)

                        // 进度
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        budgetUsagePercent > 90 ? Color(red: 0.95, green: 0.47, blue: 0.45) : Color(red: 0.4, green: 0.6, blue: 1.0),
                                        budgetUsagePercent > 90 ? Color(red: 0.95, green: 0.47, blue: 0.45).opacity(0.7) : Color(red: 0.5, green: 0.7, blue: 1.0)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(budgetUsagePercent / 100), height: 8)
                    }
                }
                .frame(height: 8)

                // 预算金额信息
                HStack {
                    Text(String(format: "剩余 ¥%.2f", remainingBudget))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)

                    Spacer()

                    Text(String(format: "总额 ¥%.2f", budget))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
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


// 交易行视图
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

#Preview {
    HomeView()
}
