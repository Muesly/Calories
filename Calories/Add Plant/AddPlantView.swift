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

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    if !searchText.isEmpty {
                        Button {
                            addedPlant = searchText
                        } label: {
                            Text("Add \(searchText) as a new plant").bold()
                        }
                    }
                    Section("Common plants") {
                        PlantGridView(plantSelections: viewModel.suggestions,
                                      addedPlant: $addedPlant)
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
        }
        .onChange(of: addedPlant) {
            if !addedPlant.isEmpty {
                dismiss()
            }
        }
    }
}

#Preview {
    let modelContext = ModelContext.inMemory
    let _ = [PlantEntry("Corn", imageData: UIImage(named: "Corn")?.jpegData(compressionQuality: 0.9)),
             PlantEntry("Rice", imageData: UIImage(named: "Rice")?.jpegData(compressionQuality: 0.9)),
             PlantEntry("Broccoli", imageData: UIImage(named: "Broccoli")?.jpegData(compressionQuality: 0.9)),
             PlantEntry("Unidentified"),
             PlantEntry("Corn 2", imageData: UIImage(named: "Corn")?.jpegData(compressionQuality: 0.9))].forEach { $0.insert(into: modelContext)}
    let viewModel = AddPlantViewModel(suggestionFetcher: SuggestionFetcher(modelContext: modelContext, excludedSuggestions: ["Corn 2"]))
    AddPlantView(viewModel: viewModel, addedPlant: .constant(""))
}
