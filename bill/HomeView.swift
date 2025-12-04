//
//  HomeView.swift
//  bill
//
//  Created by linjx on 2025/12/3.
//

import SwiftUI

struct HomeView: View {
    @State private var selectedCurrency = "美元"
    @State private var cards: [BankCard] = [
        BankCard(name: "Finpay卡", balance: 2736.15, lastFourDigits: "5318",
                backgroundColor: [Color.blue.opacity(0.8), Color.blue.opacity(0.4)])
    ]
    @State private var transactions: [Transaction] = [
        Transaction(merchantName: "苹果商店",
                   description: "iPhone 12 保护壳",
                   amount: -120.90,
                   type: .expense,
                   category: .other,
                   icon: "applelogo"),
        Transaction(merchantName: "伊利亚",
                   description: "iPhone 12 保护壳",
                   amount: -120.90,
                   type: .expense,
                   category: .food,
                   icon: "e.circle.fill"),
        Transaction(merchantName: "伊利亚",
                   description: "iPhone 12 保护壳",
                   amount: -120.90,
                   type: .expense,
                   category: .food,
                   icon: "e.circle.fill")
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
                        Text("李·詹姆斯")
                            .font(.system(size: 20, weight: .bold))
                    }

                    Spacer()

                    // 会员标识
                    HStack(spacing: 4) {
                        Text("👑")
                        Text("黄金")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange)
                    }

                    // 头像
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)

                // 货币选择和添加货币按钮
                HStack {
                    HStack(spacing: 8) {
                        Text("美元")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)

                        Text("IDR")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 12))
                            Text("添加货币")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)

                // 银行卡轮播
                TabView {
                    ForEach(cards) { card in
                        CardView(card: card)
                    }
                }
                .frame(height: 200)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))

                // 快捷操作按钮
                HStack(spacing: 40) {
                    QuickActionButton(icon: "arrow.down.circle.fill", title: "充值", color: .blue)
                    QuickActionButton(icon: "arrow.counterclockwise.circle.fill", title: "撤回", color: .blue)
                    QuickActionButton(icon: "arrow.left.arrow.right.circle.fill", title: "转移", color: .blue)
                }
                .padding(.horizontal)

                // 交易列表
                VStack(spacing: 0) {
                    HStack {
                        Text("交易")
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

// 银行卡视图
struct CardView: View {
    let card: BankCard

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(gradient: Gradient(colors: card.backgroundColor),
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
                    Image(systemName: "bolt.fill")
                    Text(card.name)
                        .font(.system(size: 16))
                    Spacer()
                    Image(systemName: "cloud.fill")
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                HStack {
                    Text("¥\(card.balance, specifier: "%.2f")")
                        .font(.system(size: 28, weight: .bold))
                    Image(systemName: "eye.slash")
                        .font(.system(size: 14))
                }

                HStack {
                    Text("••••")
                        .font(.system(size: 20))
                        .tracking(2)
                    Text(card.lastFourDigits)
                        .font(.system(size: 16))
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
            // 商家图标
            Circle()
                .fill(transaction.category == .other ? Color.black : Color.gray.opacity(0.2))
                .frame(width: 45, height: 45)
                .overlay(
                    Image(systemName: transaction.icon)
                        .foregroundColor(transaction.category == .other ? .white : .gray)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchantName)
                    .font(.system(size: 16, weight: .medium))
                HStack(spacing: 4) {
                    Image(systemName: transaction.type == .expense ? "arrow.up" : "arrow.down")
                        .font(.system(size: 10))
                        .foregroundColor(transaction.type == .expense ? .red : .green)
                    Text(transaction.description)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(transaction.amount, specifier: "%.2f")元")
                    .font(.system(size: 16, weight: .medium))
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
