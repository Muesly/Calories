//
//  PlantCell.swift
//  Calories
//
//  Created by Tony Short on 01/09/2024.
//

import Foundation
import SwiftUI

struct PlantCell: View {
    let added: (() -> Void)
    let viewModel: PlantCellViewModel
    @State var isGeneratingImage: Bool = false

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
                if isGeneratingImage {
                    ProgressView()
                        .frame(width: 100, height: 80)
                } else {
                    if let uiImage = viewModel.uiImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .frame(width: 100, height: 80)
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                    } else {
                        VStack{
                            Spacer()
                            Image(systemName: "photo.badge.plus")
                            Spacer()
                        }.frame(width: 100, height: 80)
                    }
                }
                ZStack {
                    Text(viewModel.plant)
                        .font(Font.custom("Avenir Next", size: 13))
                        .lineLimit(1)
                        .padding(.horizontal, 5)
                        .frame(maxWidth: .infinity)
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
            }
            .background(Color.backgroundSecondary)
            .foregroundColor(Color.foregroundPrimary)
            .frame(maxWidth: .infinity)
        }
    }
}
