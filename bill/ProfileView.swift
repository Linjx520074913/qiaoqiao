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
                    // 用户头像和名称
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)

                        Text(userProfile.name)
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .padding(.top, 20)


                    // 本月预算
                    VStack(spacing: 16) {
                        HStack {
                            Text("本月预算")
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                            Text("¥\(Int(userProfile.monthlyBudget))")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue)
                        }

                        VStack(spacing: 8) {
                            HStack {
                                Text("已使用")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("¥\(Int(userProfile.monthlySpent))")
                                    .font(.system(size: 14, weight: .medium))
                            }

                            ProgressView(value: userProfile.monthlySpent, total: userProfile.monthlyBudget)
                                .tint(.blue)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .gray.opacity(0.1), radius: 10)
                    .padding(.horizontal)

                    // 设置列表
                    VStack(spacing: 0) {
                        SettingRow(icon: "bell.fill", iconColor: .red, title: "记账提醒")
                        Divider().padding(.leading, 60)
                        SettingRow(icon: "icloud.fill", iconColor: .blue, title: "iCloud 同步")
                        Divider().padding(.leading, 60)
                        SettingRow(icon: "gearshape.fill", iconColor: .gray, title: "设置")
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .gray.opacity(0.1), radius: 10)
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}

// 设置行
struct SettingRow: View {
    let icon: String
    let iconColor: Color
    let title: String

    var body: some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 28)

                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding()
        }
    }
}

#Preview {
    ProfileView()
}
