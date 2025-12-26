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
    @State private var fullScreenPhoto: UIImage? = nil
    @State private var showFullScreenPhoto = false
    @State private var photoZoomScale: CGFloat = 1.0
    @State private var photoOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            let thumbnailWidth = geometry.size.width - 6

            ZStack {
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
                            fullScreenPhoto = photo
                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + 0.1
                            ) {
                                showFullScreenPhoto = true
                            }
                        }) {
                            Label("View Full Size", systemImage: "expand")
                        }
                    }
                } label: {
                    Color.clear
                }
            }
            .frame(height: 200)
        }
        .sheet(isPresented: $showPicker) {
            PHPickerView(image: $photo, isPresented: $showPicker)
        }
        .sheet(isPresented: $showCamera) {
            CameraViewControllerRepresentable { image in
                photo = image
            }
        }
        .fullScreenCover(isPresented: $showFullScreenPhoto) {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button(action: {
                            photoZoomScale = 1.0
                            photoOffset = .zero
                            showFullScreenPhoto = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding()
                        }
                    }

                    Spacer()

                    if let photo = fullScreenPhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(photoZoomScale)
                            .offset(photoOffset)
                            .gesture(
                                SimultaneousGesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            photoZoomScale = max(1.0, value)
                                        },
                                    DragGesture()
                                        .onChanged { value in
                                            photoOffset = value.translation
                                        }
                                )
                            )
                            .onTapGesture(count: 2) {
                                withAnimation {
                                    if photoZoomScale > 1.5 {
                                        photoZoomScale = 1.0
                                        photoOffset = .zero
                                    } else {
                                        photoZoomScale = 2.5
                                    }
                                }
                            }
                            .padding()
                    }

                    Spacer()
                }
            }
            .onChange(of: showFullScreenPhoto) { oldValue, newValue in
                if !newValue {
                    photoZoomScale = 1.0
                    photoOffset = .zero
                }
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

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

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
            DispatchQueue.main.async {
                self.isPresented = false
            }

            guard let provider = results.first?.itemProvider else { return }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                    guard let uiImage = image as? UIImage else { return }
                    Task { @MainActor in
                        self?.image = uiImage
                    }
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
