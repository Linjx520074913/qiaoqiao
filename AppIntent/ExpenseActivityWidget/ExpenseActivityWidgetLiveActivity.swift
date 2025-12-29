//
//  ExpenseActivityWidgetLiveActivity.swift
//  ExpenseActivityWidget
//
//  Created by linjx on 2025/12/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ExpenseActivityWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var merchant: String
        var amount: Double
        var time: String?
        var message: String
    }

    var id: String
}

struct ExpenseActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ExpenseActivityWidgetAttributes.self) { context in
            // Lock screen/banner UI
            ExpenseLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.blue)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("¥\(String(format: "%.2f", context.state.amount))")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .invalidatableContent()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.merchant)
                        .font(.caption)
                        .lineLimit(1)
                        .invalidatableContent()
                }
            } compactLeading: {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.blue)
            } compactTrailing: {
                Text("¥\(String(format: "%.0f", context.state.amount))")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .invalidatableContent()
            } minimal: {
                Image(systemName: "creditcard.fill")
            }
        }
    }
}

struct ExpenseLiveActivityView: View {
    let context: ActivityViewContext<ExpenseActivityWidgetAttributes>

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "creditcard.fill")
                .font(.title3)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(context.state.message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .invalidatableContent()

                if let time = context.state.time, !time.isEmpty {
                    Text(time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .invalidatableContent()
                }
            }

            Spacer()

            Text("¥\(String(format: "%.2f", context.state.amount))")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .invalidatableContent()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .activityBackgroundTint(Color(white: 0.95))
        .activitySystemActionForegroundColor(.black)
    }
}

extension ExpenseActivityWidgetAttributes {
    fileprivate static var preview: ExpenseActivityWidgetAttributes {
        ExpenseActivityWidgetAttributes(id: "preview")
    }
}

extension ExpenseActivityWidgetAttributes.ContentState {
    fileprivate static var analyzing: ExpenseActivityWidgetAttributes.ContentState {
        ExpenseActivityWidgetAttributes.ContentState(
            merchant: "分析中...",
            amount: 0,
            time: nil,
            message: "正在处理账单图片"
        )
    }

    fileprivate static var completed: ExpenseActivityWidgetAttributes.ContentState {
        ExpenseActivityWidgetAttributes.ContentState(
            merchant: "测试商家",
            amount: 99.99,
            time: "12:30",
            message: "测试商家 ¥99.99"
        )
    }
}

#Preview("Notification", as: .content, using: ExpenseActivityWidgetAttributes.preview) {
   ExpenseActivityWidgetLiveActivity()
} contentStates: {
    ExpenseActivityWidgetAttributes.ContentState.analyzing
    ExpenseActivityWidgetAttributes.ContentState.completed
}
