//
//  SharedActivityData.swift
//  AppIntent
//
//  Created by linjx on 2025/12/26.
//

import Foundation

/// 用于主应用和 Widget Extension 之间通过 App Group 共享的数据
struct SharedActivityData: Codable {
    var merchant: String
    var amount: Double
    var time: String?
    var message: String
    var timestamp: Date

    enum ActivityAction: String, Codable {
        case start
        case update
        case end
    }

    var action: ActivityAction
}

/// App Group 管理器
class AppGroupManager {
    static let shared = AppGroupManager()

    // App Group 标识符
    private let appGroupIdentifier = "group.com.dm.AppIntent"

    // 共享数据的 UserDefaults key
    private let activityDataKey = "shared_activity_data"

    private init() {}

    /// 获取 App Group 的 UserDefaults
    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }

    /// 保存活动数据
    func saveActivityData(_ data: SharedActivityData) {
        guard let defaults = sharedDefaults else {
            print("❌ [AppGroup] 无法访问 App Group UserDefaults")
            return
        }

        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(data)
            defaults.set(jsonData, forKey: activityDataKey)
            defaults.synchronize()
            print("✅ [AppGroup] 数据已保存: action=\(data.action), merchant=\(data.merchant)")
        } catch {
            print("❌ [AppGroup] 编码数据失败: \(error)")
        }
    }

    /// 读取活动数据
    func loadActivityData() -> SharedActivityData? {
        guard let defaults = sharedDefaults else {
            print("❌ [AppGroup] 无法访问 App Group UserDefaults")
            return nil
        }

        guard let jsonData = defaults.data(forKey: activityDataKey) else {
            print("⚠️ [AppGroup] 没有保存的数据")
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let data = try decoder.decode(SharedActivityData.self, from: jsonData)
            print("✅ [AppGroup] 数据已读取: action=\(data.action), merchant=\(data.merchant)")
            return data
        } catch {
            print("❌ [AppGroup] 解码数据失败: \(error)")
            return nil
        }
    }

    /// 清除活动数据
    func clearActivityData() {
        guard let defaults = sharedDefaults else {
            return
        }
        defaults.removeObject(forKey: activityDataKey)
        defaults.synchronize()
        print("✅ [AppGroup] 数据已清除")
    }
}
