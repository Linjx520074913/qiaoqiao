//
//  AppIntentApp.swift
//  AppIntent
//
//  Created by linjx on 2025/12/22.
//

import SwiftUI
import AppIntents

@main
struct AppIntentApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// INIntent 不需要 AppShortcuts，通过 .intentdefinition 文件配置
// 注释掉旧的 AppIntent 配置
/*
struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShowExpenseIntent(),
            phrases: [
                "在 \(.applicationName) 显示消费卡片",
                "用 \(.applicationName) 记录消费"
            ],
            shortTitle: "显示消费卡片",
            systemImageName: "creditcard.fill"
        )
    }
}
*/

// 注册 Live Activity Widget
@available(iOS 16.1, *)
struct ExpenseWidgets: WidgetBundle {
    var body: some Widget {
        ExpenseActivityView()
    }
}
