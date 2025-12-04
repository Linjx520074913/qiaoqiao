//
//  StatisticsView.swift
//  bill
//
//  Created by linjx on 2025/12/3.
//

import SwiftUI

struct StatisticsView: View {
    @State private var currentDate = Date()
    @State private var selectedDate: Date?
    @State private var isDetailExpanded = false
    @Namespace private var animation

    // 模拟每日支出数据
    @State private var dailyExpenses: [Date: Double] = {
        var expenses: [Date: Double] = [:]
        let calendar = Calendar.current
        let today = Date()

        // 生成本月的模拟数据
        for day in 1...30 {
            if let date = calendar.date(byAdding: .day, value: -day, to: today) {
                expenses[calendar.startOfDay(for: date)] = Double.random(in: 0...300)
            }
        }
        return expenses
    }()

    private var monthlyTotal: Double {
        dailyExpenses.values.reduce(0, +)
    }

    private var calendar: Calendar {
        Calendar.current
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // 背景色
                Color(red: 0.97, green: 0.97, blue: 0.98)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 月份切换和总支出
                        VStack(spacing: 16) {
                            // 月份切换
                            HStack {
                                Button(action: previousMonth) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 40, height: 40)
                                            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)

                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color(red: 0.35, green: 0.45, blue: 0.95))
                                    }
                                }

                                Spacer()

                                Text(monthYearString)
                                    .font(.system(size: 22, weight: .bold))

                                Spacer()

                                Button(action: nextMonth) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 40, height: 40)
                                            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color(red: 0.35, green: 0.45, blue: 0.95))
                                    }
                                }
                            }
                            .padding(.horizontal, 20)

                            // 本月总支出 - 渐变卡片
                            if !isDetailExpanded {
                                VStack(spacing: 16) {
                                    HStack {
                                        Text("本月支出")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.9))
                                        Spacer()
                                        Image(systemName: "chart.bar.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white.opacity(0.9))
                                    }

                                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                                        Text("¥")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.8))
                                        Text(String(format: "%.2f", monthlyTotal))
                                            .font(.system(size: 36, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        Spacer()
                                    }

                                    HStack {
                                        Text("日均支出")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.white.opacity(0.75))
                                        Spacer()
                                        Text(String(format: "¥%.2f", monthlyTotal / 30))
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundColor(.white.opacity(0.95))
                                    }
                                }
                                .padding(24)
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
                                                .frame(width: 120, height: 120)
                                                .offset(x: geo.size.width - 60, y: -30)
                                        }
                                    }
                                )
                                .cornerRadius(20)
                                .shadow(color: Color(red: 0.35, green: 0.45, blue: 0.95).opacity(0.4), radius: 20, x: 0, y: 8)
                                .padding(.horizontal, 20)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }

                        // 日历视图
                        VStack(spacing: 0) {
                            // 星期标题
                            HStack(spacing: 0) {
                                ForEach(weekdaySymbols, id: \.self) { symbol in
                                    Text(symbol)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.vertical, 16)
                            .background(Color(red: 0.96, green: 0.96, blue: 0.97))

                            // 日历网格 - 详情展开时缩小高度
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                                ForEach(daysInMonth, id: \.self) { date in
                                    CalendarDayCell(
                                        date: date,
                                        expense: expenseForDate(date),
                                        isSelected: isSameDay(date, selectedDate),
                                        isToday: isSameDay(date, Date()),
                                        isCompact: isDetailExpanded
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            if isSameDay(date, selectedDate) {
                                                selectedDate = nil
                                                isDetailExpanded = false
                                            } else {
                                                selectedDate = date
                                                isDetailExpanded = true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                        .padding(.horizontal, 20)

                        // 详情面板 - 从底部滑入
                        if isDetailExpanded, let selected = selectedDate {
                            ExpandedDateDetail(
                                date: selected,
                                expense: expenseForDate(selected),
                                onClose: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        selectedDate = nil
                                        isDetailExpanded = false
                                    }
                                }
                            )
                            .padding(.horizontal)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            ))
                        }

                        // 占位空间
                        Color.clear.frame(height: 100)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("统计")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Helper Functions

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: currentDate)
    }

    private var weekdaySymbols: [String] {
        ["日", "一", "二", "三", "四", "五", "六"]
    }

    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentDate),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var dates: [Date] = []
        var date = monthFirstWeek.start

        while date < monthInterval.end {
            dates.append(date)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = nextDate
        }

        // 补齐到完整的周
        while dates.count % 7 != 0 {
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: dates.last!) else { break }
            dates.append(nextDate)
        }

        return dates
    }

    private func expenseForDate(_ date: Date) -> Double? {
        let dateKey = calendar.startOfDay(for: date)
        return dailyExpenses[dateKey]
    }

    private func isSameDay(_ date1: Date?, _ date2: Date?) -> Bool {
        guard let date1 = date1, let date2 = date2 else { return false }
        return calendar.isDate(date1, inSameDayAs: date2)
    }

    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = newDate
        }
    }

    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = newDate
        }
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let expense: Double?
    let isSelected: Bool
    let isToday: Bool
    let isCompact: Bool

    private var calendar: Calendar {
        Calendar.current
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var isCurrentMonth: Bool {
        calendar.component(.month, from: date) == calendar.component(.month, from: Date())
    }

    var body: some View {
        VStack(spacing: isCompact ? 2 : 6) {
            // 日期数字
            Text(dayNumber)
                .font(.system(size: isCompact ? 14 : 17, weight: isToday ? .bold : .semibold, design: .rounded))
                .foregroundColor(textColor)

            // 支出金额
            if let expense = expense, expense > 0 {
                Text("¥\(Int(expense))")
                    .font(.system(size: isCompact ? 8 : 11, weight: .semibold))
                    .foregroundColor(expenseColor)
            } else {
                Text("-")
                    .font(.system(size: isCompact ? 8 : 11))
                    .foregroundColor(.clear)
            }
        }
        .frame(height: isCompact ? 44 : 64)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: isCompact ? 8 : 12)
                .stroke(borderColor, lineWidth: isToday ? 2.5 : 0)
        )
        .cornerRadius(isCompact ? 8 : 12)
        .padding(isCompact ? 2 : 3)
    }

    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return Color(red: 0.35, green: 0.45, blue: 0.95)
        } else if !isCurrentMonth {
            return .gray.opacity(0.3)
        } else {
            return .primary
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color(red: 0.35, green: 0.45, blue: 0.95)
        } else if isToday {
            return Color(red: 0.35, green: 0.45, blue: 0.95).opacity(0.12)
        } else {
            return .clear
        }
    }

    private var borderColor: Color {
        isToday ? Color(red: 0.35, green: 0.45, blue: 0.95) : .clear
    }

    private var expenseColor: Color {
        if isSelected {
            return .white.opacity(0.9)
        } else if let expense = expense {
            if expense > 200 {
                return Color(red: 0.95, green: 0.47, blue: 0.45)
            } else if expense > 100 {
                return Color(red: 0.95, green: 0.60, blue: 0.35)
            } else {
                return Color(red: 0.2, green: 0.78, blue: 0.35)
            }
        }
        return .gray
    }
}

// MARK: - Expanded Date Detail

struct ExpandedDateDetail: View {
    let date: Date
    let expense: Double?
    let onClose: () -> Void

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("当日详情")
                    .font(.system(size: 18, weight: .bold))

                Spacer()

                Button(action: onClose) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.95, green: 0.95, blue: 0.97))
                            .frame(width: 32, height: 32)

                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(20)
            .background(Color.white)

            // 日期和金额 - 渐变卡片
            VStack(spacing: 16) {
                Text(dateString)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("¥")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    if let expense = expense {
                        Text(String(format: "%.2f", expense))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    } else {
                        Text("0.00")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Text("当日支出")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
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
                            .frame(width: 100, height: 100)
                            .offset(x: geo.size.width - 50, y: -25)
                    }
                }
            )

            // 消费记录
            VStack(alignment: .leading, spacing: 16) {
                Text("消费记录")
                    .font(.system(size: 16, weight: .semibold))

                if expense != nil && expense! > 0 {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(red: 0.95, green: 0.95, blue: 0.97))
                                    .frame(width: 44, height: 44)

                                Image(systemName: "cart.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.secondary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("暂无详细记录")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)

                                Text("等待同步交易数据")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(16)
                        .background(Color(red: 0.97, green: 0.97, blue: 0.98))
                        .cornerRadius(12)
                    }
                } else {
                    Text("今日无消费")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                }
            }
            .padding(20)
            .background(Color.white)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
    }
}

#Preview {
    StatisticsView()
}
