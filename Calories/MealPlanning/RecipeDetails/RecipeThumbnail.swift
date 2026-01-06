//
//  RecipeThumbnail.swift
//  Calories
//
//  Created by Tony Short on 26/12/2025.
//

import PhotosUI
import SwiftUI

struct RecipeThumbnail: View {
    let label: String
    @Binding var photo: UIImage?
    @State private var showPicker = false
    @State private var showCamera = false
    @State private var showFullScreenPhoto = false

    var body: some View {
        thumbnailContent
            .sheet(isPresented: $showCamera) {
                CameraViewControllerRepresentable { image in
                    photo = image
                }
            }
            .sheet(isPresented: $showPicker) {
                PHPickerView(image: $photo, isPresented: $showPicker)
            }
    }

    private var thumbnailContent: some View {
        GeometryReader { geometry in
            let thumbnailWidth = geometry.size.width - 6

            ZStack(alignment: .topLeading) {
                if let photo {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: thumbnailWidth, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Colours.backgroundSecondary)
                        VStack(spacing: 12) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 40))
                                .foregroundColor(
                                    Colours.foregroundPrimary.opacity(0.5))
                            Text("Click to add\n\(label)")
                                .font(.caption)
                                .foregroundColor(
                                    Colours.foregroundPrimary.opacity(0.6)
                                )
                                .multilineTextAlignment(.center)
                        }
                    }
                }

                Menu {
                    Button(action: {
                        showCamera = true
                    }) {
                        Label("Camera", systemImage: "camera.fill")
                    }

                    Button(action: {
                        showPicker = true
                    }) {
                        Label("Photo Library", systemImage: "photo.fill")
                    }

                    if photo != nil {
                        Divider()
                        Button(action: {
                            showFullScreenPhoto = true
                        }) {
                            Label(
                                "View Full Size", systemImage: "arrow.up.left.and.arrow.down.right")
                        }
                    }
                } label: {
                    Color.clear
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(height: 200)
        .fullScreenCover(isPresented: $showFullScreenPhoto) {
            if let photo {
                PhotoView(image: photo)
            }
        }
    }
}

// MARK: - Photo Picker View

struct PHPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // Update if needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(image: $image, isPresented: $isPresented)
    }

    @MainActor class Coordinator: NSObject, PHPickerViewControllerDelegate {
        @Binding var image: UIImage?
        @Binding var isPresented: Bool

        init(image: Binding<UIImage?>, isPresented: Binding<Bool>) {
            _image = image
            _isPresented = isPresented
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider else {
                DispatchQueue.main.async {
                    self.isPresented = false
                }
                return
            }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                    guard let uiImage = image as? UIImage else {
                        Task { @MainActor in
                            self?.isPresented = false
                        }
                        return
                    }
                    Task { @MainActor in
                        self?.image = uiImage
                        self?.isPresented = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isPresented = false
                }
            }
        }
    }
}

// MARK: - Camera View Controller

struct CameraViewControllerRepresentable: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    let onImageCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCapture: onImageCapture, dismiss: dismiss)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageCapture: (UIImage) -> Void
        let dismiss: DismissAction

        init(onImageCapture: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onImageCapture = onImageCapture
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImageCapture(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
