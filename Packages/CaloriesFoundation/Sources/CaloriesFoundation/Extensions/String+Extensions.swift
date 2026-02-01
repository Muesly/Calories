//
//  String+Extensions.swift
//  Calories
//
//  Created by Tony Short on various dates.
//

import Foundation

public extension String {
    func fuzzyMatch(_ needle: String) -> Bool {
        if needle.isEmpty { return true }
        var remainder = needle.lowercased()[...]
        for char in self.lowercased() {
            if char == remainder[remainder.startIndex] {
                remainder.removeFirst()
                if remainder.isEmpty { return true }
            }
        }
        return false
    }
}
