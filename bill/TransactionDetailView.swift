//
//  TransactionDetailView.swift
//  bill
//
//  Created by linjx on 2025/12/4.
//

import SwiftUI

struct TransactionDetailView: View {
    let transaction: Transaction
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 金额展示卡片
                    amountCard

                    // 详细信息
                    detailsSection

                    // 操作按钮
                    actionButtons

                    Color.clear.frame(height: 20)
                }
                .padding(.top, 20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("账单详情")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .alert("删除确认", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteTransaction()
            }
        } message: {
            Text("确定要删除这笔账单吗？此操作无法撤销。")
        }
    }

    // MARK: - 金额展示卡片
    private var amountCard: some View {
        VStack(spacing: 20) {
            // 分类图标
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                transaction.category.color.opacity(0.3),
                                transaction.category.color.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: transaction.category.icon)
                    .font(.system(size: 36))
                    .foregroundColor(transaction.category.color)
            }

            // 金额
            VStack(spacing: 8) {
                Text(transaction.amount >= 0 ? "收入" : "支出")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)

                Text("\(transaction.amount >= 0 ? "+" : "")¥\(abs(transaction.amount), specifier: "%.2f")")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(transaction.amount >= 0 ? .green : .red)
            }

            // 商户名称
            Text(transaction.merchantName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10)
        .padding(.horizontal, 20)
    }

    // MARK: - 详细信息
    private var detailsSection: some View {
        VStack(spacing: 0) {
            DetailRow(
                icon: "tag.fill",
                iconColor: transaction.category.color,
                title: "分类",
                value: transaction.category.rawValue
            )

            Divider()
                .padding(.leading, 60)

            DetailRow(
                icon: "doc.text.fill",
                iconColor: .blue,
                title: "备注",
                value: transaction.description
            )

            Divider()
                .padding(.leading, 60)

            DetailRow(
                icon: "calendar",
                iconColor: .orange,
                title: "日期",
                value: formatDate(transaction.date)
            )

            Divider()
                .padding(.leading, 60)

            DetailRow(
                icon: "clock.fill",
                iconColor: .purple,
                title: "时间",
                value: formatTime(transaction.date)
            )

            Divider()
                .padding(.leading, 60)

            DetailRow(
                icon: "number",
                iconColor: .gray,
                title: "账单ID",
                value: String(transaction.id.prefix(8))
            )
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
        .padding(.horizontal, 20)
    }

    // MARK: - 操作按钮
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 删除按钮
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16))
                    Text("删除账单")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Helper Functions
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    private func deleteTransaction() {
        appState.deleteTransaction(transaction)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - 详情行组件
struct DetailRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            // 图标
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            // 标题和值
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)

                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

#Preview {
    TransactionDetailView(transaction: Transaction(
        merchantName: "星巴克",
        description: "早餐咖啡",
        amount: -35.00,
        type: .expense,
        category: .food,
        icon: "cup.and.saucer.fill"
    ))
    .environmentObject(AppState())
}
