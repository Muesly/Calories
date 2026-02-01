//
//  CategoryEntry.swift
//  Calories
//
//  Created by Claude Code on 29/12/2025.
//

import Foundation
import SwiftData

@Model public class CategoryEntry {
    @Attribute(.unique) var name: String
    @Relationship(inverse: \RecipeEntry.categories) public var recipes: [RecipeEntry]?

    public init(name: String) {
        self.name = name
    }
}

extension CategoryEntry: Equatable {
    public static func == (lhs: CategoryEntry, rhs: CategoryEntry) -> Bool {
        lhs.name == rhs.name
    }

    static var byName: SortDescriptor<CategoryEntry> {
        SortDescriptor(\.name, order: .forward)
    }

    @discardableResult
    func insert(into modelContext: ModelContext) -> CategoryEntry {
        modelContext.insert(self)
        return self
    }
}
