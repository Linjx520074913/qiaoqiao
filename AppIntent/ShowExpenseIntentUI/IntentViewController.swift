//
//  IntentViewController.swift
//  ShowExpenseIntentUI
//
//  Created by linjx on 2025/12/29.
//

import IntentsUI
import UIKit

class IntentViewController: UIViewController, INUIHostedViewControlling {

    // MARK: - UI Elements
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let merchantLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let debugLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let amountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
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

        setupUI()
        startMonitoringSharedData()
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

        // 添加子视图
        view.addSubview(statusLabel)
        view.addSubview(loadingIndicator)
        view.addSubview(merchantLabel)
        view.addSubview(amountLabel)
        view.addSubview(debugLabel)

        // 布局
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            loadingIndicator.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            merchantLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 20),
            merchantLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            merchantLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            amountLabel.topAnchor.constraint(equalTo: merchantLabel.bottomAnchor, constant: 8),
            amountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            amountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            debugLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 8),
            debugLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            debugLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            debugLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -20)
        ])

        // 初始状态：显示"分析中..."
        showAnalyzing()
    }

    // MARK: - State Management
    private func showAnalyzing() {
        countdown = 3
        statusLabel.text = "分析中... 3s"
        merchantLabel.text = ""
        amountLabel.text = ""
        loadingIndicator.startAnimating()

        // 启动点点动画
        startDotAnimation()
        // 启动倒计时
        startCountdown()
        // 启动 3 秒后显示结果的定时器
        scheduleResultDisplay()
    }

    private func showResult(merchant: String, amount: Double) {
        // 停止所有动画
        dotAnimationTimer?.invalidate()
        countdownTimer?.invalidate()
        loadingIndicator.stopAnimating()

        // 显示结果
        statusLabel.text = "识别完成"
        merchantLabel.text = merchant
        amountLabel.text = String(format: "¥%.2f", amount)
        amountLabel.textColor = .systemGreen
    }

    private func showError(message: String) {
        dotAnimationTimer?.invalidate()
        countdownTimer?.invalidate()
        loadingIndicator.stopAnimating()

        statusLabel.text = "识别失败"
        merchantLabel.text = message
        amountLabel.text = ""
        amountLabel.textColor = .systemRed
    }

    // MARK: - Dot Animation
    private func startDotAnimation() {
        dotCount = 0
        dotAnimationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.dotCount = (self.dotCount + 1) % 4
            let dots = String(repeating: ".", count: self.dotCount)
            self.statusLabel.text = "分析中\(dots) \(self.countdown)s"
        }
    }

    // MARK: - Countdown
    private func startCountdown() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.countdown -= 1
            if self.countdown >= 0 {
                let dots = String(repeating: ".", count: self.dotCount)
                self.statusLabel.text = "分析中\(dots) \(self.countdown)s"
            }
            if self.countdown < 0 {
                self.countdownTimer?.invalidate()
            }
        }
    }

    // MARK: - Result Display
    private func scheduleResultDisplay() {
        debugLabel.text = "等待数据..."
        print("🕐 [IntentUI] 开始等待数据")

        // 记录启动时间
        let startTime = Date()

        // 定时检查数据,最多等待 5 秒
        resultTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] timer in
            guard let self = self else {
                print("⚠️ [IntentUI] self 已释放")
                timer.invalidate()
                return
            }

            let elapsed = Date().timeIntervalSince(startTime)

            // 超时检查
            if elapsed > 5.0 {
                print("⏱️ [IntentUI] 等待超时 (5秒)")
                timer.invalidate()
                self.debugLabel.text = "❌ 等待超时"
                self.showError(message: "未收到识别结果")
                return
            }

            // 从 App Group 读取数据
            guard let sharedDefaults = UserDefaults(suiteName: self.appGroupIdentifier) else {
                print("❌ [IntentUI] 无法访问 App Group")
                return
            }

            // 检查是否有数据
            if let merchant = sharedDefaults.string(forKey: "expense_merchant"), !merchant.isEmpty {
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
                    print("⏳ [IntentUI] 等待中... \(String(format: "%.1f", elapsed))秒")
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

        // 配置视图大小
        let desiredSize = CGSize(width: self.extensionContext!.hostedViewMaximumAllowedSize.width,
                                height: 200)

        completion(true, parameters, desiredSize)
    }

    var desiredSize: CGSize {
        return CGSize(width: self.extensionContext!.hostedViewMaximumAllowedSize.width, height: 200)
    }
}
