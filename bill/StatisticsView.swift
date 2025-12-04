//
//  StatisticsView.swift
//  bill
//
//  Created by linjx on 2025/12/3.
//

import SwiftUI

struct StatisticsView: View {
    @State private var selectedPeriod = 0
    let periods = ["周", "月份", "年"]

    @State private var totalSpent: Double = 1240.50
    @State private var categoryData: [CategorySpending] = [
        CategorySpending(category: .food, amount: 480, percentage: 39),
        CategorySpending(category: .transport, amount: 280, percentage: 23),
        CategorySpending(category: .shopping, amount: 250, percentage: 20),
        CategorySpending(category: .entertainment, amount: 150, percentage: 12),
        CategorySpending(category: .other, amount: 80.50, percentage: 6)
    ]

    @State private var transactions: [Transaction] = [
        Transaction(merchantName: "星巴克",
                   description: "早餐咖啡",
                   amount: -35.00,
                   type: .expense,
                   category: .food,
                   icon: "cup.and.saucer.fill"),
        Transaction(merchantName: "地铁出行",
                   description: "上班通勤",
                   amount: -6.00,
                   type: .expense,
                   category: .transport,
                   icon: "tram.fill"),
        Transaction(merchantName: "超市购物",
                   description: "日用品采购",
                   amount: -128.50,
                   type: .expense,
                   category: .shopping,
                   icon: "cart.fill")
    ]

    struct CategorySpending: Identifiable {
        let id = UUID()
        let category: TransactionCategory
        let amount: Double
        let percentage: Double
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 时间段选择器
                    HStack(spacing: 12) {
                        ForEach(0..<periods.count, id: \.self) { index in
                            Button(action: {
                                selectedPeriod = index
                            }) {
                                Text(periods[index])
                                    .font(.system(size: 15, weight: selectedPeriod == index ? .semibold : .regular))
                                    .foregroundColor(selectedPeriod == index ? .white : .primary)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 10)
                                    .background(selectedPeriod == index ? Color.blue : Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    // 圆环图
                    ZStack {
                        // 圆环
                        DonutChart(data: categoryData, total: totalSpent)
                            .frame(width: 200, height: 200)

                        // 中心数字
                        VStack(spacing: 4) {
                            Text("\(totalSpent, specifier: "%.2f")元")
                                .font(.system(size: 28, weight: .bold))
                            Text("消费")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 20)

                    // 分类图例
                    HStack(spacing: 20) {
                        ForEach(categoryData) { item in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(item.category.color)
                                    .frame(width: 8, height: 8)
                                Text(item.category.rawValue)
                                    .font(.system(size: 13))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.horizontal)

                    // 交易列表
                    VStack(spacing: 0) {
                        HStack {
                            Text("支出明细")
                                .font(.system(size: 18, weight: .bold))
                            Spacer()
                            Button(action: {}) {
                                Text("查看全部")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)

                        ForEach(transactions) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                    }
                }
                .padding(.top)
            }
            .navigationTitle("账单统计")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

// 圆环图组件
struct DonutChart: View {
    let data: [StatisticsView.CategorySpending]
    let total: Double
    let lineWidth: CGFloat = 20

    var body: some View {
        ZStack {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                DonutSlice(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index),
                    color: item.category.color,
                    lineWidth: lineWidth
                )
            }
        }
    }

    private func startAngle(for index: Int) -> Angle {
        let previousPercentages = data.prefix(index).reduce(0.0) { $0 + $1.percentage }
        return Angle(degrees: previousPercentages * 3.6 - 90)
    }

    private func endAngle(for index: Int) -> Angle {
        let previousPercentages = data.prefix(index + 1).reduce(0.0) { $0 + $1.percentage }
        return Angle(degrees: previousPercentages * 3.6 - 90)
    }
}

// 圆环切片
struct DonutSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    let lineWidth: CGFloat

    var body: some View {
        Circle()
            .trim(from: 0, to: 1)
            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .fill(
                AngularGradient(
                    gradient: Gradient(colors: [color.opacity(0.7), color]),
                    center: .center,
                    startAngle: startAngle,
                    endAngle: endAngle
                )
            )
            .rotationEffect(startAngle)
            .overlay(
                Circle()
                    .trim(from: 0, to: (endAngle.degrees - startAngle.degrees) / 360)
                    .stroke(color, lineWidth: lineWidth)
                    .rotationEffect(startAngle)
            )
    }
}

#Preview {
    StatisticsView()
}
