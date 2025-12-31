//
//  IntentViewController.swift
//  ShowExpenseIntentUI
//
//  Created by linjx on 2025/12/29.
//

import IntentsUI
import UIKit

class IntentViewController: UIViewController, INUIHostedViewControlling {

    // MARK: - Init
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        print("🎬🎬🎬 [IntentUI] init(nibName:bundle:) 被调用")
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        print("🎬🎬🎬 [IntentUI] init(coder:) 被调用")
    }

    // MARK: - UI Elements

    // 头部容器
    private let headerContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // 应用图标
    private let appIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "SlothIcon")
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 8
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    // 应用标题
    private let appTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "悄悄记账 | 自动记账"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // 状态容器（带圆角背景，自适应宽度的胶囊形状）
    private let statusContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGray6
        view.layer.cornerRadius = 20  // 更大的圆角，形成胶囊效果
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // 状态图标
    private let statusIconLabel: UILabel = {
        let label = UILabel()
        label.text = "🧐"
        label.font = UIFont.systemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // 状态文字
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "分析中..."
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // 提示文字
    private let hintLabel: UILabel = {
        let label = UILabel()
        label.text = "呼呼，胖胖正在努力分析账单..."
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // 完成按钮 - 已移除，使用系统按钮
    // private let completeButton: UIButton = { ... }()

    // 调试标签
    private let debugLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 9, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .systemGray3
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var dotAnimationTimer: Timer?
    private var dotCount = 0
    private var statusCheckTimer: Timer?
    private var countdownTimer: Timer?
    private var countdown = 3
    private var resultTimer: Timer?

    // App Group 标识符
    private let appGroupIdentifier = "group.com.dm.AppIntent"

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        print("🎬 [IntentUI] viewDidLoad 被调用")

        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("👀 [IntentUI] viewWillAppear - view.frame: \(view.frame)")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("✨ [IntentUI] viewDidAppear - view.frame: \(view.frame)")
    }

    deinit {
        dotAnimationTimer?.invalidate()
        statusCheckTimer?.invalidate()
        countdownTimer?.invalidate()
        resultTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground

        // 添加头部
        view.addSubview(headerContainer)
        headerContainer.addSubview(appIconImageView)
        headerContainer.addSubview(appTitleLabel)

        // 添加状态容器
        view.addSubview(statusContainer)
        statusContainer.addSubview(statusIconLabel)
        statusContainer.addSubview(statusLabel)

        // 添加提示文字
        view.addSubview(hintLabel)

        // 添加调试标签
        view.addSubview(debugLabel)

        // 立即开始识别
        startBillRecognition()

        // 布局约束
        NSLayoutConstraint.activate([
            // 头部容器 - 使用 safeAreaLayoutGuide 以避免被系统标题遮挡
            headerContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            headerContainer.heightAnchor.constraint(equalToConstant: 32),

            // 应用图标
            appIconImageView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            appIconImageView.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            appIconImageView.widthAnchor.constraint(equalToConstant: 32),
            appIconImageView.heightAnchor.constraint(equalToConstant: 32),

            // 应用标题
            appTitleLabel.leadingAnchor.constraint(equalTo: appIconImageView.trailingAnchor, constant: 8),
            appTitleLabel.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),

            // 状态容器 - 自适应宽度，胶囊形状
            statusContainer.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 20),
            statusContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            statusContainer.heightAnchor.constraint(equalToConstant: 40),

            // 状态图标
            statusIconLabel.leadingAnchor.constraint(equalTo: statusContainer.leadingAnchor, constant: 12),
            statusIconLabel.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),

            // 状态文字
            statusLabel.leadingAnchor.constraint(equalTo: statusIconLabel.trailingAnchor, constant: 6),
            statusLabel.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: statusContainer.trailingAnchor, constant: -14),

            // 提示文字
            hintLabel.topAnchor.constraint(equalTo: statusContainer.bottomAnchor, constant: 40),
            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            // 调试标签
            debugLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            debugLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            debugLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
    }

    // 完成按钮处理方法已移除，使用系统按钮

    // MARK: - State Management
    private func showAnalyzing() {
        statusIconLabel.text = "🧐"
        statusLabel.text = "分析中..."
        hintLabel.text = "呼呼，胖胖正在努力分析账单..."

        // 启动数据轮询
        scheduleResultDisplay()
    }

    private func showResult(merchant: String, amount: Double) {
        // 停止所有动画
        dotAnimationTimer?.invalidate()
        countdownTimer?.invalidate()

        // 更新状态
        statusIconLabel.text = "✅"
        statusLabel.text = "识别完成"
        hintLabel.text = "\(merchant) · ¥\(String(format: "%.2f", amount))"
    }

    private func showError(message: String) {
        dotAnimationTimer?.invalidate()
        countdownTimer?.invalidate()

        statusIconLabel.text = "❌"
        statusLabel.text = "识别失败"
        hintLabel.text = message
    }

    // MARK: - Dot Animation (已弃用，使用脉冲动画代替)
    private func startDotAnimation() {
        // 现在使用 startPulseAnimation() 代替
    }

    // MARK: - Bill Recognition
    private func startBillRecognition() {
        print("🚀 [IntentUI] 开始识别流程...")

        Task {
            await performBillScan()
        }
    }

    private func performBillScan() async {
        print("📸 [IntentUI] 开始从共享容器读取图片...")
        print("🔑 [IntentUI] App Group ID: \(appGroupIdentifier)")

        // 从共享容器读取图片
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            print("❌ [IntentUI] 无法访问共享容器")
            print("❌ [IntentUI] 请检查 ShowExpenseIntentUI target 的 Signing & Capabilities")
            print("❌ [IntentUI] 确保已添加 App Groups 权限: \(appGroupIdentifier)")

            await MainActor.run {
                showError(message: "无法访问共享容器\n请检查 App Groups 权限配置")
            }
            return
        }

        let imageURL = containerURL.appendingPathComponent("bill_image.jpg")
        print("📁 [IntentUI] 图片路径: \(imageURL.path)")

        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            print("❌ [IntentUI] 图片文件不存在")

            // 列出共享容器中的所有文件
            do {
                let files = try FileManager.default.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil)
                print("📂 [IntentUI] 共享容器中的文件: \(files.map { $0.lastPathComponent })")
            } catch {
                print("❌ [IntentUI] 无法列出文件: \(error)")
            }

            showError(message: "未找到图片文件，请先执行 保存账单图片")
            return
        }

        guard let imageData = try? Data(contentsOf: imageURL),
              let image = UIImage(data: imageData) else {
            print("❌ [IntentUI] 无法加载图片")
            showError(message: "图片加载失败")
            return
        }

        print("✅ [IntentUI] 图片加载成功，大小: \(imageData.count) bytes")
        print("🌐 [IntentUI] 开始调用 API...")

        // 调用后端 API
        do {
            let scanService = BillScanService.shared
            print("📡 [IntentUI] 正在上传图片并识别...")

            let result = try await scanService.scanBill(image: image)

            print("📥 [IntentUI] API 返回结果: success=\(result.success)")

            await MainActor.run {
                if result.success, let data = result.data, let invoice = data.invoice {
                    let merchant = invoice.merchant ?? "未知商家"
                    let amount = invoice.total ?? 0.0

                    print("✅ [IntentUI] 识别成功: \(merchant) - ¥\(amount)")
                    showResult(merchant: merchant, amount: amount)
                } else {
                    let errorMsg = result.error ?? "识别失败"
                    print("❌ [IntentUI] 识别失败: \(errorMsg)")
                    showError(message: errorMsg)
                }
            }
        } catch {
            print("❌ [IntentUI] API 调用失败: \(error.localizedDescription)")
            print("❌ [IntentUI] 错误详情: \(error)")

            await MainActor.run {
                showError(message: "网络请求失败: \(error.localizedDescription)")
            }
        }

        // 删除临时图片
        try? FileManager.default.removeItem(at: imageURL)
        print("🗑️ [IntentUI] 已删除临时图片")
    }

    // MARK: - Result Display
    private func scheduleResultDisplay() {
        debugLabel.text = "等待数据..."
        print("🕐 [IntentUI] 开始等待数据")

        // 记录启动时间
        let startTime = Date()

        // 定时检查数据,最多等待 30 秒（给 API 足够的识别时间）
        resultTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] timer in
            guard let self = self else {
                print("⚠️ [IntentUI] self 已释放")
                timer.invalidate()
                return
            }

            let elapsed = Date().timeIntervalSince(startTime)

            // 超时检查 - 延长到 30 秒
            if elapsed > 30.0 {
                print("⏱️ [IntentUI] 等待超时 (30秒)")
                timer.invalidate()
                self.debugLabel.text = "❌ 等待超时"
                self.showError(message: "识别超时，请重试")
                return
            }

            // 从 App Group 读取数据
            guard let sharedDefaults = UserDefaults(suiteName: self.appGroupIdentifier) else {
                print("❌ [IntentUI] 无法访问 App Group")
                return
            }

            // 检查状态
            let status = sharedDefaults.string(forKey: "expense_status") ?? ""

            // 如果是错误状态
            if status == "error" {
                let errorMsg = sharedDefaults.string(forKey: "expense_merchant") ?? "识别失败"
                print("❌ [IntentUI] 检测到错误: \(errorMsg), 耗时: \(String(format: "%.2f", elapsed))秒")
                timer.invalidate()

                // 停止所有动画
                self.statusCheckTimer?.invalidate()
                self.countdownTimer?.invalidate()
                self.dotAnimationTimer?.invalidate()

                // 显示错误
                self.showError(message: errorMsg)

                // 清除数据
                sharedDefaults.removeObject(forKey: "expense_status")
                sharedDefaults.removeObject(forKey: "expense_merchant")
                sharedDefaults.removeObject(forKey: "expense_amount")
                sharedDefaults.removeObject(forKey: "expense_start_time")
                return
            }

            // 如果是完成状态
            if status == "completed" {
                let merchant = sharedDefaults.string(forKey: "expense_merchant") ?? "未知商家"
                let amount = sharedDefaults.double(forKey: "expense_amount")

                print("✅ [IntentUI] 检测到数据: \(merchant) - ¥\(amount), 耗时: \(String(format: "%.2f", elapsed))秒")
                timer.invalidate()

                // 停止所有动画
                self.statusCheckTimer?.invalidate()
                self.countdownTimer?.invalidate()
                self.dotAnimationTimer?.invalidate()

                // 显示结果
                self.showResult(merchant: merchant, amount: amount)

                // 清除数据
                sharedDefaults.removeObject(forKey: "expense_status")
                sharedDefaults.removeObject(forKey: "expense_merchant")
                sharedDefaults.removeObject(forKey: "expense_amount")
                sharedDefaults.removeObject(forKey: "expense_start_time")
                sharedDefaults.removeObject(forKey: "debug_status")
            } else {
                // 继续等待
                if Int(elapsed * 10) % 10 == 0 {  // 每秒打印一次
                    print("⏳ [IntentUI] 等待中... 状态: \(status), 耗时: \(String(format: "%.1f", elapsed))秒")
                }
            }
        }
        print("✅ [IntentUI] 开始轮询数据")
    }

    // MARK: - Data Monitoring
    private func startMonitoringSharedData() {
        // 使用定时器轮询共享数据
        statusCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.checkSharedData()
        }
    }

    private func checkSharedData() {
        // 这个方法现在只用来调试，实际显示由 scheduleResultDisplay 控制
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return
        }

        if let status = sharedDefaults.string(forKey: "expense_status") {
            print("📱 [IntentUI] 轮询状态: \(status)")
        }
    }

    // MARK: - INUIHostedViewControlling
    func configureView(for parameters: Set<INParameter>, of interaction: INInteraction, interactiveBehavior: INUIInteractiveBehavior, context: INUIHostedViewContext, completion: @escaping (Bool, Set<INParameter>, CGSize) -> Void) {

        print("🎨🎨🎨 [IntentUI] configureView 被调用!!!")
        print("   - interactiveBehavior: \(interactiveBehavior.rawValue)")
        print("   - context: \(context.rawValue)")
        print("   - interaction.intent: \(interaction.intent)")
        print("   - hostedViewMaximumAllowedSize: \(self.extensionContext!.hostedViewMaximumAllowedSize)")

        // 设置合适的高度以容纳所有元素
        let desiredSize = CGSize(width: self.extensionContext!.hostedViewMaximumAllowedSize.width,
                                height: 280)

        print("   - 返回的 desiredSize: \(desiredSize)")

        // 对于 information category 的 Intent，需要返回 true 表示我们要显示自定义 UI
        completion(true, parameters, desiredSize)
    }

    var desiredSize: CGSize {
        return CGSize(width: self.extensionContext!.hostedViewMaximumAllowedSize.width, height: 220)
    }
}
