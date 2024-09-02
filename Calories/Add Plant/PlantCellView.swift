//
//  PlantCellView.swift
//  Calories
//
//  Created by Tony Short on 01/09/2024.
//

import Foundation
import SwiftUI

struct PlantCellView: View {
    let added: (() -> Void)
    let viewModel: PlantCellViewModel
    @State var isGeneratingImage: Bool = false
    private static let imageSize = CGSize(width: 130, height: 110)
    init(viewModel: PlantCellViewModel,
         added: @escaping () -> Void) {
        self.viewModel = viewModel
        self.added = added
    }

    var body: some View {
        Button {
            added()
        } label: {
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
                ZStack {
                    Text(viewModel.plant)
                        .font(Font.custom("Avenir Next", size: 13))
                        .lineLimit(1)
                        .padding(.horizontal, 5)
                    HStack {
                        Spacer()
                        Button {
                            Task {
                                do {
                                    isGeneratingImage = true
                                    try await viewModel.fetchImagesForSuggestion()
                                    isGeneratingImage = false
                                } catch {
                                    print(error)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.trianglehead.clockwise.rotate.90")
                                .resizable()
                                .frame(width: 12, height: 12)
                                .padding(2)
                        }
                    }
                }
                .frame(height: 30)
            }
            .background(Color.backgroundSecondary)
            .foregroundColor(Color.foregroundPrimary)
            .frame(maxWidth: .infinity)
        }
    }
}
