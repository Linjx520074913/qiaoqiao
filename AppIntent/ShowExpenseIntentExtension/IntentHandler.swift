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
            let response = ShowExpenseIntentIntentResponse(code: .failure, userActivity: nil)
            response.message = "配置错误"
            completion(response)
            return
        }

        // 写入调试标记，证明这个方法被调用了
        sharedDefaults.set("HANDLER_CALLED", forKey: "debug_status")
        sharedDefaults.synchronize()

        // 直接保存模拟的识别结果（UI Extension 会延迟 3 秒后显示）
        let merchant = "星巴克咖啡"
        let amount = 45.50

        sharedDefaults.set("analyzing", forKey: "expense_status")
        sharedDefaults.set(merchant, forKey: "expense_merchant")
        sharedDefaults.set(amount, forKey: "expense_amount")
        sharedDefaults.set(Date().timeIntervalSince1970, forKey: "expense_start_time")
        sharedDefaults.synchronize()

        print("✅ [INIntent] 已保存数据 - merchant: \(merchant), amount: \(amount)")

        // 立即返回响应
        let response = ShowExpenseIntentIntentResponse(code: .success, userActivity: nil)
        completion(response)
        print("✅ [INIntent] 已返回响应")
    }

    func confirm(intent: ShowExpenseIntentIntent, completion: @escaping (ShowExpenseIntentIntentResponse) -> Void) {
        print("🔍 [INIntent] confirm 被调用")
        // 确认阶段，直接通过
        completion(ShowExpenseIntentIntentResponse(code: .ready, userActivity: nil))
    }
}
