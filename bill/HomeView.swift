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
                // 顶部问候和头像
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("早上好，")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text("记账小助手")
                            .font(.system(size: 20, weight: .bold))
                    }

                    Spacer()

                    // 自动记账标识
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        Text("自动记账")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)

                    // 头像
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)

                // 账本选择和添加账本按钮
                HStack {
                    HStack(spacing: 8) {
                        Text("全部账户")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)

                        Text("现金")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)

                        Text("银行卡")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 12))
                            Text("记一笔")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)

                // 账户卡片轮播
                TabView {
                    ForEach(accounts) { account in
                        AccountCardView(account: account)
                    }
                }
                .frame(height: 200)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))

                // 快捷操作按钮
                HStack(spacing: 40) {
                    QuickActionButton(icon: "plus.circle.fill", title: "记支出", color: .red)
                    QuickActionButton(icon: "arrow.down.circle.fill", title: "记收入", color: .green)
                    QuickActionButton(icon: "arrow.left.arrow.right.circle.fill", title: "转账", color: .blue)
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
        ZStack {
            // 背景渐变
            LinearGradient(gradient: Gradient(colors: account.backgroundColor),
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing)
                .cornerRadius(20)

            // 装饰性图形
            GeometryReader { geometry in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 150, height: 150)
                    .offset(x: geometry.size.width - 80, y: -30)

                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .offset(x: geometry.size.width - 50, y: geometry.size.height - 50)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "wallet.pass.fill")
                    Text(account.name)
                        .font(.system(size: 16))
                    Spacer()
                    Text(account.accountType)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("总资产")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                    HStack {
                        Text("¥\(account.balance, specifier: "%.2f")")
                            .font(.system(size: 32, weight: .bold))
                        Image(systemName: "eye.slash")
                            .font(.system(size: 14))
                    }
                }

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("本月支出")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                        Text("¥1,240")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("本月收入")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                        Text("¥8,500")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
            }
            .foregroundColor(.white)
            .padding(24)
        }
        .frame(height: 180)
        .padding(.horizontal)
    }
}

// 快捷操作按钮
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color.white)
                .frame(width: 60, height: 60)
                .shadow(color: .gray.opacity(0.2), radius: 10)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                )

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.primary)
        }
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
