//
//  ExpenseActivityWidgetBundle.swift
//  ExpenseActivityWidget
//
//  Created by linjx on 2025/12/26.
//

import WidgetKit
import SwiftUI

@main
struct ExpenseActivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        // 只包含 Live Activity,不创建桌面小组件
        ExpenseActivityWidgetLiveActivity()
    }
}
