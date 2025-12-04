//
//  DebugOverlay.swift
//  bill
//
//  Created by linjx on 2025/12/4.
//

import SwiftUI

struct DebugOverlay: View {
    @Binding var isVisible: Bool
    @Binding var messages: [String]

    var body: some View {
        if isVisible {
            VStack(spacing: 0) {
                // 标题栏
                HStack {
                    Text("🔍 调试信息")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        withAnimation {
                            isVisible = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()
                .background(Color.blue)

                // 消息列表
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1).")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .frame(width: 30, alignment: .trailing)

                                Text(message)
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(messageColor(for: message))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                }
                .background(Color.black.opacity(0.05))
            }
            .frame(maxWidth: .infinity, maxHeight: 400)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.3), radius: 20)
            .padding()
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func messageColor(for message: String) -> Color {
        if message.contains("✅") {
            return .green
        } else if message.contains("❌") {
            return .red
        } else if message.contains("⚠️") {
            return .orange
        } else if message.contains("📱") {
            return .blue
        } else {
            return .primary
        }
    }
}
