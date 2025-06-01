//
//  Model+Extensions.swift
//  Calories
//
//  Created by Tony Short on 01/06/2025.
//

import UIKit

extension PlantEntry {
    convenience init(_ name: String, timeConsumed: Date = Date(), imageName: String) {
        self.init(name, timeConsumed: timeConsumed, imageData: UIImage(named: imageName)?.jpegData(compressionQuality: 0.9))
    }

    var uiImage: UIImage? {
        guard let imageData,
              let uiImage = UIImage(data: imageData) else {
            return nil
        }
        return uiImage
    }
}
