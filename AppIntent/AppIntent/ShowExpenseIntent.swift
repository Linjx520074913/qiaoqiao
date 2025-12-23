//
//  ShowExpenseIntent.swift
//  AppIntent
//
//  Created by linjx on 2025/12/22.
//

import AppIntents
import SwiftUI

struct ShowExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "显示消费卡片"
    static var description = IntentDescription("扫描账单图片并显示消费提醒卡片")

    // 后台运行，不打开应用
    static var openAppWhenRun: Bool = false

    // 接收图片参数（必需）
    @Parameter(title: "账单图片", description: "从快捷指令传入的截图")
    var image: IntentFile

    static var parameterSummary: some ParameterSummary {
        Summary("识别\(\.$image)并显示消费信息")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        print("🚀 [Intent] 开始处理...")

        // 转换为 UIImage
        let imageData = image.data
        guard let uiImage = UIImage(data: imageData) else {
            print("❌ [Intent] 图片转换失败")

            return .result(
                dialog: IntentDialog("图片格式错误，无法解析"),
                view: ExpenseSnippetView(
                    merchant: "错误",
                    amount: 0,
                    status: "图片格式错误",
                    isLoading: false
                )
            )
        }

        print("📸 [Intent] 图片已加载，开始识别...")

        // 调用后端接口识别
        do {
            let scanService = BillScanService.shared

            print("⏳ [Intent] 正在上传图片并识别...")
            let response = try await scanService.scanBill(image: uiImage)

            if response.success, let data = response.data, let invoice = data.invoice {
                let merchant = invoice.merchant ?? "未知商家"
                let amount = invoice.total ?? 0.0

                print("✅ [Intent] 识别成功: \(merchant) - ¥\(amount)")

                // 添加性能信息
                var performanceInfo = ""
                if let perf = response.performance {
                    let totalTime = perf.total ?? 0
                    performanceInfo = String(format: "耗时 %.1f秒", totalTime)
                    print("⏱️ [Intent] 总耗时: \(totalTime)秒")
                }

                // 生成简洁的对话框消息（用于通知）
                let dialogText = "¥\(String(format: "%.2f", amount)) - \(merchant)"

                return .result(
                    dialog: IntentDialog(stringLiteral: dialogText),
                    view: ExpenseSnippetView(
                        merchant: merchant,
                        amount: amount,
                        date: invoice.date,
                        time: invoice.time,
                        status: performanceInfo.isEmpty ? "识别成功" : performanceInfo,
                        isLoading: false
                    )
                )
            } else {
                let errorMsg = response.error ?? "识别失败"
                print("❌ [Intent] 识别失败: \(errorMsg)")

                return .result(
                    dialog: IntentDialog(stringLiteral: errorMsg),
                    view: ExpenseSnippetView(
                        merchant: "识别失败",
                        amount: 0,
                        status: errorMsg,
                        isLoading: false
                    )
                )
            }
        } catch let error as NSError {
            // 详细的错误信息
            var errorMsg: String
            var debugInfo: String = ""

            if error.domain == NSURLErrorDomain {
                switch error.code {
                case NSURLErrorTimedOut:
                    errorMsg = "连接超时"
                case NSURLErrorCannotConnectToHost:
                    errorMsg = "无法连接到服务器"
                case NSURLErrorNetworkConnectionLost:
                    errorMsg = "网络连接已断开"
                case NSURLErrorNotConnectedToInternet:
                    errorMsg = "本地网络被拒绝"
                    debugInfo = "请到设置→隐私→本地网络，允许AppIntent访问"
                default:
                    errorMsg = "网络错误 \(error.code)"
                }
            } else {
                errorMsg = error.localizedDescription
            }

            print("❌ [Intent] 错误: \(errorMsg)")
            print("❌ [Intent] 详细: \(error)")

            // 提取更多调试信息
            let userInfo = error.userInfo
            if let underlyingError = userInfo["NSUnderlyingError"] as? NSError {
                debugInfo += "\nCode: \(underlyingError.code)"
            }
            if let urlString = userInfo["NSErrorFailingURLStringKey"] as? String {
                debugInfo += "\nURL: \(urlString)"
            }

            return .result(
                dialog: IntentDialog(stringLiteral: errorMsg),
                view: ExpenseSnippetView(
                    merchant: errorMsg,
                    amount: 0,
                    status: debugInfo.isEmpty ? error.localizedDescription : debugInfo,
                    isLoading: false
                )
            )
        }
    }
}

// 自定义卡片视图
struct ExpenseSnippetView: View {
    let merchant: String
    let amount: Double
    var date: String? = nil
    var time: String? = nil
    var status: String? = nil
    var isLoading: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部：商家和金额
            HStack(spacing: 12) {
                // 图标
                ZStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Image(systemName: merchant.contains("错误") || merchant.contains("网络") ? "exclamationmark.triangle.fill" : "creditcard.fill")
                            .font(.title2)
                            .foregroundColor(merchant.contains("错误") || merchant.contains("网络") ? .red : .blue)
                    }
                }
                .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(merchant)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    if amount > 0, let time = time {
                        Text(time)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if amount > 0 {
                    Text("¥\(String(format: "%.2f", amount))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }

            // 状态信息或日期
            if let status = status, !status.isEmpty {
                Divider()
                HStack {
                    if status.contains("耗时") {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else if status == "识别成功" {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    Text(status)
                        .font(.caption)
                        .foregroundColor(status.contains("成功") || status.contains("耗时") ? .green : .red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if let date = date {
                Divider()
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
