//
//  RatingView.swift
//  Recipes
//
//  Created by Tony Short on 08/04/2023.
//

import SwiftUI

struct RatingView: View {
    @Binding private var rating: Int16

    init(rating: Binding<Int16>) {
        self._rating = rating
    }

    var body: some View {
        HStack {
            Text("Rating")
            VStack {
                Button {
                    rating = 4
                } label: {
                    HStack {
                        Image(systemName: "star.fill")
                        Image(systemName: "star.fill")
                        Image(systemName: "star.fill")
                        Image(systemName: "star.fill")
                        Image(systemName: "star")
                    }
                }
                .foregroundColor(rating == 4 ? .accentColor : .gray.opacity(0.5))
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 10))
                Button {
                    rating = 5
                } label: {
                    HStack {
                        Image(systemName: "star.fill")
                        Image(systemName: "star.fill")
                        Image(systemName: "star.fill")
                        Image(systemName: "star.fill")
                        Image(systemName: "star.fill")
                    }
                }
                .foregroundColor(rating == 5 ? .accentColor : .gray.opacity(0.5))
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 10))
            }
        }
    }
}
