//
//  RandomPicker.swift
//  Calories
//
//  Created by Tony Short on 15/08/2024.
//

import Foundation

public protocol RandomPickerType {
    func pick(fromNumberOfItems numberOfItems: Int) -> Int
}

public struct RandomPicker: RandomPickerType {
    public init() {}

    public func pick(fromNumberOfItems numberOfItems: Int) -> Int {
        Int.random(in: 0..<numberOfItems)
    }
}
