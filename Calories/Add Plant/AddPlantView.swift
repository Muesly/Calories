//
//  AddPlantView.swift
//  Calories
//
//  Created by Tony Short on 19/08/2024.
//

import SwiftData
import SwiftUI

struct AddPlantView: View {
    @Environment(\.dismissSearch) private var dismissSearch
    @Environment(\.dismiss) var dismiss
    @State var viewModel: AddPlantViewModel
    @State var searchText = ""
    @Binding var addedPlant: String
    @State private var isSearching: Bool = true
    @State private var actionSheetShown = false
    @State private var takeAPhotoOption = false
    @State private var chooseFromLibraryOption = false
    @State private var image: UIImage?

    init(viewModel: AddPlantViewModel,
         addedPlant: Binding<String>) {
        self.viewModel = viewModel
        self._addedPlant = addedPlant
    }

    let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    if !searchText.isEmpty {
                        Button {
                            addedPlant = searchText
                            dismiss()
                        } label: {
                            Text("Add \(searchText) as a new plant").bold()
                        }
                    }
                    Section("Common plants") {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(viewModel.suggestions, id: \.name) { suggestion in
                                Button {
                                    addedPlant = suggestion.name
                                    dismiss()
                                } label: {
                                    VStack {
                                        if let uiImage = suggestion.uiImage {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                        } else {
                                            Image(systemName: "photo.badge.plus")
                                        }
                                        Text(suggestion.name)
                                            .frame(height: 20)
                                    }
                                    .frame(width: 80, height: 80)
                                }
                                .onLongPressGesture {
                                    Task {
                                        do {
                                            try await viewModel.fetchImagesForSuggestion(suggestion)
                                        } catch {
                                            print(error)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listRowBackground(Colours.backgroundSecondary)
                }
                .foregroundColor(.white)
                .accessibilityIdentifier("Plant List")
                .navigationTitle("Add Plant")
            }
        }
        .toolbar {
            ToolbarItem {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .font(.brand)
        .onAppear {
            viewModel.fetchSuggestions(searchText: searchText)
        }
        .onChange(of: searchText) { _, searchText in
            viewModel.fetchSuggestions(searchText: searchText)
        }
        .searchable(text: $searchText,
                    isPresented: $isSearching,
                    placement:  .navigationBarDrawer(displayMode: .always),
                    prompt: "Enter Plant")
        .onSubmit(of: .search) {
            addedPlant = searchText
            dismiss()
        }
    }
}

#Preview {
    let modelContext = ModelContext.inMemory
    let _ = [PlantEntry("Corn", imageData: UIImage(named: "Corn")?.jpegData(compressionQuality: 0.9)),
             PlantEntry("Rice", imageData: UIImage(named: "Rice")?.jpegData(compressionQuality: 0.9)),
             PlantEntry("Broccoli", imageData: UIImage(named: "Broccoli")?.jpegData(compressionQuality: 0.9))].forEach { $0.insert(into: modelContext)}
    let viewModel = AddPlantViewModel(modelContext: modelContext,
                                      plantImageGenerator: StubbedPlantGenerator())
    AddPlantView(viewModel: viewModel, addedPlant: .constant(""))
}
