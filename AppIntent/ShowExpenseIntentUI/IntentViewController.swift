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

    // 内容容器（白色背景）
    private let contentContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground  // 白色背景
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
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = .label  // 系统主文字颜色（深色）
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // 状态容器（带圆角背景，自适应宽度的胶囊形状）
    private let statusContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.95, alpha: 1.0)  // 浅灰蓝色
        view.layer.cornerRadius = 20  // 更大的圆角，形成胶囊效果
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // 状态图标 - 思考树懒
    private let statusIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "ThinkingSloth")
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear  // 确保背景透明
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
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

    // 账单图标
    private let receiptIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "ReceiptIcon")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    // 提示文字容器
    private let hintContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear  // 透明背景
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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

    // 网络错误容器（用于居中显示图标和文字）
    private let networkErrorContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    // 网络错误图标（大图标，用于网络错误时显示）
    private let networkErrorIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "NetworkErrorSloth")
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    // 网络错误提示文字（在图标右侧显示）
    private let networkErrorLabel: UILabel = {
        let label = UILabel()
        label.text = "网络异常，请检查网络后重试"
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = .label
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // 结果容器 - 用于显示识别成功后的商家信息
    private let resultContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true  // 初始隐藏
        return view
    }()

    // 商家图标
    private let merchantIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        imageView.layer.cornerRadius = 12
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // 默认显示一个占位图标
        imageView.image = UIImage(systemName: "storefront.fill")
        imageView.tintColor = .systemGray
        return imageView
    }()

    // 商家名称
    private let merchantNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // 金额标签
    private let amountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .systemRed
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
        view.backgroundColor = .systemGray6  // 和系统弹窗顶部颜色一致

        // 添加头部
        view.addSubview(headerContainer)
        headerContainer.addSubview(appIconImageView)
        headerContainer.addSubview(appTitleLabel)

        // 添加内容容器
        view.addSubview(contentContainer)

        // 添加树懒图标和状态容器到内容容器
        contentContainer.addSubview(statusIconImageView)
        contentContainer.addSubview(statusContainer)
        statusContainer.addSubview(statusLabel)

        // 添加账单图标
        contentContainer.addSubview(receiptIconImageView)

        // 添加提示文字容器到内容容器
        contentContainer.addSubview(hintContainer)
        hintContainer.addSubview(hintLabel)

        // 添加网络错误容器及其子视图
        contentContainer.addSubview(networkErrorContainer)
        networkErrorContainer.addSubview(networkErrorIconImageView)
        networkErrorContainer.addSubview(networkErrorLabel)

        // 添加结果容器
        contentContainer.addSubview(resultContainer)
        resultContainer.addSubview(merchantIconImageView)
        resultContainer.addSubview(merchantNameLabel)
        resultContainer.addSubview(amountLabel)

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

            // 内容容器 - 白色背景，和标题栏分开，完全贴边，延伸到底部
            contentContainer.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 12),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // 树懒图标 - 独立显示，无背景（网络错误时会调整位置和大小）
            statusIconImageView.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 16),
            statusIconImageView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 16),
            statusIconImageView.widthAnchor.constraint(equalToConstant: 48),
            statusIconImageView.heightAnchor.constraint(equalToConstant: 48),

            // 状态容器 - 只包含文字的胶囊
            statusContainer.centerYAnchor.constraint(equalTo: statusIconImageView.centerYAnchor),
            statusContainer.leadingAnchor.constraint(equalTo: statusIconImageView.trailingAnchor, constant: 12),
            statusContainer.heightAnchor.constraint(equalToConstant: 32),

            // 状态文字
            statusLabel.leadingAnchor.constraint(equalTo: statusContainer.leadingAnchor, constant: 14),
            statusLabel.centerYAnchor.constraint(equalTo: statusContainer.centerYAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: statusContainer.trailingAnchor, constant: -14),

            // 账单图标 - 在状态容器和提示文字之间
            receiptIconImageView.topAnchor.constraint(equalTo: statusIconImageView.bottomAnchor, constant: 20),
            receiptIconImageView.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
            receiptIconImageView.widthAnchor.constraint(equalToConstant: 80),
            receiptIconImageView.heightAnchor.constraint(equalToConstant: 80),

            // 提示文字容器 - 浅绿色背景
            hintContainer.topAnchor.constraint(equalTo: receiptIconImageView.bottomAnchor, constant: 16),
            hintContainer.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 16),
            hintContainer.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -16),

            // 提示文字 - 在提示容器内
            hintLabel.topAnchor.constraint(equalTo: hintContainer.topAnchor, constant: 12),
            hintLabel.leadingAnchor.constraint(equalTo: hintContainer.leadingAnchor, constant: 12),
            hintLabel.trailingAnchor.constraint(equalTo: hintContainer.trailingAnchor, constant: -12),
            hintLabel.bottomAnchor.constraint(equalTo: hintContainer.bottomAnchor, constant: -12),

            // 网络错误容器 - 水平垂直居中
            networkErrorContainer.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
            networkErrorContainer.centerYAnchor.constraint(equalTo: contentContainer.centerYAnchor, constant: -20),
            networkErrorContainer.leadingAnchor.constraint(greaterThanOrEqualTo: contentContainer.leadingAnchor, constant: 20),
            networkErrorContainer.trailingAnchor.constraint(lessThanOrEqualTo: contentContainer.trailingAnchor, constant: -20),

            // 网络错误图标 - 在容器左侧
            networkErrorIconImageView.leadingAnchor.constraint(equalTo: networkErrorContainer.leadingAnchor),
            networkErrorIconImageView.centerYAnchor.constraint(equalTo: networkErrorContainer.centerYAnchor),
            networkErrorIconImageView.topAnchor.constraint(equalTo: networkErrorContainer.topAnchor),
            networkErrorIconImageView.bottomAnchor.constraint(equalTo: networkErrorContainer.bottomAnchor),
            networkErrorIconImageView.widthAnchor.constraint(equalToConstant: 100),
            networkErrorIconImageView.heightAnchor.constraint(equalToConstant: 100),

            // 网络错误文字 - 在图标右侧
            networkErrorLabel.leadingAnchor.constraint(equalTo: networkErrorIconImageView.trailingAnchor, constant: 16),
            networkErrorLabel.centerYAnchor.constraint(equalTo: networkErrorIconImageView.centerYAnchor),
            networkErrorLabel.trailingAnchor.constraint(equalTo: networkErrorContainer.trailingAnchor),

            // 结果容器 - 和账单图标占据相同位置
            resultContainer.topAnchor.constraint(equalTo: statusIconImageView.bottomAnchor, constant: 20),
            resultContainer.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 16),
            resultContainer.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -16),
            resultContainer.heightAnchor.constraint(equalToConstant: 80),

            // 商家图标
            merchantIconImageView.leadingAnchor.constraint(equalTo: resultContainer.leadingAnchor),
            merchantIconImageView.centerYAnchor.constraint(equalTo: resultContainer.centerYAnchor),
            merchantIconImageView.widthAnchor.constraint(equalToConstant: 60),
            merchantIconImageView.heightAnchor.constraint(equalToConstant: 60),

            // 商家名称
            merchantNameLabel.leadingAnchor.constraint(equalTo: merchantIconImageView.trailingAnchor, constant: 12),
            merchantNameLabel.topAnchor.constraint(equalTo: merchantIconImageView.topAnchor, constant: 8),

            // 金额标签
            amountLabel.leadingAnchor.constraint(equalTo: merchantIconImageView.trailingAnchor, constant: 12),
            amountLabel.bottomAnchor.constraint(equalTo: merchantIconImageView.bottomAnchor, constant: -8),

            // 调试标签
            debugLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            debugLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            debugLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
    }

    // 完成按钮处理方法已移除，使用系统按钮

    // MARK: - State Management
    private func showAnalyzing() {
        statusIconImageView.image = UIImage(named: "ThinkingSloth")
        statusLabel.text = "分析中..."

        // 隐藏提示容器
        hintContainer.isHidden = true

        // 启动数据轮询
        scheduleResultDisplay()
    }

    private func showResult(merchant: String, amount: Double) {
        // 停止所有动画
        dotAnimationTimer?.invalidate()
        countdownTimer?.invalidate()

        // 更新状态为开心树懒
        statusIconImageView.image = UIImage(named: "HappySloth")
        statusLabel.text = "识别完成"

        // 隐藏账单图标和提示容器
        UIView.animate(withDuration: 0.3) {
            self.receiptIconImageView.alpha = 0
            self.hintContainer.alpha = 0
        } completion: { _ in
            self.receiptIconImageView.isHidden = true
            self.hintContainer.isHidden = true
        }

        // 显示结果容器
        merchantNameLabel.text = merchant
        amountLabel.text = "¥\(String(format: "%.2f", amount))"

        resultContainer.alpha = 0
        resultContainer.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.resultContainer.alpha = 1
        }
    }

    private func showError(message: String) {
        dotAnimationTimer?.invalidate()
        countdownTimer?.invalidate()

        // 判断是否为网络相关错误
        let isNetworkError = message.contains("网络") ||
                           message.contains("Network") ||
                           message.contains("network") ||
                           message.contains("请求失败") ||
                           message.contains("连接")

        // 网络错误时：显示居中的图标 + 文字（参考 2.jpg）
        if isNetworkError {
            // 显示网络错误容器（图标 + 文字，水平垂直居中）
            networkErrorContainer.isHidden = false

            // 隐藏所有其他元素
            statusIconImageView.isHidden = true
            statusContainer.isHidden = true
            receiptIconImageView.isHidden = true
            hintContainer.isHidden = true
        } else {
            // 其他错误：显示完整信息
            statusIconImageView.image = UIImage(named: "SadSloth")
            statusIconImageView.isHidden = false

            statusLabel.text = "识别失败"
            statusContainer.isHidden = false

            hintLabel.text = message
            hintContainer.isHidden = false
            hintContainer.alpha = 1

            // 隐藏网络错误容器
            networkErrorContainer.isHidden = true
        }
    }

    // MARK: - Dot Animation
    private func startDotAnimation() {
        dotCount = 0
        dotAnimationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            self.dotCount = (self.dotCount + 1) % 4
            let dots = String(repeating: ".", count: self.dotCount)

            DispatchQueue.main.async {
                self.statusLabel.text = "分析中\(dots)"
            }
        }
    }

    // MARK: - Bill Recognition
    private func startBillRecognition() {
        print("🚀 [IntentUI] 开始识别流程...")

        // 启动点点动画
        startDotAnimation()

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
                // 统一使用"网络"关键词，确保触发网络错误显示
                if let urlError = error as? URLError {
                    showError(message: "网络请求失败")
                } else {
                    showError(message: "网络请求失败: \(error.localizedDescription)")
                }
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

        // 设置合适的高度以容纳所有元素（账单图标 + 结果区域）
        let desiredSize = CGSize(width: self.extensionContext!.hostedViewMaximumAllowedSize.width,
                                height: 240)

        print("   - 返回的 desiredSize: \(desiredSize)")

        // 对于 information category 的 Intent，需要返回 true 表示我们要显示自定义 UI
        completion(true, parameters, desiredSize)
    }

    var desiredSize: CGSize {
        return CGSize(width: self.extensionContext!.hostedViewMaximumAllowedSize.width, height: 220)
    }
}
