//
//  PhotoView.swift
//  Recipes
//
//  Created by Tony Short on 06/04/2023.
//

import SwiftUI

struct PhotoView: View {
    @Environment(\.dismiss) var dismiss
    @State var scale: CGFloat = 1
    @State var scaleAnchor: UnitPoint = .center
    @State var lastScale: CGFloat = 1
    @State var offset: CGSize = .zero
    @State var lastOffset: CGSize = .zero
    let image: UIImage

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                let magnificationGesture = MagnificationGesture()
                    .onChanged { gesture in
                        scaleAnchor = .center
                        scale = max(1, lastScale * gesture)
                    }
                    .onEnded { _ in
                        fixOffsetAndScale(geometry: geometry)
                    }

                let dragGesture = DragGesture()
                    .onChanged { gesture in
                        var newOffset = lastOffset
                        newOffset.width += gesture.translation.width
                        newOffset.height += gesture.translation.height
                        offset = newOffset
                    }
                    .onEnded { _ in
                        fixOffsetAndScale(geometry: geometry)
                    }

                let doubleTapGesture = TapGesture(count: 2).onEnded {
                    withAnimation(.easeIn) {
                        let min = 1.0
                        let max = 2.0
                        if scale <= min {
                            scale = max
                        } else if scale >= max {
                            scale = min
                        } else {
                            scale = ((max - min) * 0.5 + min) < scale ? max : min
                        }
                    }
                }

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )
                    .scaleEffect(scale, anchor: scaleAnchor)
                    .offset(offset)
                    .gesture(dragGesture)
                    .gesture(doubleTapGesture)
                    .gesture(magnificationGesture)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
    }

    private func fixOffsetAndScale(geometry: GeometryProxy) {
        let newScale: CGFloat = .minimum(.maximum(scale, 1), 4)
        let screenSize = geometry.size

        let originalScale =
            image.size.width / image.size.height >= screenSize.width / screenSize.height
            ? geometry.size.width / image.size.width : geometry.size.height / image.size.height

        let imageWidth = (image.size.width * originalScale) * newScale

        var width: CGFloat = .zero
        if imageWidth > screenSize.width {
            let widthLimit: CGFloat =
                imageWidth > screenSize.width
                ? (imageWidth - screenSize.width) / 2
                : 0

            width =
                offset.width > 0
                ? .minimum(widthLimit, offset.width) : .maximum(-widthLimit, offset.width)
        }

        let imageHeight = (image.size.height * originalScale) * newScale
        var height: CGFloat = .zero
        if imageHeight > screenSize.height {
            let heightLimit: CGFloat =
                imageHeight > screenSize.height
                ? (imageHeight - screenSize.height) / 2
                : 0

            height =
                offset.height > 0
                ? .minimum(heightLimit, offset.height) : .maximum(-heightLimit, offset.height)
        }

        let newOffset = CGSize(width: width, height: height)
        lastScale = newScale
        lastOffset = newOffset
        withAnimation() {
            offset = newOffset
            scale = newScale
        }
    }
}
