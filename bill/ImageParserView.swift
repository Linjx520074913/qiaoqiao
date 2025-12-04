//
//  ImageParserView.swift
//  bill
//
//  Created by linjx on 2025/12/4.
//

import SwiftUI
import Vision
import UIKit

struct ImageParserView: View {
    let receivedImage: UIImage?

    @State private var selectedImage: UIImage?
    @State private var isShowingImagePicker = false
    @State private var recognizedText = ""
    @State private var parsedBillInfo: ParsedBillInfo?
    @State private var parsedMultipleBills: [ParsedBillInfo] = []
    @State private var isProcessing = false
    @State private var currentCardIndex = 0
    @State private var cardOffset: CGFloat = 0
    @State private var cardRotation: Double = 0
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState

    init(receivedImage: UIImage? = nil) {
        self.receivedImage = receivedImage

        // 优先使用传入的图片，否则检查剪贴板
        var initialImage = receivedImage
        if initialImage == nil {
            initialImage = Self.getImageFromPasteboard()
        }

        _selectedImage = State(initialValue: initialImage)
    }

    // 从剪贴板获取图片
    private static func getImageFromPasteboard() -> UIImage? {
        if UIPasteboard.general.hasImages {
            return UIPasteboard.general.image
        }
        return nil
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if isProcessing {
                    // 加载状态
                    VStack(spacing: 24) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))

                        VStack(spacing: 8) {
                            Text("正在识别账单...")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)

                            Text("请稍候")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                } else if !parsedMultipleBills.isEmpty {
                    // 识别完成,显示悬浮卡片
                    ZStack {
                        // 半透明背景
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                // 点击背景关闭
                                presentationMode.wrappedValue.dismiss()
                            }

                        // 卡片内容
                        parsedBillInfoSection
                    }
                } else {
                    // 无图片或未开始识别,显示选择界面
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 20) {
                            imageDisplaySection
                            actionButtonsSection
                            Color.clear.frame(height: 80)
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle(!parsedMultipleBills.isEmpty ? "确认账单" : "图像解析")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onAppear {
            // 如果有图片,自动开始解析
            if selectedImage != nil && parsedMultipleBills.isEmpty && !isProcessing {
                processImage()
            }
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var imageDisplaySection: some View {
        if let image = selectedImage {
            VStack(spacing: 16) {
                Text("识别的图片")
                    .font(.system(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 10)
            }
            .padding(.horizontal, 20)
        }
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: { isShowingImagePicker = true }) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 18))
                    Text("选择图片")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }

            if selectedImage != nil {
                Button(action: processImage) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 18))
                            Text("解析账单")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isProcessing ? Color.gray : Color.green)
                    .cornerRadius(12)
                }
                .disabled(isProcessing)
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var recognizedTextSection: some View {
        if !recognizedText.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "text.alignleft")
                        .foregroundColor(.blue)
                    Text("OCR识别结果")
                        .font(.system(size: 18, weight: .bold))

                    Spacer()

                    Text("\(recognizedText.components(separatedBy: .newlines).count) 行")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                ScrollView {
                    Text(recognizedText)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(maxHeight: 250) // 增加高度
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10)
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private var parsedBillInfoSection: some View {
        if !parsedMultipleBills.isEmpty && currentCardIndex < parsedMultipleBills.count {
            VStack(spacing: 0) {
                // 只显示卡片本身
                ZStack {
                    // 显示当前卡片
                    ForEach(Array(parsedMultipleBills.enumerated()), id: \.offset) { index, billInfo in
                        if index == currentCardIndex {
                            SwipeableCardView(
                                billInfo: billInfo,
                                index: index,
                                sourceImage: selectedImage,
                                isTopCard: true,
                                offset: $cardOffset,
                                rotation: $cardRotation,
                                onConfirm: {
                                    confirmCurrentCard()
                                },
                                onDelete: {
                                    deleteCurrentCard()
                                }
                            )
                        }
                    }
                }
                .frame(maxWidth: 340)
                .padding(.horizontal, 20)
            }
        } else if let billInfo = parsedBillInfo {
            // 单条账单（兼容旧逻辑）
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(.green)
                    Text("解析的账单信息")
                        .font(.system(size: 18, weight: .bold))
                }

                billInfoDetails(billInfo)

                Button(action: {
                    if let bill = parsedBillInfo {
                        saveSingleBill(bill)
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("保存账单")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10)
            .padding(.horizontal, 20)
        }
    }

    private func billInfoDetails(_ billInfo: ParsedBillInfo) -> some View {
        VStack(spacing: 12) {
            DebugInfoRow(label: "商户名称", value: billInfo.merchantName)
            DebugInfoRow(label: "金额", value: String(format: "¥%.2f", billInfo.amount))
            DebugInfoRow(label: "类型", value: billInfo.type == .expense ? "支出" : "收入")
            DebugInfoRow(label: "分类", value: billInfo.category.rawValue)
            if let desc = billInfo.description {
                DebugInfoRow(label: "描述", value: desc)
            }
            DebugInfoRow(label: "时间", value: formatDate(billInfo.date))
        }
    }

    private func processImage() {
        guard let image = selectedImage else { return }

        isProcessing = true
        recognizedText = ""
        parsedBillInfo = nil
        parsedMultipleBills = []

        // 执行OCR识别
        recognizeText(in: image) { text in
            DispatchQueue.main.async {
                self.recognizedText = text
                print("📝 OCR识别文字：\n\(text)")

                // 解析文本为多条账单信息
                self.parsedMultipleBills = self.parseMultipleBillsFromText(text)
                print("📊 解析出 \(self.parsedMultipleBills.count) 条账单")

                for (index, bill) in self.parsedMultipleBills.enumerated() {
                    print("账单 #\(index + 1): \(bill.merchantName) - ¥\(bill.amount) - \(bill.category.rawValue)")
                }

                // 如果只有一条，也放到单条变量（兼容）
                if self.parsedMultipleBills.count == 1 {
                    self.parsedBillInfo = self.parsedMultipleBills.first
                }

                self.isProcessing = false

                // 将识别结果转换为待确认账单并存入AppState
                if !self.parsedMultipleBills.isEmpty {
                    // 获取图片数据
                    let imageData = self.selectedImage?.jpegData(compressionQuality: 0.7)

                    let pendingBills = self.parsedMultipleBills.map { billInfo in
                        PendingBill(
                            merchantName: billInfo.merchantName,
                            amount: billInfo.amount,
                            type: billInfo.type,
                            category: billInfo.category,
                            description: billInfo.description,
                            date: billInfo.date,
                            icon: billInfo.category.icon,
                            imageData: imageData
                        )
                    }
                    self.appState.pendingBills = pendingBills
                    self.appState.currentBillIndex = 0

                    // 关闭识别页面
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private func recognizeText(in image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else {
            completion("")
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation],
                  error == nil else {
                completion("")
                return
            }

            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }

            completion(recognizedStrings.joined(separator: "\n"))
        }

        // 设置识别语言为简体中文和英文
        request.recognitionLanguages = ["zh-Hans", "en-US"]
        request.recognitionLevel = .accurate

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    // 解析多条账单信息
    private func parseMultipleBillsFromText(_ text: String) -> [ParsedBillInfo] {
        var bills: [ParsedBillInfo] = []
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        print("🔍 开始解析，共 \(lines.count) 行文字")
        for (i, line) in lines.enumerated() {
            print("  第\(i+1)行: \(line)")
        }

        // 策略1: 按行解析（每行可能是一条交易）
        var foundAmounts: [TransactionCandidate] = []
        var processedIndices = Set<Int>() // 记录已处理的行索引

        // 查找所有可能的金额（包括跨行情况）
        for (index, line) in lines.enumerated() {
            // 如果这行已经被处理过，跳过
            if processedIndices.contains(index) {
                continue
            }

            // 先检查当前行
            if let amount = extractAmount(from: line) {
                print("  ✅ 第\(index+1)行找到金额: ¥\(amount)")
                foundAmounts.append(TransactionCandidate(
                    lineIndex: index,
                    amount: amount,
                    line: line
                ))
                processedIndices.insert(index)
            } else {
                // 检查是否是跨行情况：当前行+下一行
                if index + 1 < lines.count && !processedIndices.contains(index + 1) {
                    let combinedLine = line + lines[index + 1]
                    if let amount = extractAmount(from: combinedLine) {
                        print("  ✅ 第\(index+1)-\(index+2)行跨行找到金额: ¥\(amount)")
                        foundAmounts.append(TransactionCandidate(
                            lineIndex: index,
                            amount: amount,
                            line: combinedLine
                        ))
                        processedIndices.insert(index)
                        processedIndices.insert(index + 1) // 标记下一行也已处理
                    } else {
                        print("  ❌ 第\(index+1)行未找到金额")
                    }
                } else {
                    print("  ❌ 第\(index+1)行未找到金额")
                }
            }
        }

        print("💰 共找到 \(foundAmounts.count) 个金额")

        // 如果找到多个金额，认为是多条交易
        if foundAmounts.count > 1 {
            for candidate in foundAmounts {
                // 获取前后文用于识别商户和分类
                let contextStart = max(0, candidate.lineIndex - 2)
                let contextEnd = min(lines.count, candidate.lineIndex + 2)
                let context = lines[contextStart..<contextEnd].joined(separator: " ")

                // 判断交易类型（收入/支出）
                let transactionType = detectTransactionType(from: context)
                let finalAmount = transactionType == .income ? candidate.amount : -abs(candidate.amount)

                let merchantName = extractMerchantName(from: candidate.line, context: context)
                let category = classifyTransaction(text: context, transactionType: transactionType)

                bills.append(ParsedBillInfo(
                    merchantName: merchantName,
                    amount: finalAmount,
                    type: transactionType,
                    category: category,
                    description: "第\(bills.count + 1)笔交易",
                    date: Date()
                ))
            }
        } else if foundAmounts.count == 1 {
            // 只有一条交易，使用原有逻辑
            if let singleBill = parseBillFromText(text) {
                bills.append(singleBill)
            }
        } else {
            // 没有找到金额，尝试其他解析方式
            // 检查是否是表格形式（如微信/支付宝账单截图）
            if let tableBills = parseTableFormatBills(text) {
                bills = tableBills
            }
        }

        return bills
    }

    // 辅助结构
    private struct TransactionCandidate {
        let lineIndex: Int
        let amount: Double
        let line: String
    }

    // 提取金额
    private func extractAmount(from text: String) -> Double? {
        // 支持多种金额格式的正则表达式，按优先级排序
        let patterns = [
            // 带货币符号的格式（优先级最高）
            ("¥\\s*([0-9,]+\\.?[0-9]*)", "¥"),           // ¥23.00 或 ¥5,000.00
            ("\\$\\s*([0-9,]+\\.?[0-9]*)", "$"),         // $23.00
            ("([0-9,]+\\.?[0-9]*)\\s*元", "元"),         // 23.00元 或 5,000元

            // 带正负号的格式（中等优先级）
            ("-\\s*([0-9,]+\\.?[0-9]*)", "-"),           // -23.00（负数）
            ("\\+\\s*([0-9,]+\\.?[0-9]*)", "+"),         // +5000.00（正数）

            // 纯数字格式（最低优先级，必须带小数点才匹配）
            ("\\b([0-9,]+\\.[0-9]{1,2})\\b", "")        // 23.00 (必须有小数点)
        ]

        for (pattern, _) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                if let range = Range(match.range(at: 1), in: text) {
                    // 移除千位分隔符和空格
                    let numStr = text[range]
                        .replacingOccurrences(of: ",", with: "")
                        .trimmingCharacters(in: .whitespaces)

                    if let value = Double(numStr), value > 0 && value < 10000000 {
                        print("    → 匹配模式: \(pattern), 提取值: \(value)")
                        return value
                    }
                }
            }
        }
        return nil
    }

    // 提取商户名称
    private func extractMerchantName(from line: String, context: String) -> String {
        // 特殊处理：银行短信格式
        // 格式：日网上支付支取人民币XX.XX元 或 日收入（网银跨行）人民币XX.XX元
        if line.contains("人民币") {
            // 提取交易类型
            if line.contains("收入") {
                if line.contains("网银跨行") {
                    return "网银跨行收入"
                } else if line.contains("工资") {
                    return "工资收入"
                }
                return "收入"
            } else if line.contains("支取") || line.contains("支付") {
                if line.contains("网上支付") {
                    return "网上支付"
                } else if line.contains("转账") {
                    return "转账支出"
                }
                return "支出"
            }
        }

        // 移除金额部分（支持更多格式）
        var cleanLine = line
        let amountPatterns = [
            "人民币[0-9,]+\\.?[0-9]*\\s*元",  // 人民币XX元（银行格式）
            "¥\\s*[0-9,]+\\.?[0-9]*",       // ¥23.00 或 ¥5,000
            "[0-9,]+\\.?[0-9]*\\s*元",      // 23.00元
            "\\$\\s*[0-9,]+\\.?[0-9]*",     // $23.00
            "-\\s*[0-9,]+\\.?[0-9]*",       // -23.00
            "\\+\\s*[0-9,]+\\.?[0-9]*",     // +5000.00
            "\\b[0-9,]+\\.[0-9]{1,2}\\b"    // 纯数字 23.00
        ]

        for pattern in amountPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                cleanLine = regex.stringByReplacingMatches(
                    in: cleanLine,
                    range: NSRange(cleanLine.startIndex..., in: cleanLine),
                    withTemplate: ""
                )
            }
        }

        // 移除常见的银行短信关键词
        let removePatterns = [
            "您的借记卡账户[0-9]+，于[0-9月日]+",
            "日.*支取",
            "日.*收入",
            "，交易.*",
            "后余额.*",
            "【.*】"
        ]

        for pattern in removePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                cleanLine = regex.stringByReplacingMatches(
                    in: cleanLine,
                    range: NSRange(cleanLine.startIndex..., in: cleanLine),
                    withTemplate: ""
                )
            }
        }

        // 清理空白字符和特殊字符
        var merchant = cleanLine
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "|-()（）"))

        // 如果太短或为空，尝试从上下文提取
        if merchant.count < 2 {
            return "银行交易"
        }

        return merchant.count > 30 ? String(merchant.prefix(30)) : merchant
    }

    // 检测交易类型（收入/支出）
    private func detectTransactionType(from text: String) -> TransactionType {
        let textLower = text.lowercased()

        // 收入关键词
        let incomeKeywords = [
            "收入", "入账", "转入", "到账", "工资", "奖金", "分红",
            "报销", "退款", "返现", "红包", "salary", "income",
            "网银跨行", "存入", "credit", "deposit"
        ]

        // 支出关键词
        let expenseKeywords = [
            "支出", "支取", "支付", "消费", "扣款", "划出",
            "购买", "付款", "转账", "网上支付", "expense",
            "payment", "purchase", "withdraw", "debit"
        ]

        // 检查收入关键词
        for keyword in incomeKeywords {
            if textLower.contains(keyword) {
                return .income
            }
        }

        // 检查支出关键词
        for keyword in expenseKeywords {
            if textLower.contains(keyword) {
                return .expense
            }
        }

        // 如果文本中包含加号 "+"，通常表示收入
        if text.contains("+") {
            return .income
        }

        // 如果文本中包含减号 "-"，通常表示支出
        if text.contains("-") {
            return .expense
        }

        // 默认为支出
        return .expense
    }

    // 分类交易
    private func classifyTransaction(text: String, transactionType: TransactionType = .expense) -> TransactionCategory {
        let textLower = text.lowercased()

        // 如果是收入，根据收入类型分类
        if transactionType == .income {
            if textLower.contains("工资") || textLower.contains("薪水") || textLower.contains("salary") {
                return .other  // 工资收入归为其他
            } else if textLower.contains("奖金") || textLower.contains("分红") || textLower.contains("红包") {
                return .other  // 奖金归为其他
            } else if textLower.contains("退款") || textLower.contains("返现") || textLower.contains("报销") {
                return .other  // 退款归为其他
            }
            return .other  // 其他收入
        }

        // 支出分类
        if textLower.contains("餐") || textLower.contains("咖啡") || textLower.contains("美食")
            || textLower.contains("饭店") || textLower.contains("starbucks") || textLower.contains("外卖")
            || textLower.contains("肯德基") || textLower.contains("麦当劳") || textLower.contains("食")
            || textLower.contains("饮") || textLower.contains("茶") || textLower.contains("restaurant") {
            return .food
        } else if textLower.contains("超市") || textLower.contains("商场") || textLower.contains("购物")
            || textLower.contains("淘宝") || textLower.contains("京东") || textLower.contains("拼多多")
            || textLower.contains("商店") || textLower.contains("shopping") {
            return .shopping
        } else if textLower.contains("地铁") || textLower.contains("出租") || textLower.contains("滴滴")
            || textLower.contains("uber") || textLower.contains("交通") || textLower.contains("打车")
            || textLower.contains("公交") || textLower.contains("高铁") || textLower.contains("火车")
            || textLower.contains("飞机") || textLower.contains("加油") || textLower.contains("停车") {
            return .transport
        } else if textLower.contains("电影") || textLower.contains("娱乐") || textLower.contains("ktv")
            || textLower.contains("游戏") || textLower.contains("旅游") || textLower.contains("景点") {
            return .entertainment
        } else if textLower.contains("房租") || textLower.contains("物业") || textLower.contains("水电")
            || textLower.contains("房贷") || textLower.contains("燃气") || textLower.contains("宽带") {
            return .housing
        } else if textLower.contains("医院") || textLower.contains("药店") || textLower.contains("医疗")
            || textLower.contains("体检") || textLower.contains("诊所") {
            return .healthcare
        } else if textLower.contains("教育") || textLower.contains("培训") || textLower.contains("学费")
            || textLower.contains("书") || textLower.contains("课程") {
            return .education
        }

        return .other
    }

    // 解析表格格式的账单（如支付宝/微信账单截图）
    private func parseTableFormatBills(_ text: String) -> [ParsedBillInfo]? {
        // TODO: 实现表格格式解析
        // 检测是否有"商户名称"、"金额"等表头
        // 按行解析表格数据
        return nil
    }

    private func parseBillFromText(_ text: String) -> ParsedBillInfo? {
        // 智能解析文本，提取账单信息
        let lines = text.components(separatedBy: .newlines)
        var amount: Double?
        var merchantName = "未知商户"
        var category: TransactionCategory = .other

        // 查找金额（支持多种格式）
        for line in lines {
            if let foundAmount = extractAmount(from: line) {
                amount = foundAmount
                break
            }
        }

        // 智能识别商户名称（通常在前几行）
        if lines.count > 0 {
            let firstLine = lines[0].trimmingCharacters(in: .whitespacesAndNewlines)
            if !firstLine.isEmpty && firstLine.count < 20 {
                merchantName = firstLine
            }
        }

        guard let foundAmount = amount else { return nil }

        // 判断交易类型（收入/支出）
        let transactionType = detectTransactionType(from: text)
        let finalAmount = transactionType == .income ? foundAmount : -abs(foundAmount)

        // 智能分类（传入交易类型）
        category = classifyTransaction(text: text, transactionType: transactionType)

        return ParsedBillInfo(
            merchantName: merchantName,
            amount: finalAmount,
            type: transactionType,
            category: category,
            description: "通过图像识别",
            date: Date()
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }

    // 保存单条账单
    private func saveSingleBill(_ billInfo: ParsedBillInfo) {
        let transaction = convertToTransaction(billInfo)
        appState.addTransaction(transaction)
        print("✅ 已保存账单: \(transaction.merchantName) - ¥\(transaction.amount)")

        // 显示提示并关闭
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            presentationMode.wrappedValue.dismiss()
        }
    }

    // 保存所有账单
    private func saveAllBills() {
        let transactions = parsedMultipleBills.map { convertToTransaction($0) }
        appState.addTransactions(transactions)
        print("✅ 已保存 \(transactions.count) 条账单")

        // 显示提示并关闭
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            presentationMode.wrappedValue.dismiss()
        }
    }

    // 确认单条账单
    private func confirmBill(at index: Int) {
        guard index < parsedMultipleBills.count else { return }
        let billInfo = parsedMultipleBills[index]
        let transaction = convertToTransaction(billInfo)
        appState.addTransaction(transaction)

        // 从列表中移除已确认的账单
        withAnimation {
            parsedMultipleBills.remove(at: index)
        }

        print("✅ 已确认账单: \(transaction.merchantName) - ¥\(transaction.amount)")

        // 如果所有账单都已确认,关闭页面
        if parsedMultipleBills.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    // 删除单条账单
    private func deleteBill(at index: Int) {
        guard index < parsedMultipleBills.count else { return }
        let billInfo = parsedMultipleBills[index]

        withAnimation {
            parsedMultipleBills.remove(at: index)
        }

        print("🗑️ 已删除账单: \(billInfo.merchantName)")

        // 如果所有账单都已删除,关闭页面
        if parsedMultipleBills.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    // 确认所有账单
    private func confirmAllBills() {
        let transactions = parsedMultipleBills.map { convertToTransaction($0) }
        appState.addTransactions(transactions)
        print("✅ 已确认全部 \(transactions.count) 条账单")

        // 清空列表并关闭
        parsedMultipleBills.removeAll()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            presentationMode.wrappedValue.dismiss()
        }
    }

    // 确认当前卡片
    private func confirmCurrentCard() {
        guard currentCardIndex < parsedMultipleBills.count else { return }
        let billInfo = parsedMultipleBills[currentCardIndex]
        let transaction = convertToTransaction(billInfo)
        appState.addTransaction(transaction)

        print("✅ 已确认账单: \(transaction.merchantName) - ¥\(transaction.amount)")

        // 移动到下一张卡片
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentCardIndex += 1
        }

        // 如果所有账单都已确认,关闭页面
        if currentCardIndex >= parsedMultipleBills.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    // 删除当前卡片
    private func deleteCurrentCard() {
        guard currentCardIndex < parsedMultipleBills.count else { return }
        let billInfo = parsedMultipleBills[currentCardIndex]

        print("🗑️ 已删除账单: \(billInfo.merchantName)")

        // 移动到下一张卡片
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentCardIndex += 1
        }

        // 如果所有账单都已处理,关闭页面
        if currentCardIndex >= parsedMultipleBills.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    // 跳过当前卡片
    private func skipCurrentCard() {
        guard currentCardIndex < parsedMultipleBills.count - 1 else { return }

        // 移动到下一张卡片
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentCardIndex += 1
        }
    }

    // 将 ParsedBillInfo 转换为 Transaction
    private func convertToTransaction(_ billInfo: ParsedBillInfo) -> Transaction {
        return Transaction(
            merchantName: billInfo.merchantName,
            description: billInfo.description ?? "无备注",
            amount: billInfo.amount,
            date: billInfo.date,
            type: billInfo.type,
            category: billInfo.category,
            icon: billInfo.category.icon
        )
    }
}

// MARK: - 调试信息行
struct DebugInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 可滑动的卡片视图
struct SwipeableCardView: View {
    let billInfo: ParsedBillInfo
    let index: Int
    let sourceImage: UIImage?
    let isTopCard: Bool
    @Binding var offset: CGFloat
    @Binding var rotation: Double
    let onConfirm: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 卡片内容
            VStack(spacing: 16) {
                // 顶部：分类图标和金额
                VStack(spacing: 12) {
                    // 分类图标
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        billInfo.category.color.opacity(0.3),
                                        billInfo.category.color.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)

                        Image(systemName: billInfo.category.icon)
                            .font(.system(size: 32))
                            .foregroundColor(billInfo.category.color)
                    }

                    // 金额
                    Text(String(format: "%@¥%.2f",
                              billInfo.amount >= 0 ? "+" : "",
                              abs(billInfo.amount)))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(billInfo.amount >= 0 ? .green : .red)

                    Text(billInfo.type == .income ? "收入" : "支出")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                .padding(.top, 24)

                Divider()
                    .padding(.horizontal, 16)

                // 账单详情
                VStack(spacing: 12) {
                    CompactDetailRow(
                        icon: "building.2.fill",
                        iconColor: .blue,
                        title: "商户",
                        value: billInfo.merchantName
                    )

                    if let description = billInfo.description, !description.isEmpty {
                        CompactDetailRow(
                            icon: "doc.text.fill",
                            iconColor: .orange,
                            title: "备注",
                            value: description
                        )
                    }

                    CompactDetailRow(
                        icon: "tag.fill",
                        iconColor: billInfo.category.color,
                        title: "分类",
                        value: billInfo.category.rawValue
                    )

                    CompactDetailRow(
                        icon: "calendar",
                        iconColor: .purple,
                        title: "时间",
                        value: formatDateTime(billInfo.date)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // 底部操作按钮
                HStack(spacing: 12) {
                    // 删除按钮
                    Button(action: onDelete) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                            Text("删除")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }

                    // 确认按钮
                    Button(action: onConfirm) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                            Text("确认")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.25), radius: 30, x: 0, y: 10)
        .offset(x: isTopCard ? offset : 0)
        .rotationEffect(.degrees(isTopCard ? rotation : 0))
        .gesture(
            isTopCard ? DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation.width
                    rotation = Double(gesture.translation.width / 20)
                }
                .onEnded { gesture in
                    let threshold: CGFloat = 120
                    if gesture.translation.width > threshold {
                        // 向右滑动 - 确认
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            offset = 500
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            offset = 0
                            rotation = 0
                            onConfirm()
                        }
                    } else if gesture.translation.width < -threshold {
                        // 向左滑动 - 删除
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            offset = -500
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            offset = 0
                            rotation = 0
                            onDelete()
                        }
                    } else {
                        // 回弹
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            offset = 0
                            rotation = 0
                        }
                    }
                } : nil
        )
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
}

// 紧凑的详情信息行
struct CompactDetailRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(iconColor)
                .frame(width: 20)

            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .frame(width: 40, alignment: .leading)

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()
        }
    }
}

// 详情信息行
struct DetailInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 28)

            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .frame(width: 50, alignment: .leading)

            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - 解析的账单信息
struct ParsedBillInfo {
    let merchantName: String
    let amount: Double
    let type: TransactionType
    let category: TransactionCategory
    let description: String?
    let date: Date
}

// MARK: - 账单确认卡片
struct BillConfirmCard: View {
    let billInfo: ParsedBillInfo
    let index: Int
    let sourceImage: UIImage?
    let onConfirm: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // 卡片主体
            VStack(spacing: 16) {
                // 头部：商户名 + 金额
                HStack(alignment: .top, spacing: 12) {
                    // 分类图标
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(billInfo.category.color.opacity(0.15))
                            .frame(width: 52, height: 52)

                        Image(systemName: billInfo.category.icon)
                            .font(.system(size: 22))
                            .foregroundColor(billInfo.category.color)
                    }

                    // 商户和备注
                    VStack(alignment: .leading, spacing: 6) {
                        Text(billInfo.merchantName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)

                        if let description = billInfo.description, !description.isEmpty {
                            Text(description)
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // 金额
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(String(format: "%@¥%.2f",
                                  billInfo.amount >= 0 ? "+" : "",
                                  abs(billInfo.amount)))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(billInfo.amount >= 0 ? .green : .red)

                        Text(billInfo.type == .income ? "收入" : "支出")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }

                // 分类和时间
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 12))
                            .foregroundColor(billInfo.category.color)
                        Text(billInfo.category.rawValue)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                        Text(formatDate(billInfo.date))
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }

                    Spacer()
                }

                // 操作按钮
                HStack(spacing: 12) {
                    // 删除按钮
                    Button(action: onDelete) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                            Text("删除")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }

                    // 确认按钮
                    Button(action: onConfirm) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14))
                            Text("确认")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.green,
                                    Color.green.opacity(0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                    }
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    ImageParserView()
}
