//
//  Models.swift
//  qiaoqiao
//
//  数据模型
//

import Foundation

// MARK: - 账单明细项
struct InvoiceItem: Codable {
    let name: String
    let quantity: Double?
    let unitPrice: Double?
    let amount: Double?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case name
        case quantity
        case unitPrice = "unit_price"
        case amount
        case description
    }
}

// MARK: - 账单信息
struct Invoice: Codable {
    let invoiceType: String?
    let invoiceNumber: String?
    let invoiceDate: String?
    let sellerName: String?
    let buyerName: String?
    let buyerPhone: String?
    let totalAmount: Double?
    let items: [InvoiceItem]?
    let remarks: String?

    enum CodingKeys: String, CodingKey {
        case invoiceType = "invoice_type"
        case invoiceNumber = "invoice_number"
        case invoiceDate = "invoice_date"
        case sellerName = "seller_name"
        case buyerName = "buyer_name"
        case buyerPhone = "buyer_phone"
        case totalAmount = "total_amount"
        case items
        case remarks
    }
}

// MARK: - 扫描结果
struct ScanResult: Codable {
    let success: Bool
    let data: ScanData?
    let error: String?
    let performance: [String: Double]?
}

struct ScanData: Codable {
    let type: String?
    let invoice: Invoice?
    let stats: [String: Int]?
    let orders: [OrderResult]?
}

struct OrderResult: Codable {
    let success: Bool
    let invoice: Invoice?
    let error: String?
}
