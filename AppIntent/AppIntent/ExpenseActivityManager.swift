//
//  ExpenseActivityManager.swift
//  AppIntent
//
//  Created by linjx on 2025/12/22.
//

import ActivityKit
import Foundation

@available(iOS 16.1, *)
class ExpenseActivityManager {
    static let shared = ExpenseActivityManager()

    private var currentActivity: Activity<ExpenseActivityWidgetAttributes>?

    private init() {}

    func startActivity(merchant: String, amount: Double, time: String?, message: String) async throws {
        // 如果已有活动，先结束
        if let activity = currentActivity {
            await activity.end(nil, dismissalPolicy: .immediate)
        }

        let attributes = ExpenseActivityAttributes(id: UUID().uuidString)
        let contentState = ExpenseActivityAttributes.ContentState(
            merchant: merchant,
            amount: amount,
            time: time,
            message: message
        )

        do {
            // 设置自动消失时间（30秒后）
            let futureDate = Calendar.current.date(byAdding: .second, value: 30, to: Date())

            // 添加 alert 配置以提升优先级
            let activityContent = ActivityContent(
                state: contentState,
                staleDate: futureDate
            )

            let activity = try Activity.request(
                attributes: attributes,
                content: activityContent,
                pushType: nil
            )
            currentActivity = activity
            print("✅ [ActivityManager] Live Activity 启动成功，ID: \(activity.id)")
        } catch {
            print("❌ [ActivityManager] Live Activity 启动失败: \(error)")
            throw error
        }
    }

    func updateActivity(merchant: String, amount: Double, time: String?, message: String) async {
        guard let activity = currentActivity else {
            print("⚠️ [ActivityManager] currentActivity 为 nil，无法更新")
            return
        }

        print("📝 [ActivityManager] 准备更新: merchant=\(merchant), amount=\(amount)")

        let contentState = ExpenseActivityAttributes.ContentState(
            merchant: merchant,
            amount: amount,
            time: time,
            message: message
        )

        // 更新 Live Activity 内容
        let futureDate = Calendar.current.date(byAdding: .second, value: 30, to: Date())
        await activity.update(
            ActivityContent(state: contentState, staleDate: futureDate)
        )

        print("✅ [ActivityManager] 更新完成")
    }

    func endActivity() async {
        guard let activity = currentActivity else { return }
        await activity.end(nil, dismissalPolicy: .immediate)
        currentActivity = nil
    }
}
