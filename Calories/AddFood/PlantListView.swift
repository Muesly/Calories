//
//  PlantListView.swift
//  Calories
//
//  Created by Tony Short on 11/01/2024.
//

import SwiftUI

struct PlantListView: View {
    var body: some View {
        List {
            Section {
                Text("Lettuce")
                Text("Tomato")
                Text("Red Pepper")
                Text("+")
            } header: {
                Text("List of plants/seeds/herbs in dish")
            }
        }.listStyle(.grouped)
    }
}

struct PlantListView_Previews: PreviewProvider {
    static var previews: some View {
        PlantListView()
    }
}
