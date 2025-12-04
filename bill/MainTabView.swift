//
//  MainTabView.swift
//  bill
//
//  Created by linjx on 2025/12/3.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

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
            CustomTabBar(selectedTab: $selectedTab)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int

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
                selectedTab = 2
            }) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 64, height: 64)
                        .shadow(color: .blue.opacity(0.3), radius: 10)

                    Image(systemName: "qrcode.viewfinder")
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

#Preview {
    MainTabView()
}
