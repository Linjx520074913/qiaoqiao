//
//  Models.swift
//  bill
//
//  Created by linjx on 2025/12/3.
//

import SwiftUI

// 交易类型
enum TransactionType: String, Codable {
    case income = "income"
    case expense = "expense"
}

// 记账分类
enum TransactionCategory: String, Codable, CaseIterable {
    case food = "餐饮"
    case shopping = "购物"
    case transport = "交通"
    case entertainment = "娱乐"
    case housing = "住房"
    case healthcare = "医疗"
    case education = "教育"
    case other = "其他"

    var color: Color {
        switch self {
        case .food:
            return .orange
        case .shopping:
            return .blue
        case .transport:
            return .green
        case .entertainment:
            return .purple
        case .housing:
            return .red
        case .healthcare:
            return .pink
        case .education:
            return .cyan
        case .other:
            return .gray
        }
    }

    var icon: String {
        switch self {
        case .food:
            return "fork.knife"
        case .shopping:
            return "cart.fill"
        case .transport:
            return "car.fill"
        case .entertainment:
            return "gamecontroller.fill"
        case .housing:
            return "house.fill"
        case .healthcare:
            return "heart.fill"
        case .education:
            return "book.fill"
        case .other:
            return "ellipsis.circle.fill"
        }
    }
}

// 交易记录
struct Transaction: Identifiable, Codable {
    let id: String
    let merchantName: String
    let description: String
    let amount: Double
    let date: Date
    let type: TransactionType
    let category: TransactionCategory
    let icon: String
    let imageData: Data? // 账单图片附件

    init(id: String = UUID().uuidString,
         merchantName: String,
         description: String,
         amount: Double,
         date: Date = Date(),
         type: TransactionType,
         category: TransactionCategory,
         icon: String = "applelogo",
         imageData: Data? = nil) {
        self.id = id
        self.merchantName = merchantName
        self.description = description
        self.amount = amount
        self.date = date
        self.type = type
        self.category = category
        self.icon = icon
        self.imageData = imageData
    }
}

// 账户/账本
struct Account: Identifiable {
    let id: String
    let name: String
    let balance: Double
    let accountType: String // 现金、银行卡、支付宝、微信等
    let backgroundColor: [Color]

    init(id: String = UUID().uuidString,
         name: String,
         balance: Double,
         accountType: String = "银行卡",
         backgroundColor: [Color]) {
        self.id = id
        self.name = name
        self.balance = balance
        self.accountType = accountType
        self.backgroundColor = backgroundColor
    }
}

// 用户信息
struct UserProfile {
    var name: String
    var avatarImage: String
    var totalIncome: Double      // 总收入
    var totalExpense: Double     // 总支出
    var monthlyBudget: Double    // 月度预算
    var monthlySpent: Double     // 本月已花费
    var autoRecordEnabled: Bool  // 是否启用自动记账

    init(name: String = "记账用户",
         avatarImage: String = "person.circle.fill",
         totalIncome: Double = 8500,
         totalExpense: Double = 3240,
         monthlyBudget: Double = 5000,
         monthlySpent: Double = 1240,
         autoRecordEnabled: Bool = true) {
        self.name = name
        self.avatarImage = avatarImage
        self.totalIncome = totalIncome
        self.totalExpense = totalExpense
        self.monthlyBudget = monthlyBudget
        self.monthlySpent = monthlySpent
        self.autoRecordEnabled = autoRecordEnabled
    }
}

// 统计数据
struct StatisticsData {
    var totalSpent: Double
    var categories: [CategorySpending]

    struct CategorySpending: Identifiable {
        let id = UUID()
        let category: TransactionCategory
        let amount: Double
        var percentage: Double
    }
}
