//
//  RecipeSourceView.swift
//  Calories
//
//  Created by Tony Short on 26/12/2025.
//

import PhotosUI
import SwiftUI

struct RecipeSourceView: View {
    @Binding var currentPage: AddRecipePage
    @Binding var extractedRecipeNames: [String]
    @Binding var dishPhoto: UIImage?
    @Binding var stepsPhoto: UIImage?

    @State private var showDishPicker = false
    @State private var showStepsPicker = false
    @State private var showDishCamera = false
    @State private var showStepsCamera = false
    @State private var fullScreenPhoto: UIImage? = nil
    @State private var showFullScreenPhoto = false
    @State private var showGenerateAlert = false
    @State private var isScanning = false

    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(spacing: 24) {
                    // Recipe Book Section
                    VStack(spacing: 16) {
                        Text("Recipe Book")
                            .font(.headline)
                            .foregroundColor(Colours.foregroundPrimary)

                        GeometryReader { geometry in
                            let thumbnailWidth = (geometry.size.width - 12) / 2

                            HStack(spacing: 12) {
                                // Dish Photo Thumbnail
                                ZStack {
                                    if let dishPhoto {
                                        Image(uiImage: dishPhoto)
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
                                                Text("Click to add\nDish photo")
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
                                            showDishCamera = true
                                        }) {
                                            Label("Camera", systemImage: "camera.fill")
                                        }

                                        Button(action: {
                                            showDishPicker = true
                                        }) {
                                            Label("Photo Library", systemImage: "photo.fill")
                                        }

                                        if dishPhoto != nil {
                                            Divider()
                                            Button(action: {
                                                fullScreenPhoto = dishPhoto
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
                                .frame(width: thumbnailWidth, height: 200)

                                // Steps Photo Thumbnail
                                ZStack {
                                    if let stepsPhoto {
                                        Image(uiImage: stepsPhoto)
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
                                                Text("Click to add\nSteps photo")
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
                                            showStepsCamera = true
                                        }) {
                                            Label("Camera", systemImage: "camera.fill")
                                        }

                                        Button(action: {
                                            showStepsPicker = true
                                        }) {
                                            Label("Photo Library", systemImage: "photo.fill")
                                        }

                                        if stepsPhoto != nil {
                                            Divider()
                                            Button(action: {
                                                fullScreenPhoto = stepsPhoto
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
                                .frame(width: thumbnailWidth, height: 200)
                            }
                        }
                        .frame(height: 200)

                        // Scan recipe button
                        Button(action: {
                            scanRecipe()
                        }) {
                            if isScanning {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .tint(Colours.foregroundPrimary)
                                    Text("Scanning...")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Colours.backgroundSecondary)
                                .foregroundColor(Colours.foregroundPrimary)
                                .cornerRadius(8)
                            } else {
                                Text("Scan recipe")
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(Colours.backgroundSecondary)
                                    .foregroundColor(Colours.foregroundPrimary)
                                    .cornerRadius(8)
                            }
                        }
                        .disabled(stepsPhoto == nil || isScanning)
                        .opacity(stepsPhoto == nil ? 0.5 : 1.0)
                    }
                    .padding(.horizontal)

                    // Divider with "or" label
                    HStack(spacing: 12) {
                        Divider()
                            .background(Colours.foregroundPrimary.opacity(0.3))
                        Text("or")
                            .font(.caption)
                            .foregroundColor(Colours.foregroundPrimary.opacity(0.6))
                        Divider()
                            .background(Colours.foregroundPrimary.opacity(0.3))
                    }
                    .padding(.horizontal)

                    // AI Generated Section
                    VStack(spacing: 16) {
                        Text("AI Generated")
                            .font(.headline)
                            .foregroundColor(Colours.foregroundPrimary)

                        Button(action: {
                            showGenerateAlert = true
                        }) {
                            Text("Generate Recipe")
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Colours.backgroundSecondary)
                                .foregroundColor(Colours.foregroundPrimary)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Choose Recipe Source")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showDishPicker) {
            PHPickerView(image: $dishPhoto, isPresented: $showDishPicker)
        }
        .sheet(isPresented: $showStepsPicker) {
            PHPickerView(image: $stepsPhoto, isPresented: $showStepsPicker)
        }
        .sheet(isPresented: $showDishCamera) {
            CameraViewControllerRepresentable { image in
                dishPhoto = image
            }
        }
        .sheet(isPresented: $showStepsCamera) {
            CameraViewControllerRepresentable { image in
                stepsPhoto = image
            }
        }
        .sheet(isPresented: $showFullScreenPhoto) {
            if let fullScreenPhoto {
                PhotoView(image: fullScreenPhoto)
            }
        }
        .alert("Generate Recipe", isPresented: $showGenerateAlert) {
            Button("OK") {}
        } message: {
            Text("Will generate recipe")
        }
    }

    private func scanRecipe() {
        guard let photo = stepsPhoto else { return }

        Task {
            await MainActor.run {
                isScanning = true
            }

            let recipeNames = await RecipeTextExtractor.extractRecipeData(
                from: photo)

            if !recipeNames.isEmpty {
                try? await Task.sleep(nanoseconds: 300_000_000)

                await MainActor.run {
                    extractedRecipeNames = recipeNames
                    isScanning = false
                    currentPage = .details
                }
            } else {
                await MainActor.run {
                    isScanning = false
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
