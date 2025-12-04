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

// 交易分类
enum TransactionCategory: String, Codable, CaseIterable {
    case food = "食物"
    case bills = "账单"
    case entertainment = "小玩意"
    case other = "其他"

    var color: Color {
        switch self {
        case .food:
            return .blue
        case .bills:
            return .purple
        case .entertainment:
            return .gray
        case .other:
            return .black
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

    init(id: String = UUID().uuidString,
         merchantName: String,
         description: String,
         amount: Double,
         date: Date = Date(),
         type: TransactionType,
         category: TransactionCategory,
         icon: String = "applelogo") {
        self.id = id
        self.merchantName = merchantName
        self.description = description
        self.amount = amount
        self.date = date
        self.type = type
        self.category = category
        self.icon = icon
    }
}

// 银行卡
struct BankCard: Identifiable {
    let id: String
    let name: String
    let balance: Double
    let lastFourDigits: String
    let backgroundColor: [Color]

    init(id: String = UUID().uuidString,
         name: String,
         balance: Double,
         lastFourDigits: String,
         backgroundColor: [Color]) {
        self.id = id
        self.name = name
        self.balance = balance
        self.lastFourDigits = lastFourDigits
        self.backgroundColor = backgroundColor
    }
}

// 用户信息
struct UserProfile {
    var name: String
    var memberLevel: String
    var phoneNumber: String
    var language: String
    var avatarImage: String
    var totalProfit: Double
    var totalExpense: Double
    var monthlyBudget: Double
    var monthlySpent: Double

    init(name: String = "丹尼尔·特拉维斯",
         memberLevel: String = "会员会 👑",
         phoneNumber: String = "0812 345 6789",
         language: String = "印度尼西亚语",
         avatarImage: String = "person.circle.fill",
         totalProfit: Double = 4500,
         totalExpense: Double = 1691,
         monthlyBudget: Double = 124,
         monthlySpent: Double = 124) {
        self.name = name
        self.memberLevel = memberLevel
        self.phoneNumber = phoneNumber
        self.language = language
        self.avatarImage = avatarImage
        self.totalProfit = totalProfit
        self.totalExpense = totalExpense
        self.monthlyBudget = monthlyBudget
        self.monthlySpent = monthlySpent
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
