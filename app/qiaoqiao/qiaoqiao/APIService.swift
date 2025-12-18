//
//  APIService.swift
//  qiaoqiao
//
//  Backend API 服务
//

import Foundation
import UIKit

class APIService: ObservableObject {
    static let shared = APIService()

    // 服务器地址
    // 模拟器使用: http://127.0.0.1:8080
    // 真机调试使用: Mac 的局域网 IP 地址
    @Published var baseURL = "http://10.9.191.78:8080"

    private init() {}

    // MARK: - 健康检查
    func healthCheck() async throws -> [String: Any] {
        guard let url = URL(string: "\(baseURL)/health") else {
            throw URLError(.badURL)
        }

        print("🔍 正在连接: \(url.absoluteString)")

        // 创建不使用代理的 URLSession
        let configuration = URLSessionConfiguration.default
        configuration.connectionProxyDictionary = [:]  // 禁用代理
        let session = URLSession(configuration: configuration)

        do {
            let (data, response) = try await session.data(from: url)

            if let httpResponse = response as? HTTPURLResponse {
                print("✅ HTTP 状态码: \(httpResponse.statusCode)")
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw URLError(.cannotParseResponse)
            }
            print("✅ 连接成功")
            return json
        } catch {
            print("❌ 连接失败: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - 扫描账单
    func scanBill(
        image: UIImage,
        skipItems: Bool = false,
        useFastMode: Bool = false
    ) async throws -> ScanResult {
        let endpoint = useFastMode ? "/scan/fast" : "/scan"
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw URLError(.badURL)
        }

        // 压缩图片
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "图片压缩失败"])
        }

        // 创建 multipart/form-data 请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // 添加 file 字段
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // 添加 skip_items 字段
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"skip_items\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(skipItems ? "true" : "false")\r\n".data(using: .utf8)!)

        // 结束边界
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        // 创建不使用代理的 URLSession
        let configuration = URLSessionConfiguration.default
        configuration.connectionProxyDictionary = [:]  // 禁用代理
        let session = URLSession(configuration: configuration)

        // 发送请求
        print("🔍 正在扫描: \(url.absoluteString)")
        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("✅ 扫描响应状态码: \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(ScanResult.self, from: data)
        return result
    }
}
