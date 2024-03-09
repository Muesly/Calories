//
//  PlantPickerView.swift
//  Calories
//
//  Created by Tony Short on 14/01/2024.
//

import SwiftUI

struct PlantPickerView: View {
    @Environment(\.dismissSearch) private var dismissSearch
    @State var searchText = ""
    @State private var readyToNavigateToAddEntryInputFields : Bool = false
    @State var plantAdded = false

    var body: some View {
        List {
            if !searchText.isEmpty {
                NavigationLink {
                    AddPlantView(viewModel: AddPlantEntryViewModel(),
                                 defName: searchText,
                                 searchText: $searchText,
                                 plantAdded: $plantAdded)
                } label: {
                    Text("Add \(searchText) as a new plant").bold()
                }
            }
            Text("Banana")
            Text("Apple")
        }
        .navigationTitle("Pick plant")
            .searchable(text: $searchText,
                         placement:  .navigationBarDrawer(displayMode: .always),
                         prompt: "Enter plant, seed or herb...")
            .onSubmit(of: .search) {
                dismissSearch()
                readyToNavigateToAddEntryInputFields = true
            }
    }
}

struct PlantPickerView_Previews: PreviewProvider {
    static var previews: some View {
        PlantPickerView()
    }
}
