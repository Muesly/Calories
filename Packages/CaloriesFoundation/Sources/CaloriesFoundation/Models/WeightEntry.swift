//
//  WeightEntry.swift
//  Calories
//
//  Created by Tony Short on 20/02/2023.
//

import Foundation

public struct WeightEntry {
    public let weight: Int
    public let timeRecorded: Date

    public init(weight: Int, timeRecorded: Date) {
        self.weight = weight
        self.timeRecorded = timeRecorded
    }
}
