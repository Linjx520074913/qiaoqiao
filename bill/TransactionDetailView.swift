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
    @State private var showFullImage = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 金额展示卡片 - 更紧凑的设计
                    amountCard

                    // 详细信息 - 全新设计
                    detailsSection

                    // 操作按钮
                    actionButtons

                    Color.clear.frame(height: 20)
                }
                .padding(.top, 20)
            }
            .background(Color(red: 0.97, green: 0.97, blue: 0.98))
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
        .fullScreenCover(isPresented: $showFullImage) {
            if let imageData = transaction.imageData,
               let uiImage = UIImage(data: imageData) {
                FullImageView(image: uiImage, isPresented: $showFullImage)
            }
        }
    }

    // MARK: - 金额展示卡片（渐变设计）
    private var amountCard: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                gradient: Gradient(colors: transaction.amount >= 0 ? [
                    Color(red: 0.2, green: 0.78, blue: 0.35),
                    Color(red: 0.15, green: 0.68, blue: 0.30)
                ] : [
                    Color(red: 0.35, green: 0.45, blue: 0.95),
                    Color(red: 0.25, green: 0.35, blue: 0.85)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 装饰性圆形
            GeometryReader { geo in
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 150, height: 150)
                    .offset(x: geo.size.width - 60, y: -30)

                Circle()
                    .fill(.white.opacity(0.05))
                    .frame(width: 100, height: 100)
                    .offset(x: -20, y: geo.size.height - 40)
            }

            VStack(spacing: 16) {
                // 分类标签
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.25))
                            .frame(width: 32, height: 32)
                        Image(systemName: transaction.category.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Text(transaction.category.rawValue)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))

                    Spacer()

                    // 类型标签
                    HStack(spacing: 6) {
                        Image(systemName: transaction.amount >= 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .font(.system(size: 12))
                        Text(transaction.amount >= 0 ? "收入" : "支出")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.95))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.white.opacity(0.2)))
                }

                // 商户名称
                HStack {
                    Text(transaction.merchantName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }

                // 金额
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(transaction.amount >= 0 ? "+" : "-")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    Text("¥")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    Text(String(format: "%.2f", abs(transaction.amount)))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                }
            }
            .padding(24)
        }
        .frame(height: 180)
        .cornerRadius(24)
        .shadow(color: (transaction.amount >= 0 ? Color(red: 0.2, green: 0.78, blue: 0.35) : Color(red: 0.35, green: 0.45, blue: 0.95)).opacity(0.3), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 20)
    }

    // MARK: - 详细信息（新设计）
    private var detailsSection: some View {
        VStack(spacing: 12) {
            // 时间和备注组合
            VStack(spacing: 12) {
                // 交易时间
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.95, green: 0.95, blue: 0.97))
                            .frame(width: 44, height: 44)
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 18))
                            .foregroundColor(Color(red: 0.35, green: 0.45, blue: 0.95))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("交易时间")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("\(formatDate(transaction.date)) \(formatTime(transaction.date))")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    Spacer()
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)

                // 备注
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.95, green: 0.95, blue: 0.97))
                            .frame(width: 44, height: 44)
                        Image(systemName: "note.text")
                            .font(.system(size: 18))
                            .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.50))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("备注")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(transaction.description.isEmpty ? "无备注" : transaction.description)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)

                // 图片附件（小缩略图）
                if let imageData = transaction.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Button(action: {
                        showFullImage = true
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(red: 0.95, green: 0.95, blue: 0.97))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("账单图片")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text("点击查看原图")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)
                            }

                            Spacer()

                            // 缩略图
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // 账单ID
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.95, green: 0.95, blue: 0.97))
                            .frame(width: 44, height: 44)
                        Image(systemName: "number.square.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("账单ID")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(String(transaction.id.prefix(12)))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
            }
        }
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
        formatter.dateFormat = "MM月dd日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func deleteTransaction() {
        appState.deleteTransaction(transaction)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - 全屏图片查看器
struct FullImageView: View {
    let image: UIImage
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            scale = min(max(scale * delta, 1), 4)
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                            if scale < 1 {
                                withAnimation {
                                    scale = 1
                                    offset = .zero
                                }
                            }
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if scale > 1 {
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )

            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 44, height: 44)
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(20)
                }
                Spacer()
            }
        }
        .statusBar(hidden: true)
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
