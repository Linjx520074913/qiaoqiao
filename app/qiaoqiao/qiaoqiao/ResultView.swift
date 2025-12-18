//
//  ResultView.swift
//  qiaoqiao
//
//  结果显示页面
//

import SwiftUI

struct ResultView: View {
    let scanResult: ScanResult
    let image: UIImage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 显示图片
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
                    .padding(.horizontal)

                if let data = scanResult.data, let invoice = data.invoice {
                    // 基本信息
                    InfoCard(title: "基本信息") {
                        VStack(alignment: .leading, spacing: 8) {
                            if let type = invoice.invoiceType {
                                InfoRow(label: "类型", value: type)
                            }
                            if let seller = invoice.sellerName {
                                InfoRow(label: "商家", value: seller)
                            }
                            if let date = invoice.invoiceDate {
                                InfoRow(label: "日期", value: date)
                            }
                            if let number = invoice.invoiceNumber {
                                InfoRow(label: "订单号", value: number)
                            }
                        }
                    }

                    // 商品明细
                    if let items = invoice.items, !items.isEmpty {
                        InfoCard(title: "商品明细 (\(items.count)项)") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(items.prefix(5), id: \.name) { item in
                                    HStack {
                                        Text("• \(item.name)")
                                            .font(.system(size: 14))
                                        Spacer()
                                        if let amount = item.amount {
                                            Text(String(format: "¥%.2f", amount))
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }

                                if items.count > 5 {
                                    Text("... 还有 \(items.count - 5) 项")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    // 总金额
                    if let total = invoice.totalAmount {
                        InfoCard(title: "总金额") {
                            Text(String(format: "¥%.2f", total))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }

                // 性能统计
                if let performance = scanResult.performance {
                    InfoCard(title: "性能统计") {
                        VStack(alignment: .leading, spacing: 8) {
                            if let total = performance["total"] {
                                InfoRow(label: "总耗时", value: String(format: "%.2fs", total))
                            }
                            if let ocr = performance["ocr"] {
                                InfoRow(label: "OCR", value: String(format: "%.2fs", ocr))
                            }
                            if let parse = performance["parse"] {
                                InfoRow(label: "解析", value: String(format: "%.2fs", parse))
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("识别结果")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 信息卡片
struct InfoCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - 信息行
struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14))
        }
    }
}
