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
            ScrollView {
                VStack(spacing: 20) {
                    // 月份切换和总支出
                    VStack(spacing: 16) {
                        // 月份切换
                        HStack {
                            Button(action: previousMonth) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.blue)
                            }

                            Spacer()

                            Text(monthYearString)
                                .font(.system(size: 20, weight: .bold))

                            Spacer()

                            Button(action: nextMonth) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)

                        // 本月总支出
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("本月支出")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                Text("¥\(monthlyTotal, specifier: "%.2f")")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.primary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("日均支出")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                Text("¥\(monthlyTotal / 30, specifier: "%.2f")")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .gray.opacity(0.1), radius: 10)
                        .padding(.horizontal)
                    }

                    // 日历视图
                    VStack(spacing: 0) {
                        // 星期标题
                        HStack(spacing: 0) {
                            ForEach(weekdaySymbols, id: \.self) { symbol in
                                Text(symbol)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.05))

                        // 日历网格
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                            ForEach(daysInMonth, id: \.self) { date in
                                CalendarDayCell(
                                    date: date,
                                    expense: expenseForDate(date),
                                    isSelected: isSameDay(date, selectedDate),
                                    isToday: isSameDay(date, Date())
                                )
                                .onTapGesture {
                                    selectedDate = date
                                }
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .gray.opacity(0.1), radius: 10)
                    .padding(.horizontal)

                    // 选中日期的详情
                    if let selected = selectedDate {
                        SelectedDateDetail(date: selected, expense: expenseForDate(selected))
                            .padding(.horizontal)
                    }
                }
                .padding(.top)
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
        VStack(spacing: 4) {
            // 日期数字
            Text(dayNumber)
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundColor(textColor)

            // 支出金额
            if let expense = expense, expense > 0 {
                Text("¥\(Int(expense))")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(expenseColor)
            } else {
                Text("-")
                    .font(.system(size: 10))
                    .foregroundColor(.clear)
            }
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: isToday ? 2 : 0)
        )
        .cornerRadius(8)
        .padding(2)
    }

    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .blue
        } else if !isCurrentMonth {
            return .gray.opacity(0.3)
        } else {
            return .primary
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return .blue.opacity(0.1)
        } else {
            return .clear
        }
    }

    private var borderColor: Color {
        isToday ? .blue : .clear
    }

    private var expenseColor: Color {
        if isSelected {
            return .white
        } else if let expense = expense {
            if expense > 200 {
                return .red
            } else if expense > 100 {
                return .orange
            } else {
                return .green
            }
        }
        return .gray
    }
}

// MARK: - Selected Date Detail

struct SelectedDateDetail: View {
    let date: Date
    let expense: Double?

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateString)
                        .font(.system(size: 16, weight: .semibold))
                    Text("当日支出")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                Spacer()

                if let expense = expense {
                    Text("¥\(expense, specifier: "%.2f")")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.red)
                } else {
                    Text("¥0.00")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.gray)
                }
            }

            // 可以添加当日交易列表
            if expense != nil && expense! > 0 {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("消费记录")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)

                    Text("暂无详细记录")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 10)
    }
}

#Preview {
    StatisticsView()
}
