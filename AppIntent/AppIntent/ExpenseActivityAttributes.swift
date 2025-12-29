//
//  ExpenseActivityAttributes.swift
//  AppIntent
//
//  Created by linjx on 2025/12/22.
//

import ActivityKit
import Foundation

// 使用与 Widget Extension 相同的命名
typealias ExpenseActivityAttributes = ExpenseActivityWidgetAttributes

struct ExpenseActivityWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var merchant: String
        var amount: Double
        var time: String?
        var message: String
    }

    var id: String
}
