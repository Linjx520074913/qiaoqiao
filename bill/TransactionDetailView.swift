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
                VStack(spacing: 0) {
                    // 账单收据样式
                    receiptView
                        .padding(.top, 30)
                        .padding(.bottom, 30)
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.95, blue: 0.97),
                        Color(red: 0.92, green: 0.92, blue: 0.95)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
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

    // MARK: - 收据样式视图
    private var receiptView: some View {
        VStack(spacing: 0) {
            // 收据纸张效果
            VStack(spacing: 0) {
                // 顶部装饰波浪
                topWaveEdge

                VStack(spacing: 0) {
                    // 头部 - 商户信息
                    receiptHeader

                    // 分割虚线
                    dashedDivider
                        .padding(.vertical, 20)

                    // 账单主体信息
                    receiptBody

                    // 分割虚线
                    dashedDivider
                        .padding(.vertical, 20)

                    // 金额区域
                    amountSection

                    // 分割虚线
                    dashedDivider
                        .padding(.vertical, 20)

                    // 底部信息
                    receiptFooter

                    // 图片附件（如果有）
                    if transaction.imageData != nil {
                        dashedDivider
                            .padding(.vertical, 20)
                        imageSection
                    }

                    // 操作按钮区域
                    dashedDivider
                        .padding(.vertical, 20)

                    actionSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                // 底部装饰波浪
                bottomWaveEdge
            }
            .background(Color.white)
            .cornerRadius(0)
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        }
        .padding(.horizontal, 20)
    }

    // 顶部波浪边缘
    private var topWaveEdge: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let waveHeight: CGFloat = 10
                let waveWidth: CGFloat = 15

                path.move(to: CGPoint(x: 0, y: waveHeight))

                var x: CGFloat = 0
                while x < width {
                    path.addLine(to: CGPoint(x: x + waveWidth / 2, y: 0))
                    path.addLine(to: CGPoint(x: x + waveWidth, y: waveHeight))
                    x += waveWidth
                }
            }
            .fill(Color.white)
        }
        .frame(height: 10)
    }

    // 底部波浪边缘
    private var bottomWaveEdge: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let waveHeight: CGFloat = 10
                let waveWidth: CGFloat = 15

                path.move(to: CGPoint(x: 0, y: 0))

                var x: CGFloat = 0
                while x < width {
                    path.addLine(to: CGPoint(x: x + waveWidth / 2, y: waveHeight))
                    path.addLine(to: CGPoint(x: x + waveWidth, y: 0))
                    x += waveWidth
                }
            }
            .fill(Color.white)
        }
        .frame(height: 10)
    }

    // 虚线分割线
    private var dashedDivider: some View {
        GeometryReader { geometry in
            Path { path in
                let dashWidth: CGFloat = 5
                let dashSpace: CGFloat = 5
                var x: CGFloat = 0

                while x < geometry.size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + dashWidth, y: 0))
                    x += dashWidth + dashSpace
                }
            }
            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        }
        .frame(height: 1)
    }

    // 收据头部
    private var receiptHeader: some View {
        VStack(spacing: 16) {
            // Logo区域
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                transaction.category.color.opacity(0.2),
                                transaction.category.color.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)

                Image(systemName: transaction.category.icon)
                    .font(.system(size: 32))
                    .foregroundColor(transaction.category.color)
            }
            .padding(.top, 20)

            // 商户名称
            Text(transaction.merchantName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            // 分类标签
            HStack(spacing: 8) {
                Text(transaction.category.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(transaction.category.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(transaction.category.color.opacity(0.15))
                    )

                Text(transaction.amount >= 0 ? "收入" : "支出")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(transaction.amount >= 0 ? .green : .red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill((transaction.amount >= 0 ? Color.green : Color.red).opacity(0.15))
                    )
            }
        }
    }

    // 收据主体
    private var receiptBody: some View {
        VStack(spacing: 14) {
            // 交易时间
            receiptRow(
                label: "交易时间",
                value: "\(formatDate(transaction.date)) \(formatTime(transaction.date))"
            )

            // 备注
            if !transaction.description.isEmpty && transaction.description != "无备注" {
                receiptRow(
                    label: "备注",
                    value: transaction.description
                )
            }

            // 账单ID
            receiptRow(
                label: "账单编号",
                value: String(transaction.id.prefix(12)).uppercased()
            )
        }
    }

    // 收据行
    private func receiptRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    // 金额区域
    private var amountSection: some View {
        VStack(spacing: 12) {
            // 小写金额
            HStack {
                Text("金额")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(transaction.amount >= 0 ? "+" : "-")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(transaction.amount >= 0 ? .green : .red)
                    Text("¥")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(transaction.amount >= 0 ? .green : .red)
                    Text(String(format: "%.2f", abs(transaction.amount)))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(transaction.amount >= 0 ? .green : .red)
                }
            }

            // 大写金额
            HStack {
                Text("大写")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                Text(numberToChinese(abs(transaction.amount)))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }

    // 收据底部
    private var receiptFooter: some View {
        VStack(spacing: 12) {
            HStack {
                Text("本账单由敲敲记账自动生成")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
            }

            HStack {
                Text("生成时间：\(formatDateTime(transaction.date))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
    }

    // 图片区域
    private var imageSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("账单图片")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }

            if let imageData = transaction.imageData,
               let uiImage = UIImage(data: imageData) {
                Button(action: {
                    showFullImage = true
                }) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .overlay(
                            ZStack {
                                Color.black.opacity(0.3)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                VStack(spacing: 4) {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                    Text("点击查看")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // 操作区域
    private var actionSection: some View {
        Button(action: {
            showDeleteConfirmation = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14))
                Text("删除账单")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.red.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
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
        formatter.dateFormat = "MM月dd日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm:ss"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    // 数字转中文大写
    private func numberToChinese(_ number: Double) -> String {
        let yuan = Int(number)
        let jiao = Int((number - Double(yuan)) * 10)
        let fen = Int((number - Double(yuan) - Double(jiao) * 0.1) * 100)

        let digits = ["零", "壹", "贰", "叁", "肆", "伍", "陆", "柒", "捌", "玖"]
        let units = ["", "拾", "佰", "仟", "万", "拾", "佰", "仟", "亿"]

        var result = ""
        var yuanStr = String(yuan)
        var index = yuanStr.count - 1

        for char in yuanStr {
            let digit = Int(String(char))!
            if digit != 0 {
                result += digits[digit] + units[index]
            } else if !result.isEmpty && !result.hasSuffix("零") {
                result += "零"
            }
            index -= 1
        }

        if result.isEmpty {
            result = "零"
        }

        result += "圆"

        if jiao == 0 && fen == 0 {
            result += "整"
        } else {
            if jiao != 0 {
                result += digits[jiao] + "角"
            }
            if fen != 0 {
                result += digits[fen] + "分"
            }
        }

        return result
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
