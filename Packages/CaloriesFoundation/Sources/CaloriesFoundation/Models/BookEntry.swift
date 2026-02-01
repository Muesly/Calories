//
//  BookEntry.swift
//  Calories
//
//  Created by Tony Short on 29/12/2025.
//

import Foundation
import SwiftData

@Model public class BookEntry {
    @Attribute(.unique) public var name: String

    public init(name: String) {
        self.name = name
    }
}

extension BookEntry: Equatable {
    public static func == (lhs: BookEntry, rhs: BookEntry) -> Bool {
        lhs.name == rhs.name
    }

    static var byName: SortDescriptor<BookEntry> {
        SortDescriptor(\.name, order: .forward)
    }

    @discardableResult
    func insert(into modelContext: ModelContext) -> BookEntry {
        modelContext.insert(self)
        return self
    }
}
