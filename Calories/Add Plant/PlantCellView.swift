//
//  PlantCellView.swift
//  Calories
//
//  Created by Tony Short on 01/09/2024.
//

import Foundation
import SwiftUI

struct PlantCellView: View {
    let viewModel: PlantCellViewModel
    @State var isGeneratingImage: Bool = false
    private static let imageSize = CGSize(width: 130, height: 110)
    @Binding var addedPlant: String

    init(viewModel: PlantCellViewModel,
         addedPlant: Binding<String>) {
        self.viewModel = viewModel
        self._addedPlant = addedPlant
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if isGeneratingImage {
                    ProgressView()
                        .frame(width: PlantCellView.imageSize.width, height: PlantCellView.imageSize.height)
                } else {
                    if let uiImage = viewModel.uiImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .frame(width: PlantCellView.imageSize.width, height: PlantCellView.imageSize.height)
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                    } else {
                        VStack{
                            Spacer()
                            Image(systemName: "photo.badge.plus")
                            Spacer()
                        }.frame(width: PlantCellView.imageSize.width, height: PlantCellView.imageSize.height)
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
                    }.frame(width: PlantCellView.imageSize.width, height: PlantCellView.imageSize.height)
                }
            }
            .onTapGesture {     // Using a button exhibited strange behaviour
                addedPlant = viewModel.plant
            }
            ZStack {
                Text(viewModel.plant)
                    .font(Font.custom("Avenir Next", size: 13))
                    .lineLimit(1)
                    .padding(.horizontal, 5)
                HStack {
                    Spacer()
                    Image(systemName: "arrow.trianglehead.clockwise.rotate.90")
                        .resizable()
                        .frame(width: 12, height: 12)
                        .padding(2)
                        .onTapGesture {
                            Task {
                                do {
                                    isGeneratingImage = true
                                    try await viewModel.fetchImagesForSuggestion()
                                    isGeneratingImage = false
                                } catch {
                                    print(error)
                                }
                            }
                        }
                }
            }
            .frame(height: 30)
            .background(Color.backgroundSecondary)
            .foregroundColor(Color.foregroundPrimary)
            .frame(maxWidth: .infinity)
        }
    }
}
