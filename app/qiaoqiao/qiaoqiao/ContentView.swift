//
//  ContentView.swift
//  qiaoqiao
//
//  主页面 - 图片选择和扫描
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var apiService = APIService.shared
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var isScanning = false
    @State private var scanResult: ScanResult?
    @State private var showResult = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var serverStatus: String = "检查中..."
    @State private var skipItems = false
    @State private var useFastMode = false
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 服务器状态
                    Text(serverStatus)
                        .font(.caption)
                        .foregroundColor(serverStatus.contains("✓") ? .green : .red)
                        .padding(.top)

                    // 图片预览
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                            .padding()
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 300)
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    Text("未选择图片")
                                        .foregroundColor(.secondary)
                                }
                            )
                            .padding()
                    }

                    // 选项开关
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("快速模式", isOn: $useFastMode)
                        Toggle("跳过商品明细", isOn: $skipItems)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // 按钮组
                    HStack(spacing: 12) {
                        // 选择图片
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Label("选择图片", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        // 拍照
                        Button {
                            showCamera = true
                        } label: {
                            Label("拍照", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)

                    // 开始识别按钮
                    Button {
                        Task {
                            await scanImage()
                        }
                    } label: {
                        if isScanning {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.6))
                                .cornerRadius(10)
                        } else {
                            Text("开始识别")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedImage == nil ? Color.gray : Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .disabled(selectedImage == nil || isScanning)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("KAPI - 智能账单识别")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showResult) {
                if let result = scanResult, let image = selectedImage {
                    ResultView(scanResult: result, image: image)
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "未知错误")
            }
            .onChange(of: selectedItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
            .task {
                await checkHealth()
            }
        }
    }

    // MARK: - 健康检查
    private func checkHealth() async {
        do {
            _ = try await apiService.healthCheck()
            serverStatus = "✓ 服务器连接成功"
        } catch {
            serverStatus = "✗ 服务器连接失败"
        }
    }

    // MARK: - 扫描图片
    private func scanImage() async {
        guard let image = selectedImage else { return }

        isScanning = true
        defer { isScanning = false }

        do {
            let result = try await apiService.scanBill(
                image: image,
                skipItems: skipItems,
                useFastMode: useFastMode
            )

            if result.success {
                scanResult = result
                showResult = true
            } else {
                errorMessage = result.error ?? "识别失败"
                showError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - 相机选择器
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ContentView()
}
