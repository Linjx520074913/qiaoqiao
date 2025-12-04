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
                    HStack(spacing: 0) {
                        ForEach(0..<periods.count, id: \.self) { index in
                            Button(action: {
                                selectedPeriod = index
                            }) {
                                Text(periods[index])
                                    .font(.system(size: 15, weight: selectedPeriod == index ? .semibold : .regular))
                                    .foregroundColor(selectedPeriod == index ? .white : .gray)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selectedPeriod == index ? Color.blue : Color.clear)
                            }
                        }
                    }
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)

                    // 总支出金额
                    VStack(spacing: 8) {
                        Text("本月支出")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text("¥\(totalSpent, specifier: "%.2f")")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 20)

                    // 分类列表
                    VStack(spacing: 12) {
                        ForEach(categoryData) { item in
                            HStack {
                                // 分类图标
                                Image(systemName: item.category.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(item.category.color)
                                    .frame(width: 40, height: 40)
                                    .background(item.category.color.opacity(0.1))
                                    .cornerRadius(10)

                                // 分类名称
                                Text(item.category.rawValue)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)

                                Spacer()

                                // 金额和百分比
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("¥\(item.amount, specifier: "%.2f")")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Text("\(Int(item.percentage))%")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)

                }
                .padding(.top)
            }
            .navigationTitle("统计")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    StatisticsView()
}
