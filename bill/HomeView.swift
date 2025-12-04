//
//  HomeView.swift
//  bill
//
//  Created by linjx on 2025/12/3.
//

import SwiftUI

struct HomeView: View {
    @State private var selectedAccount = "全部账户"
    @State private var accounts: [Account] = [
        Account(name: "我的账本", balance: 5259.85, accountType: "总资产",
                backgroundColor: [Color.blue.opacity(0.8), Color.blue.opacity(0.4)])
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
        Transaction(merchantName: "工资收入",
                   description: "月度工资",
                   amount: 8500.00,
                   type: .income,
                   category: .other,
                   icon: "yensign.circle.fill"),
        Transaction(merchantName: "超市购物",
                   description: "日用品采购",
                   amount: -128.50,
                   type: .expense,
                   category: .shopping,
                   icon: "cart.fill")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 顶部标题
                HStack {
                    Text("记账")
                        .font(.system(size: 28, weight: .bold))

                    Spacer()

                    // 添加记账按钮
                    Button(action: {}) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)


                // 账户卡片
                ForEach(accounts) { account in
                    AccountCardView(account: account)
                }
                .padding(.horizontal)

                // 交易列表
                VStack(spacing: 0) {
                    HStack {
                        Text("最近记录")
                            .font(.system(size: 18, weight: .bold))
                        Spacer()
                        Button(action: {}) {
                            Text("查看全部")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()

                    ForEach(transactions) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                }
            }
            .padding(.top)
        }
    }
}

// 账户卡片视图
struct AccountCardView: View {
    let account: Account

    var body: some View {
        VStack(spacing: 0) {
            // 总资产部分
            VStack(spacing: 8) {
                Text("总资产")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)

                Text("¥\(account.balance, specifier: "%.2f")")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 24)

            Divider()

            // 收支统计
            HStack(spacing: 0) {
                // 支出
                VStack(spacing: 8) {
                    Text("支出")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    Text("¥1,240")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                // 收入
                VStack(spacing: 8) {
                    Text("收入")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    Text("¥8,500")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 20)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 10)
    }
}


// 交易行视图
struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            // 分类图标
            Circle()
                .fill(transaction.category.color.opacity(0.2))
                .frame(width: 45, height: 45)
                .overlay(
                    Image(systemName: transaction.category.icon)
                        .foregroundColor(transaction.category.color)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchantName)
                    .font(.system(size: 16, weight: .medium))
                HStack(spacing: 4) {
                    Text(transaction.category.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(transaction.category.color.opacity(0.6))
                        .cornerRadius(4)
                    Text(transaction.description)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(transaction.amount >= 0 ? "+" : "")\(transaction.amount, specifier: "%.2f")元")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(transaction.amount >= 0 ? .green : .red)
                Text(transaction.date, style: .time)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
    }
}

#Preview {
    HomeView()
}
