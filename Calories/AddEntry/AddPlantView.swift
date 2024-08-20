//
//  AddPlantView.swift
//  Calories
//
//  Created by Tony Short on 19/08/2024.
//

import SwiftUI

struct AddPlantView: View {
    @State var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                if !searchText.isEmpty {
                    Button {
                    } label: {
                        Text("Add \(searchText) as a new plant").bold()
                    }
                }
            }
            .accessibilityIdentifier("Plant List")
            .navigationTitle("Add Plant")
            .searchable(text: $searchText,
                        placement:  .navigationBarDrawer(displayMode: .always),
                        prompt: "Enter name of plant")
        }
    }
}
