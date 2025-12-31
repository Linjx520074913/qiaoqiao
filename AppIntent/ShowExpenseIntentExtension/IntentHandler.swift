//
//  IntentHandler.swift
//  ShowExpenseIntentExtension
//
//  Created by Claude Code on 2025/12/29.
//

import Intents
import UIKit

class IntentHandler: INExtension, ShowExpenseIntentIntentHandling {

    // App Group 标识符
    private let appGroupIdentifier = "group.com.dm.AppIntent"

    override func handler(for intent: INIntent) -> Any {
        print("🔧 [INIntent] handler(for:) 被调用 - intent类型: \(type(of: intent))")
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.

        return self
    }

    // MARK: - ShowExpenseIntentIntentHandling

    func handle(intent: ShowExpenseIntentIntent, completion: @escaping (ShowExpenseIntentIntentResponse) -> Void) {
        print("🚀 [INIntent] 开始处理...")

        // 访问 App Group
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("❌ [INIntent] 无法访问 App Group")
            let response = ShowExpenseIntentIntentResponse(code: .success, userActivity: nil)
            completion(response)
            return
        }

        // 写入初始状态：分析中
        sharedDefaults.set("analyzing", forKey: "expense_status")
        sharedDefaults.set("", forKey: "expense_merchant")
        sharedDefaults.set(0.0, forKey: "expense_amount")
        sharedDefaults.set(Date().timeIntervalSince1970, forKey: "expense_start_time")
        sharedDefaults.synchronize()

        // 立即返回响应，让 UI 显示"分析中..."
        let response = ShowExpenseIntentIntentResponse(code: .success, userActivity: nil)
        completion(response)
        print("✅ [INIntent] 已返回响应，UI 将显示分析中状态")

        // 在后台异步执行 API 调用
        Task {
            await self.performBillScan(sharedDefaults: sharedDefaults)
        }
    }

    // MARK: - Private Methods

    private func performBillScan(sharedDefaults: UserDefaults) async {
        print("📸 [INIntent] 开始从共享容器读取图片...")

        // 写入调试信息
        sharedDefaults.set("正在读取图片...", forKey: "debug_message")
        sharedDefaults.synchronize()

        // 从共享容器读取图片
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            print("❌ [INIntent] 无法访问共享容器")
            saveError(to: sharedDefaults, message: "无法访问共享容器")
            return
        }

        let imageURL = containerURL.appendingPathComponent("bill_image.jpg")
        print("📁 [INIntent] 图片路径: \(imageURL.path)")

        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            print("❌ [INIntent] 图片文件不存在: \(imageURL.path)")

            // 列出共享容器中的所有文件
            do {
                let files = try FileManager.default.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil)
                print("📂 [INIntent] 共享容器中的文件: \(files.map { $0.lastPathComponent })")
            } catch {
                print("❌ [INIntent] 无法列出文件: \(error)")
            }

            saveError(to: sharedDefaults, message: "未找到图片文件，请先执行 保存账单图片")
            return
        }

        guard let imageData = try? Data(contentsOf: imageURL),
              let image = UIImage(data: imageData) else {
            print("❌ [INIntent] 无法加载图片")
            saveError(to: sharedDefaults, message: "图片加载失败")
            return
        }

        print("✅ [INIntent] 图片加载成功，大小: \(imageData.count) bytes")

        sharedDefaults.set("正在调用 API...", forKey: "debug_message")
        sharedDefaults.synchronize()

        print("🌐 [INIntent] 开始调用 API...")

        // 调用后端 API
        do {
            let scanService = BillScanService.shared
            print("📡 [INIntent] 正在上传图片并识别...")

            let result = try await scanService.scanBill(image: image)

            print("📥 [INIntent] API 返回结果: success=\(result.success)")

            if result.success, let data = result.data, let invoice = data.invoice {
                let merchant = invoice.merchant ?? "未知商家"
                let amount = invoice.total ?? 0.0

                print("✅ [INIntent] 识别成功: \(merchant) - ¥\(amount)")

                // 保存识别结果
                sharedDefaults.set("completed", forKey: "expense_status")
                sharedDefaults.set(merchant, forKey: "expense_merchant")
                sharedDefaults.set(amount, forKey: "expense_amount")
                sharedDefaults.set("识别成功", forKey: "debug_message")
                sharedDefaults.synchronize()

                print("✅ [INIntent] 结果已保存到共享容器")
                print("   - status: completed")
                print("   - merchant: \(merchant)")
                print("   - amount: \(amount)")
            } else {
                let errorMsg = result.error ?? "识别失败"
                print("❌ [INIntent] 识别失败: \(errorMsg)")
                saveError(to: sharedDefaults, message: errorMsg)
            }
        } catch {
            print("❌ [INIntent] API 调用失败: \(error.localizedDescription)")
            print("❌ [INIntent] 错误详情: \(error)")
            saveError(to: sharedDefaults, message: "网络请求失败: \(error.localizedDescription)")
        }

        // 删除临时图片
        try? FileManager.default.removeItem(at: imageURL)
        print("🗑️ [INIntent] 已删除临时图片")
    }

    private func saveError(to sharedDefaults: UserDefaults, message: String) {
        sharedDefaults.set("error", forKey: "expense_status")
        sharedDefaults.set(message, forKey: "expense_merchant")
        sharedDefaults.set(0.0, forKey: "expense_amount")
        sharedDefaults.synchronize()
    }

    // 移除 confirm 方法，因为我们不需要用户确认
    // func confirm(intent: ShowExpenseIntentIntent, completion: @escaping (ShowExpenseIntentIntentResponse) -> Void) {
    //     print("🔍 [INIntent] confirm 被调用")
    //     completion(ShowExpenseIntentIntentResponse(code: .ready, userActivity: nil))
    // }
}
