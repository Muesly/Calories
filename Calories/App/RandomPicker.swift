//
//  RandomPicker.swift
//  Calories
//
//  Created by Tony Short on 15/08/2024.
//

import Foundation

protocol RandomPickerType {
    func pick(fromNumberOfItems numberOfItems: Int) -> Int
}

struct RandomPicker: RandomPickerType {
    func pick(fromNumberOfItems numberOfItems: Int) -> Int {
        Int.random(in: 0..<numberOfItems)
    }
}
