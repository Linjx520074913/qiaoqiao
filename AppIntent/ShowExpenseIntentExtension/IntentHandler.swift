//
//  IntentHandler.swift
//  ShowExpenseIntentExtension
//
//  Created by Claude Code on 2025/12/29.
//

import Intents

class IntentHandler: INExtension, ShowExpenseIntentIntentHandling {

    // App Group 标识符
    private let appGroupIdentifier = "group.com.dm.AppIntent"

    override func handler(for intent: INIntent) -> Any {
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
            let response = ShowExpenseIntentIntentResponse(code: .failure, userActivity: nil)
            response.message = "配置错误"
            completion(response)
            return
        }

        // 设置初始状态：分析中
        sharedDefaults.set("analyzing", forKey: "expense_status")
        sharedDefaults.synchronize()
        print("✅ [INIntent] 已设置状态为 analyzing")

        // 启动后台任务
        DispatchQueue.global(qos: .userInitiated).async {
            print("⏳ [INIntent] 开始 3 秒任务...")
            Thread.sleep(forTimeInterval: 3.0) // 3秒

            print("✅ [INIntent] 3 秒完成")

            // 更新状态为已完成
            sharedDefaults.set("success", forKey: "expense_status")
            sharedDefaults.synchronize()

            print("✅ [INIntent] 已更新共享数据为 success")

            // 返回响应
            DispatchQueue.main.async {
                let response = ShowExpenseIntentIntentResponse(code: .success, userActivity: nil)
                completion(response)
                print("✅ [INIntent] 已返回响应")
            }
        }

        // 注意：这里不要立即 completion，而是在后台任务完成后调用
    }

    func confirm(intent: ShowExpenseIntentIntent, completion: @escaping (ShowExpenseIntentIntentResponse) -> Void) {
        // 确认阶段，直接通过
        completion(ShowExpenseIntentIntentResponse(code: .ready, userActivity: nil))
    }
}
