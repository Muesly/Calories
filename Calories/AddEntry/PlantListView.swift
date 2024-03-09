//
//  PlantListView.swift
//  Calories
//
//  Created by Tony Short on 11/01/2024.
//

import SwiftUI

struct PlantListView: View {
    let viewModel: PlantListViewModel

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Plants")
                Spacer()
            }
            Grid() {
                GridRow {
                    NavigationLink("+") {
                        PlantPickerView()
                    }
                }
            }
        }
    }
}

struct PlantListView_Previews: PreviewProvider {
    static var previews: some View {
        PlantListView(viewModel: PlantListViewModel())
    }
}

class PlantListViewModel {

}
