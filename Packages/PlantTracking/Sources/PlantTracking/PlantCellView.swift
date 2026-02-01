//
//  PlantCellView.swift
//  Calories
//
//  Created by Tony Short on 01/09/2024.
//

import CaloriesFoundation
import Foundation
import SwiftUI

struct PlantCellView: View {
    let viewModel: PlantCellViewModel
    @State var isGeneratingImage: Bool = false
    private static let width = 100.0
    private static let imageSize = CGSize(width: width, height: 85)
    @Binding var addedPlant: String

    init(
        viewModel: PlantCellViewModel,
        addedPlant: Binding<String>
    ) {
        self.viewModel = viewModel
        self._addedPlant = addedPlant
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if isGeneratingImage {
                    ProgressView()
                        .frame(
                            width: PlantCellView.imageSize.width,
                            height: PlantCellView.imageSize.height)
                } else {
                    if let uiImage = viewModel.uiImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .frame(
                                width: PlantCellView.imageSize.width,
                                height: PlantCellView.imageSize.height
                            )
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                    } else {
                        VStack {
                            Spacer()
                            Image(systemName: "photo.badge.plus")
                            Spacer()
                        }.frame(
                            width: PlantCellView.imageSize.width,
                            height: PlantCellView.imageSize.height
                        )
                        .background(Colours.backgroundSecondary).opacity(0.5)
                    }
                }
                if viewModel.isSelected {
                    VStack {
                        HStack(alignment: .top) {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .padding(2)
                        }
                        Spacer()
                    }.frame(
                        width: PlantCellView.imageSize.width, height: PlantCellView.imageSize.height
                    )
                }
            }
            .onTapGesture {  // Using a button exhibited strange behaviour
                addedPlant = viewModel.plant
            }
            ZStack {
                Text(viewModel.plant)
                    .font(Font.custom("Avenir Next", size: 11))
                    .lineLimit(1)
                HStack {
                    Spacer()
                    Image(systemName: "arrow.trianglehead.clockwise.rotate.90")
                        .resizable()
                        .frame(width: 12, height: 12)
                        .padding(5)
                        .onTapGesture {
                            Task {
                                do {
                                    isGeneratingImage = true
                                    try await viewModel.fetchImagesForSuggestion()
                                } catch {
                                    print(error)
                                }
                                isGeneratingImage = false
                            }
                        }
                }
            }
            .frame(width: Self.width, height: 25)
            .background(Colours.backgroundSecondary)
            .foregroundColor(Colours.foregroundPrimary)
        }
        .cornerRadius(5)
    }
}
