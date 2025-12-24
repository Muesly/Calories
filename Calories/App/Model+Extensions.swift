//
//  Model+Extensions.swift
//  Calories
//
//  Created by Tony Short on 01/06/2025.
//

import UIKit

extension IngredientEntry {
    convenience init(_ name: String, imageName: String, isPlant: Bool = true) {
        self.init(
            name,
            imageData: UIImage(named: imageName)?.jpegData(compressionQuality: 0.9),
            isPlant: isPlant)
    }

    var uiImage: UIImage? {
        guard let imageData,
            let uiImage = UIImage(data: imageData)
        else {
            return nil
        }
        return uiImage
    }
}
