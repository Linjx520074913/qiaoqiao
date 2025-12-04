//
//  AddTransactionView.swift
//  bill
//
//  Created by linjx on 2025/12/4.
//

import SwiftUI

struct AddTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    var onSave: (Transaction) -> Void

    @State private var merchantName = ""
    @State private var description = ""
    @State private var amount = ""
    @State private var transactionType: TransactionType = .expense
    @State private var selectedCategory: TransactionCategory = .food
    @State private var selectedDate = Date()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 交易类型选择
                    VStack(alignment: .leading, spacing: 12) {
                        Text("交易类型")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        HStack(spacing: 12) {
                            TypeButton(
                                title: "支出",
                                icon: "arrow.down.circle.fill",
                                color: .red,
                                isSelected: transactionType == .expense,
                                action: { transactionType = .expense }
                            )

                            TypeButton(
                                title: "收入",
                                icon: "arrow.up.circle.fill",
                                color: .green,
                                isSelected: transactionType == .income,
                                action: { transactionType = .income }
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    // 金额输入
                    VStack(alignment: .leading, spacing: 12) {
                        Text("金额")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        HStack {
                            Text("¥")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(transactionType == .expense ? .red : .green)

                            TextField("0.00", text: $amount)
                                .font(.system(size: 32, weight: .bold))
                                .keyboardType(.decimalPad)
                                .foregroundColor(transactionType == .expense ? .red : .green)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)

                    // 商户名称
                    VStack(alignment: .leading, spacing: 12) {
                        Text("商户名称")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        TextField("如：星巴克、超市等", text: $merchantName)
                            .font(.system(size: 16))
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)

                    // 备注
                    VStack(alignment: .leading, spacing: 12) {
                        Text("备注")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        TextField("如：早餐、打车等", text: $description)
                            .font(.system(size: 16))
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)

                    // 分类选择
                    VStack(alignment: .leading, spacing: 12) {
                        Text("分类")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(TransactionCategory.allCases, id: \.self) { category in
                                CategoryButton(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // 日期选择
                    VStack(alignment: .leading, spacing: 12) {
                        Text("日期")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)

                    // 保存按钮
                    Button(action: saveTransaction) {
                        Text("保存")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(!isFormValid)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .padding(.top, 20)
            }
            .navigationTitle("添加记录")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }

    private var isFormValid: Bool {
        !merchantName.isEmpty && !amount.isEmpty && Double(amount) != nil
    }

    private func saveTransaction() {
        guard let amountValue = Double(amount) else { return }

        let finalAmount = transactionType == .expense ? -abs(amountValue) : abs(amountValue)

        let transaction = Transaction(
            merchantName: merchantName,
            description: description.isEmpty ? "无备注" : description,
            amount: finalAmount,
            date: selectedDate,
            type: transactionType,
            category: selectedCategory,
            icon: selectedCategory.icon
        )

        onSave(transaction)
        presentationMode.wrappedValue.dismiss()
    }
}

// 类型选择按钮
struct TypeButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : color)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? color : color.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// 分类选择按钮
struct CategoryButton: View {
    let category: TransactionCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? category.color : category.color.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: category.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .white : category.color)
                }

                Text(category.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? category.color : .gray)
            }
        }
    }
}

#Preview {
    AddTransactionView { transaction in
        print("保存: \(transaction)")
    }
}
