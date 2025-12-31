//
//  SaveBillImageIntent.swift
//  AppIntent
//
//  Created by Claude Code on 2025/12/30.
//

import AppIntents
import UIKit

struct SaveBillImageIntent: AppIntent {
    static var title: LocalizedStringResource = "保存账单图片"
    static var description = IntentDescription("将图片保存到共享容器，供后续识别使用")

    // 后台运行，不打开应用
    static var openAppWhenRun: Bool = false

    // 接收图片参数
    @Parameter(title: "账单图片", description: "要识别的账单图片")
    var image: IntentFile

    static var parameterSummary: some ParameterSummary {
        Summary("保存\(\.$image)")
    }

    // App Group 标识符
    private let appGroupIdentifier = "group.com.dm.AppIntent"

    func perform() async throws -> some IntentResult {
        print("💾 [SaveImage] 开始保存图片...")

        // 转换为 UIImage
        let imageData = image.data
        guard let uiImage = UIImage(data: imageData) else {
            print("❌ [SaveImage] 图片转换失败")
            throw NSError(domain: "SaveBillImageIntent", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "图片格式错误"
            ])
        }

        // 压缩图片
        guard let jpegData = uiImage.jpegData(compressionQuality: 0.8) else {
            print("❌ [SaveImage] 图片压缩失败")
            throw NSError(domain: "SaveBillImageIntent", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "图片压缩失败"
            ])
        }

        // 获取共享容器路径
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            print("❌ [SaveImage] 无法访问共享容器")
            throw NSError(domain: "SaveBillImageIntent", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "无法访问共享容器"
            ])
        }

        let imageURL = containerURL.appendingPathComponent("bill_image.jpg")

        // 保存图片
        do {
            try jpegData.write(to: imageURL)
            print("✅ [SaveImage] 图片已保存: \(imageURL.path)")
            print("📦 [SaveImage] 图片大小: \(jpegData.count) bytes")
        } catch {
            print("❌ [SaveImage] 保存失败: \(error.localizedDescription)")
            throw error
        }

        return .result()
    }
}
