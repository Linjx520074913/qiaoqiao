//
//  MainTabView.swift
//  bill
//
//  Created by linjx on 2025/12/3.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var isShowingImageParser = false
    @State private var hasCheckedPasteboard = false
    @State private var pasteboardCheckTimer: Timer?
    @State private var showDebugOverlay = false
    @State private var debugMessages: [String] = []
    @State private var currentProcessor: BackgroundOCRProcessor?
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        ZStack(alignment: .bottom) {
            // 主内容区域
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)

                StatisticsView()
                    .tag(1)

                Color.clear
                    .tag(2)

                Color.white
                    .tag(3)

                ProfileView()
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // 自定义底部导航栏
            CustomTabBar(selectedTab: $selectedTab, onScanTapped: {
                isShowingImageParser = true
            })

            // 调试浮窗
            VStack {
                Spacer()
                DebugOverlay(isVisible: $showDebugOverlay, messages: $debugMessages)
            }

            // 悬浮账单确认卡片
            if !appState.pendingBills.isEmpty && appState.currentBillIndex < appState.pendingBills.count {
                BillConfirmationOverlay()
                    .environmentObject(appState)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .zIndex(100)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .gesture(
            // 三指向下滑动显示调试信息
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.height > 50 && !showDebugOverlay {
                        withAnimation {
                            showDebugOverlay = true
                        }
                    }
                }
        )
        .onChange(of: appState.receivedImage) { oldValue, newValue in
            // 当收到图片时,直接在后台处理
            if let image = newValue {
                addDebugMessage("🖼️ onChange触发: 收到图片,尺寸 \(image.size.width)x\(image.size.height)")
                addDebugMessage("🔄 调用processImageInBackground")
                processImageInBackground(image)
                // 延迟清空，确保处理已开始
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.appState.receivedImage = nil
                }
            }
        }
        .onChange(of: appState.shouldShowImageParser) {
            if appState.shouldShowImageParser {
                // 如果需要显示解析界面(手动选择)
                if appState.receivedImage == nil {
                    isShowingImageParser = true
                }
                appState.shouldShowImageParser = false
            }
        }
        .fullScreenCover(isPresented: $isShowingImageParser) {
            ImageParserView(receivedImage: nil)
        }
        .onAppear {
            addDebugMessage("🔵 MainTabView onAppear")
            startPasteboardMonitoring()
        }
        .onDisappear {
            addDebugMessage("🔴 MainTabView onDisappear")
            stopPasteboardMonitoring()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            addDebugMessage("🔄 scenePhase 变化: \(oldPhase) -> \(newPhase)")

            if newPhase == .active {
                // App从后台返回前台
                addDebugMessage("✨ App返回前台，重新检查剪贴板")

                // 清除之前的定时器
                stopPasteboardMonitoring()

                // 延迟一点再开始监听，确保剪贴板已更新
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    startPasteboardMonitoring()
                }
            } else if newPhase == .background {
                addDebugMessage("💤 App进入后台")
                stopPasteboardMonitoring()
            }
        }
    }

    private func startPasteboardMonitoring() {
        addDebugMessage("📱 App启动，开始监听剪贴板")

        // 立即检查一次
        checkPasteboardAndOpenParser()

        // 启动定时器，每0.5秒检查一次剪贴板（持续3秒）
        var checkCount = 0
        pasteboardCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            checkCount += 1
            addDebugMessage("🔍 第\(checkCount)次检查剪贴板...")

            if checkPasteboardAndOpenParser() {
                // 找到图片，停止检查
                addDebugMessage("✅ 已找到图片，停止监听")
                timer.invalidate()
                pasteboardCheckTimer = nil
            } else if checkCount >= 6 {
                // 检查了3秒（6次×0.5秒），停止
                addDebugMessage("⚠️ 监听3秒未发现图片，停止监听")
                addDebugMessage("💡 提示：确保快捷指令有'拷贝到剪贴板'步骤")
                timer.invalidate()
                pasteboardCheckTimer = nil

                // 自动显示调试信息
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        showDebugOverlay = true
                    }
                }
            }
        }
    }

    private func stopPasteboardMonitoring() {
        pasteboardCheckTimer?.invalidate()
        pasteboardCheckTimer = nil
    }

    @discardableResult
    private func checkPasteboardAndOpenParser() -> Bool {
        // 检查剪贴板内容类型
        let types = UIPasteboard.general.types
        addDebugMessage("📎 剪贴板类型: \(types.joined(separator: ", "))")

        // 检查剪贴板是否有图片
        if UIPasteboard.general.hasImages {
            addDebugMessage("📋 剪贴板中发现图片内容")

            if let image = UIPasteboard.general.image {
                let imageSize = image.size
                addDebugMessage("🖼️ 图片尺寸: \(imageSize.width) x \(imageSize.height)")

                // 防止重复打开
                guard appState.receivedImage == nil else {
                    addDebugMessage("⚠️ 图片已加载，跳过")
                    return true
                }

                addDebugMessage("✅ 成功获取图片，开始后台识别")

                // 直接后台处理，不打开界面
                processImageInBackground(image)

                return true
            } else {
                addDebugMessage("❌ 剪贴板有图片标记但获取失败")
            }
        } else {
            addDebugMessage("❌ 剪贴板中没有图片内容")
        }
        return false
    }

    private func addDebugMessage(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let fullMessage = "[\(timestamp)] \(message)"
        print(fullMessage)
        DispatchQueue.main.async {
            debugMessages.append(fullMessage)
            // 限制最多保存50条
            if debugMessages.count > 50 {
                debugMessages.removeFirst()
            }
        }
    }

    // 后台处理图片识别
    private func processImageInBackground(_ image: UIImage) {
        addDebugMessage("🔄 开始OCR识别... 图片尺寸: \(image.size.width)x\(image.size.height)")

        // 创建OCR处理器并保存到状态变量，防止过早释放
        let processor = BackgroundOCRProcessor(appState: appState, debugCallback: { message in
            self.addDebugMessage(message)
        })
        self.currentProcessor = processor  // 保持引用

        processor.processImage(image) { success, count in
            DispatchQueue.main.async {
                if success {
                    self.addDebugMessage("✅ 识别成功: \(count)条账单")
                    self.addDebugMessage("📋 待确认账单数: \(self.appState.pendingBills.count)")
                } else {
                    self.addDebugMessage("❌ 识别失败")
                }
                // 完成后清除引用
                self.currentProcessor = nil
            }
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let onScanTapped: () -> Void

    var body: some View {
        ZStack {
            // 底部导航栏背景
            HStack(spacing: 0) {
                // 左侧标签
                ForEach(0..<2) { index in
                    TabBarButton(
                        icon: tabIcon(for: index),
                        title: tabTitle(for: index),
                        isSelected: selectedTab == index,
                        action: { selectedTab = index }
                    )
                }

                // 中间的扫描按钮占位
                Spacer()
                    .frame(width: 80)

                // 右侧标签
                ForEach(3..<5) { index in
                    TabBarButton(
                        icon: tabIcon(for: index),
                        title: tabTitle(for: index),
                        isSelected: selectedTab == index,
                        action: { selectedTab = index }
                    )
                }
            }
            .padding(.horizontal)
            .frame(height: 70)
            .background(Color.white)
            .cornerRadius(0)
            .shadow(color: .gray.opacity(0.2), radius: 10, y: -5)

            // 中间的浮动按钮
            Button(action: {
                onScanTapped()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 64, height: 64)
                        .shadow(color: .blue.opacity(0.3), radius: 10)

                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -20)
        }
    }

    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "house.fill"
        case 1: return "chart.pie.fill"
        case 3: return "book.fill"
        case 4: return "person.fill"
        default: return ""
        }
    }

    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "记账"
        case 1: return "统计"
        case 3: return "账本"
        case 4: return "我的"
        default: return ""
        }
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(title)
                    .font(.system(size: 10))
            }
            .foregroundColor(isSelected ? .blue : .gray)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - 账单确认悬浮层
struct BillConfirmationOverlay: View {
    @EnvironmentObject var appState: AppState
    @State private var offset: CGFloat = 0
    @State private var rotation: Double = 0

    var currentBill: PendingBill? {
        guard appState.currentBillIndex < appState.pendingBills.count else { return nil }
        return appState.pendingBills[appState.currentBillIndex]
    }

    var body: some View {
        ZStack {
            // 半透明遮罩
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    // 点击背景跳过所有
                    withAnimation {
                        appState.pendingBills.removeAll()
                        appState.currentBillIndex = 0
                    }
                }

            // 卡片
            if let bill = currentBill {
                BillCardView(
                    bill: bill,
                    offset: $offset,
                    rotation: $rotation,
                    onConfirm: {
                        confirmCurrentBill()
                    },
                    onDelete: {
                        deleteCurrentBill()
                    }
                )
                .frame(maxWidth: 340)
            }
        }
    }

    private func confirmCurrentBill() {
        guard let bill = currentBill else { return }

        // 转换为Transaction并保存
        let transaction = Transaction(
            merchantName: bill.merchantName,
            description: bill.description ?? "无备注",
            amount: bill.amount,
            type: bill.type,
            category: bill.category,
            icon: bill.icon
        )
        appState.addTransaction(transaction)

        // 移动到下一张
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            appState.currentBillIndex += 1
        }

        // 如果全部确认完毕,清空列表
        if appState.currentBillIndex >= appState.pendingBills.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    appState.pendingBills.removeAll()
                    appState.currentBillIndex = 0
                }
            }
        }
    }

    private func deleteCurrentBill() {
        // 移动到下一张
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            appState.currentBillIndex += 1
        }

        // 如果全部处理完毕,清空列表
        if appState.currentBillIndex >= appState.pendingBills.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    appState.pendingBills.removeAll()
                    appState.currentBillIndex = 0
                }
            }
        }
    }
}

// MARK: - 账单卡片视图
struct BillCardView: View {
    let bill: PendingBill
    @Binding var offset: CGFloat
    @Binding var rotation: Double
    let onConfirm: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                // 顶部：图标和金额
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        bill.category.color.opacity(0.3),
                                        bill.category.color.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)

                        Image(systemName: bill.icon)
                            .font(.system(size: 32))
                            .foregroundColor(bill.category.color)
                    }

                    Text(String(format: "%@¥%.2f",
                              bill.amount >= 0 ? "+" : "",
                              abs(bill.amount)))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(bill.amount >= 0 ? .green : .red)

                    Text(bill.type == .income ? "收入" : "支出")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                .padding(.top, 24)

                Divider()
                    .padding(.horizontal, 16)

                // 详情
                VStack(spacing: 12) {
                    BillDetailRow(icon: "building.2.fill", iconColor: .blue, title: "商户", value: bill.merchantName)

                    if let description = bill.description, !description.isEmpty {
                        BillDetailRow(icon: "doc.text.fill", iconColor: .orange, title: "备注", value: description)
                    }

                    BillDetailRow(icon: "tag.fill", iconColor: bill.category.color, title: "分类", value: bill.category.rawValue)

                    BillDetailRow(icon: "calendar", iconColor: .purple, title: "时间", value: formatDateTime(bill.date))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // 操作按钮
                HStack(spacing: 12) {
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
        .offset(x: offset)
        .rotationEffect(.degrees(rotation))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation.width
                    rotation = Double(gesture.translation.width / 20)
                }
                .onEnded { gesture in
                    let threshold: CGFloat = 120
                    if gesture.translation.width > threshold {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            offset = 500
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            offset = 0
                            rotation = 0
                            onConfirm()
                        }
                    } else if gesture.translation.width < -threshold {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            offset = -500
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            offset = 0
                            rotation = 0
                            onDelete()
                        }
                    } else {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            offset = 0
                            rotation = 0
                        }
                    }
                }
        )
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
}

// 账单详情行
struct BillDetailRow: View {
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

// MARK: - 后台OCR处理器
import Vision

class BackgroundOCRProcessor {
    let appState: AppState
    let debugCallback: ((String) -> Void)?

    init(appState: AppState, debugCallback: ((String) -> Void)? = nil) {
        self.appState = appState
        self.debugCallback = debugCallback
    }

    func processImage(_ image: UIImage, completion: @escaping (Bool, Int) -> Void) {
        debugCallback?("🎬 BackgroundOCRProcessor.processImage 开始")

        guard let cgImage = image.cgImage else {
            debugCallback?("❌ 无法获取CGImage")
            completion(false, 0)
            return
        }

        debugCallback?("📸 CGImage 准备完成,开始Vision识别")

        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }

            if let error = error {
                self.debugCallback?("❌ Vision错误: \(error.localizedDescription)")
                completion(false, 0)
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                self.debugCallback?("❌ 无法获取识别结果")
                completion(false, 0)
                return
            }

            self.debugCallback?("📊 Vision识别完成,共\(observations.count)个文本块")

            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }

            let text = recognizedStrings.joined(separator: "\n")
            self.debugCallback?("📝 识别文字(\(text.count)字符):\n\(text)")

            // 解析账单
            let pendingBills = self.parseBillsFromText(text)
            self.debugCallback?("📊 解析结果: \(pendingBills.count) 条账单")

            for (i, bill) in pendingBills.enumerated() {
                self.debugCallback?("  账单\(i+1): \(bill.merchantName) ¥\(bill.amount)")
            }

            DispatchQueue.main.async {
                if !pendingBills.isEmpty {
                    self.debugCallback?("💾 保存到AppState: \(pendingBills.count)条")
                    self.appState.pendingBills = pendingBills
                    self.appState.currentBillIndex = 0
                    completion(true, pendingBills.count)
                } else {
                    self.debugCallback?("⚠️ 未解析到任何账单")
                    completion(false, 0)
                }
            }
        }

        request.recognitionLanguages = ["zh-Hans", "en-US"]
        request.recognitionLevel = .accurate

        debugCallback?("🔧 配置Vision请求: 语言=zh-Hans,en-US, 级别=accurate")

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        debugCallback?("⚙️ 创建VNImageRequestHandler完成")

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.debugCallback?("🚀 在后台线程开始执行Vision请求...")
            do {
                try handler.perform([request])
                self?.debugCallback?("✅ Vision请求执行完成")
            } catch {
                self?.debugCallback?("❌ Vision请求执行失败: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false, 0)
                }
            }
        }
    }

    // 辅助结构
    private struct TransactionCandidate {
        let lineIndex: Int
        let amount: Double
        let line: String
    }

    // 完整的账单解析逻辑（从ImageParserView复制）
    private func parseBillsFromText(_ text: String) -> [PendingBill] {
        var bills: [PendingBill] = []
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        debugCallback?("🔍 开始解析，共 \(lines.count) 行文字")
        for (i, line) in lines.enumerated() {
            debugCallback?("  第\(i+1)行: \(line)")
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
                debugCallback?("  ✅ 第\(index+1)行找到金额: ¥\(amount)")
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
                        debugCallback?("  ✅ 第\(index+1)-\(index+2)行跨行找到金额: ¥\(amount)")
                        foundAmounts.append(TransactionCandidate(
                            lineIndex: index,
                            amount: amount,
                            line: combinedLine
                        ))
                        processedIndices.insert(index)
                        processedIndices.insert(index + 1) // 标记下一行也已处理
                    } else {
                        debugCallback?("  ❌ 第\(index+1)行未找到金额")
                    }
                } else {
                    debugCallback?("  ❌ 第\(index+1)行未找到金额")
                }
            }
        }

        debugCallback?("💰 共找到 \(foundAmounts.count) 个金额")

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

                bills.append(PendingBill(
                    merchantName: merchantName,
                    amount: finalAmount,
                    type: transactionType,
                    category: category,
                    description: "第\(bills.count + 1)笔交易",
                    date: Date(),
                    icon: category.icon
                ))
            }
        } else if foundAmounts.count == 1 {
            // 只有一条交易
            if let candidate = foundAmounts.first {
                let transactionType = detectTransactionType(from: text)
                let finalAmount = transactionType == .income ? candidate.amount : -abs(candidate.amount)
                let merchantName = extractMerchantName(from: candidate.line, context: text)
                let category = classifyTransaction(text: text, transactionType: transactionType)

                bills.append(PendingBill(
                    merchantName: merchantName,
                    amount: finalAmount,
                    type: transactionType,
                    category: category,
                    description: "通过图像识别",
                    date: Date(),
                    icon: category.icon
                ))
            }
        }

        return bills
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

        var merchantName = cleanLine.trimmingCharacters(in: .whitespacesAndNewlines)

        // 如果提取的商户名太长或为空，使用默认值
        if merchantName.isEmpty || merchantName.count > 30 {
            merchantName = "未知商户"
        }

        return merchantName
    }

    // 检测交易类型
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
}

#Preview {
    MainTabView()
}
