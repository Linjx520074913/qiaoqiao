//
//  BillScanService.swift
//  AppIntent
//
//  Created by linjx on 2025/12/22.
//

import Foundation
import UIKit

// MARK: - 响应数据模型

struct BillScanResponse: Codable {
    let success: Bool
    let data: BillData?
    let error: String?
    let performance: Performance?
}

struct BillData: Codable {
    let type: String
    let invoice: Invoice?
    let confidence: Double?
}

struct Invoice: Codable {
    let merchant: String?
    let total: Double?
    let invoiceDate: String?  // 完整的日期时间："2025-12-22 16:00:23"
    let remarks: String?

    // 计算属性：从 invoiceDate 提取日期和时间
    var date: String? {
        guard let invoiceDate = invoiceDate else { return nil }
        return String(invoiceDate.prefix(10))  // "2025-12-22"
    }

    var time: String? {
        guard let invoiceDate = invoiceDate else { return nil }
        if invoiceDate.count > 11 {
            return String(invoiceDate.suffix(from: invoiceDate.index(invoiceDate.startIndex, offsetBy: 11)))  // "16:00:23"
        }
        return nil
    }

    enum CodingKeys: String, CodingKey {
        case merchant = "seller_name"
        case total = "total_amount"
        case invoiceDate = "invoice_date"
        case remarks = "raw_text"
    }
}

struct Performance: Codable {
    let ocr: Double?
    let parse: Double?
    let total: Double?
}

// MARK: - 账单扫描服务

class BillScanService {
    static let shared = BillScanService()

    // 后端服务地址 - 使用 Cloudflare Tunnel（支持外网访问）
    private let baseURL = "https://scanning-zone-logos-richard.trycloudflare.com"

    private init() {}

    /// 扫描账单图片
    /// - Parameter image: UIImage 对象
    /// - Returns: 识别结果
    func scanBill(image: UIImage) async throws -> BillScanResponse {
        print("📸 [BillScan] 开始处理图片...")

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ [BillScan] 图片数据转换失败")
            throw NSError(domain: "BillScanService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "图片数据转换失败"
            ])
        }

        print("✅ [BillScan] 图片数据大小: \(imageData.count) bytes")

        // 创建请求
        let url = URL(string: "\(baseURL)/scan/fast")!
        print("🌐 [BillScan] 请求地址: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120 // 设置 120 秒超时（OCR + LLM 需要时间）

        // 创建 multipart/form-data
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // 添加图片文件
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"bill.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // 添加参数
        let params: [String: String] = [
            "skip_items": "true",
            "clean_text": "true",
            "concurrent": "true"
        ]

        for (key, value) in params {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body
        print("📦 [BillScan] 请求体大小: \(body.count) bytes")

        // 发送请求
        print("🚀 [BillScan] 发送请求...")
        let startTime = Date()

        // 创建不使用代理的 URLSession 配置
        let configuration = URLSessionConfiguration.default
        configuration.connectionProxyDictionary = [:]  // 禁用代理（关键！）
        let session = URLSession(configuration: configuration)

        let (data, response): (Data, URLResponse)
        do {
            // 在后台任务中添加进度提示
            Task {
                for i in 1...30 {
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 每2秒
                    let elapsed = Date().timeIntervalSince(startTime)
                    print("⏳ [BillScan] 等待响应... (\(Int(elapsed))秒)")
                }
            }

            (data, response) = try await session.data(for: request)
            let elapsed = Date().timeIntervalSince(startTime)
            print("✅ [BillScan] 收到响应（总耗时: \(String(format: "%.1f", elapsed))秒）")
        } catch {
            let elapsed = Date().timeIntervalSince(startTime)
            print("❌ [BillScan] 网络请求失败（耗时: \(String(format: "%.1f", elapsed))秒）")
            print("❌ [BillScan] 错误: \(error)")
            print("❌ [BillScan] 错误详情: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("❌ [BillScan] URLError code: \(urlError.code.rawValue)")
                print("❌ [BillScan] 目标地址: \(urlError.failingURL?.absoluteString ?? "未知")")
            }
            throw error
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [BillScan] 无效的响应")
            throw NSError(domain: "BillScanService", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "无效的响应"
            ])
        }

        print("📡 [BillScan] HTTP 状态码: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            print("❌ [BillScan] 服务器错误: \(httpResponse.statusCode)")
            throw NSError(domain: "BillScanService", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "服务器错误: \(httpResponse.statusCode)"
            ])
        }

        // 解析响应
        print("🔍 [BillScan] 解析响应数据...")

        // 打印原始响应（调试用）
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 [BillScan] 原始响应: \(responseString)")
        }

        let decoder = JSONDecoder()
        let scanResponse = try decoder.decode(BillScanResponse.self, from: data)

        print("✅ [BillScan] 识别成功: \(scanResponse.success)")
        if let error = scanResponse.error {
            print("❌ [BillScan] 错误信息: \(error)")
        }
        if let invoice = scanResponse.data?.invoice {
            print("🏪 [BillScan] 商家: \(invoice.merchant ?? "未知")")
            print("💰 [BillScan] 金额: \(invoice.total ?? 0)")
        }

        return scanResponse
    }
}
