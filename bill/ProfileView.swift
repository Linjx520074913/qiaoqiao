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
                        // 姓名
                        ProfileInfoRow(
                            icon: "person.fill",
                            iconColor: .blue,
                            title: userProfile.name,
                            showArrow: false
                        )

                        // 电话
                        ProfileInfoRow(
                            icon: "phone.fill",
                            iconColor: .blue,
                            title: userProfile.phoneNumber,
                            showArrow: false
                        )

                        // 密码
                        ProfileInfoRow(
                            icon: "lock.fill",
                            iconColor: .blue,
                            title: "• • • • • • •",
                            showArrow: false,
                            trailing: {
                                Button(action: {}) {
                                    Image(systemName: "eye.slash.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        )

                        // 语言
                        ProfileInfoRow(
                            icon: "flag.fill",
                            iconColor: .red,
                            title: userProfile.language,
                            showArrow: false,
                            trailing: {
                                Button(action: {}) {
                                    Text("改变")
                                        .font(.system(size: 14))
                                        .foregroundColor(.blue)
                                }
                            }
                        )
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .gray.opacity(0.1), radius: 10)
                    .padding(.horizontal)

                    // 概览卡片
                    VStack(alignment: .leading, spacing: 16) {
                        Text("概览")
                            .font(.system(size: 16, weight: .bold))
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            // 净利润和费用
                            HStack(spacing: 0) {
                                OverviewCard(
                                    icon: "arrow.down.circle.fill",
                                    iconColor: .blue,
                                    title: "净利润",
                                    amount: userProfile.totalProfit
                                )

                                Divider()
                                    .frame(height: 60)

                                OverviewCard(
                                    icon: "arrow.up.circle.fill",
                                    iconColor: .blue,
                                    title: "费用",
                                    amount: userProfile.totalExpense
                                )
                            }
                            .padding()

                            Divider()

                            // 本月预算进度
                            VStack(alignment: .leading, spacing: 12) {
                                Text("度过这个星期")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)

                                HStack {
                                    ProgressView(value: userProfile.monthlySpent, total: userProfile.monthlyBudget)
                                        .tint(.blue)

                                    Text("\(Int(userProfile.monthlySpent))元")
                                        .font(.system(size: 14, weight: .medium))
                                }

                                Text("\(Int(userProfile.monthlySpent)) 元待消费")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .padding()
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .gray.opacity(0.1), radius: 10)
                        .padding(.horizontal)

                        // 邀请卡片
                        InvitationCard()
                            .padding(.horizontal)

                        // 加入信息
                        Text("您于 2021年9月加入 Finpay。自那时起已过去 1 个月，我们的硬命运日，帮助您更好地管理财务。")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("我的账户")
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

// 邀请卡片
struct InvitationCard: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.2.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 4) {
                Text("有任何问题要问Finpay吗？")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Text("我们的客服团队全天候待命，随时为您提供帮助！")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.black)
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
