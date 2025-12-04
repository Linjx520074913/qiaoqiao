//
//  ProfileView.swift
//  bill
//
//  Created by linjx on 2025/12/3.
//

import SwiftUI

struct ProfileView: View {
    @State private var userProfile = UserProfile()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 顶部蓝色背景
                    ZStack(alignment: .top) {
                        // 蓝色背景
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.blue)
                            .frame(height: 120)
                            .padding(.horizontal)

                        VStack(spacing: 16) {
                            // 头像
                            ZStack(alignment: .bottomTrailing) {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray.opacity(0.3))
                                    .background(Color.white)
                                    .clipShape(Circle())

                                // 相机图标
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                    )
                            }
                            .padding(.top, 20)
                        }
                    }

                    // 用户信息卡片
                    VStack(spacing: 20) {
                        // 用户名
                        ProfileInfoRow(
                            icon: "person.fill",
                            iconColor: .blue,
                            title: userProfile.name,
                            showArrow: false,
                            trailing: {
                                Button(action: {}) {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.blue)
                                }
                            }
                        )

                        // 账本类型
                        ProfileInfoRow(
                            icon: "book.fill",
                            iconColor: .orange,
                            title: "个人账本",
                            showArrow: true
                        )

                        // 记账提醒
                        ProfileInfoRow(
                            icon: "bell.fill",
                            iconColor: .red,
                            title: "每日记账提醒",
                            showArrow: true
                        )

                        // 数据备份
                        ProfileInfoRow(
                            icon: "icloud.fill",
                            iconColor: .cyan,
                            title: "iCloud 同步",
                            showArrow: true
                        )
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .gray.opacity(0.1), radius: 10)
                    .padding(.horizontal)

                    // 财务概览卡片
                    VStack(alignment: .leading, spacing: 16) {
                        Text("财务概览")
                            .font(.system(size: 16, weight: .bold))
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            // 总收入和总支出
                            HStack(spacing: 0) {
                                OverviewCard(
                                    icon: "arrow.down.circle.fill",
                                    iconColor: .green,
                                    title: "总收入",
                                    amount: userProfile.totalIncome
                                )

                                Divider()
                                    .frame(height: 60)

                                OverviewCard(
                                    icon: "arrow.up.circle.fill",
                                    iconColor: .red,
                                    title: "总支出",
                                    amount: userProfile.totalExpense
                                )
                            }
                            .padding()

                            Divider()

                            // 本月预算进度
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("本月预算")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("已用 \(Int(userProfile.monthlySpent / userProfile.monthlyBudget * 100))%")
                                        .font(.system(size: 12))
                                        .foregroundColor(.orange)
                                }

                                HStack {
                                    ProgressView(value: userProfile.monthlySpent, total: userProfile.monthlyBudget)
                                        .tint(.blue)

                                    Text("¥\(Int(userProfile.monthlySpent))")
                                        .font(.system(size: 14, weight: .medium))
                                }

                                HStack {
                                    Text("预算: ¥\(Int(userProfile.monthlyBudget))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("剩余: ¥\(Int(userProfile.monthlyBudget - userProfile.monthlySpent))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                }
                            }
                            .padding()
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .gray.opacity(0.1), radius: 10)
                        .padding(.horizontal)

                        // 自动记账功能卡片
                        AutoRecordCard()
                            .padding(.horizontal)

                        // 使用说明
                        Text("自动记账功能可以智能识别您的支付记录，自动分类并记录到账本中，让记账变得轻松便捷。")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("我的账本")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.primary)
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}

// 个人信息行
struct ProfileInfoRow<Trailing: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let showArrow: Bool
    let trailing: (() -> Trailing)?

    init(icon: String,
         iconColor: Color,
         title: String,
         showArrow: Bool = true,
         @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.showArrow = showArrow
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)

            Spacer()

            if let trailing = trailing {
                trailing()
            }

            if showArrow {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
    }
}

// 概览卡片
struct OverviewCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let amount: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                Text("\(Int(amount)) 元")
                    .font(.system(size: 20, weight: .bold))
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// 自动记账功能卡片
struct AutoRecordCard: View {
    @State private var isAutoRecordEnabled = true

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 4) {
                Text("智能自动记账")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Text("自动识别支付记录，智能分类记账")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
            }

            Spacer()

            Toggle("", isOn: $isAutoRecordEnabled)
                .labelsHidden()
                .tint(.green)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
    }
}

// 保存按钮视图
struct SaveButton: View {
    var body: some View {
        Button(action: {}) {
            Text("保存更改")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(16)
        }
        .padding(.horizontal)
    }
}

#Preview {
    ProfileView()
}
