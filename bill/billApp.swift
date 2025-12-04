//
//  billApp.swift
//  bill
//
//  Created by linjx on 2025/12/3.
//

import SwiftUI

@main
struct billApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onOpenURL { url in
                    handleURL(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    handleUserActivity(userActivity)
                }
        }
    }

    private func handleURL(_ url: URL) {
        print("📱 Received URL: \(url)")
        print("📱 URL Scheme: \(url.scheme ?? "nil")")
        print("📱 URL Host: \(url.host ?? "nil")")
        print("📱 URL Path: \(url.path)")
        print("📱 URL Query: \(url.query ?? "nil")")

        // 支持多种URL格式
        guard url.scheme == "bill" || url.scheme == "shortcuts" else {
            print("❌ Unsupported scheme")
            return
        }

        // 尝试多种方式获取图片数据
        var receivedImage: UIImage?

        // 1. 检查URL参数中的base64数据
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {

            // 检查 data 参数
            if let dataItem = queryItems.first(where: { $0.name == "data" }),
               let base64String = dataItem.value {
                if let imageData = Data(base64Encoded: base64String),
                   let image = UIImage(data: imageData) {
                    print("✅ Found image in URL data parameter")
                    receivedImage = image
                }
            }

            // 检查 image 参数
            if receivedImage == nil,
               let imageItem = queryItems.first(where: { $0.name == "image" }),
               let base64String = imageItem.value {
                if let imageData = Data(base64Encoded: base64String),
                   let image = UIImage(data: imageData) {
                    print("✅ Found image in URL image parameter")
                    receivedImage = image
                }
            }
        }

        // 2. 检查URL的完整路径（可能整个path就是base64）
        if receivedImage == nil {
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if !pathComponents.isEmpty {
                let combinedPath = pathComponents.joined(separator: "")
                if let imageData = Data(base64Encoded: combinedPath),
                   let image = UIImage(data: imageData) {
                    print("✅ Found image in URL path")
                    receivedImage = image
                }
            }
        }

        // 3. 如果URL没有图片，检查剪贴板
        if receivedImage == nil {
            if UIPasteboard.general.hasImages,
               let image = UIPasteboard.general.image {
                print("✅ Found image in pasteboard")
                receivedImage = image
            }
        }

        // 如果找到图片，直接处理
        if let image = receivedImage {
            print("✅ 图片获取成功，尺寸: \(image.size.width)x\(image.size.height)")
            print("🔄 开始后台OCR识别...")

            // 直接设置到appState，触发MainTabView的onChange
            DispatchQueue.main.async {
                self.appState.receivedImage = image
            }
        } else {
            print("⚠️ No image found in URL or pasteboard")
        }
    }

    private func handleUserActivity(_ userActivity: NSUserActivity) {
        print("📱 Received UserActivity: \(userActivity.activityType)")
        // 处理其他可能的输入方式
    }
}

// 待确认的账单信息
struct PendingBill: Identifiable {
    let id = UUID()
    let merchantName: String
    let amount: Double
    let type: TransactionType
    let category: TransactionCategory
    let description: String?
    let date: Date
    let icon: String
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var shouldShowImageParser = false
    @Published var receivedImage: UIImage?
    @Published var transactions: [Transaction] = []
    @Published var pendingBills: [PendingBill] = []
    @Published var currentBillIndex = 0

    // 计算属性：总资产
    var totalBalance: Double {
        // 初始资产 + 所有交易金额
        let initialBalance: Double = 0
        return transactions.reduce(initialBalance) { $0 + $1.amount }
    }

    // 计算属性：本月支出
    var monthlyExpense: Double {
        let calendar = Calendar.current
        let now = Date()
        let monthTransactions = transactions.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }
        return abs(monthTransactions.filter { $0.amount < 0 }.reduce(0) { $0 + $1.amount })
    }

    // 计算属性：本月收入
    var monthlyIncome: Double {
        let calendar = Calendar.current
        let now = Date()
        let monthTransactions = transactions.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }
        return monthTransactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
    }

    // 添加交易记录
    func addTransaction(_ transaction: Transaction) {
        transactions.insert(transaction, at: 0)
    }

    // 批量添加交易记录
    func addTransactions(_ newTransactions: [Transaction]) {
        for transaction in newTransactions.reversed() {
            transactions.insert(transaction, at: 0)
        }
    }

    // 删除交易记录
    func deleteTransaction(_ transaction: Transaction) {
        transactions.removeAll { $0.id == transaction.id }
    }
}
