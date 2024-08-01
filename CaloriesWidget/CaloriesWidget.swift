//
//  CaloriesWidget.swift
//  CaloriesWidget
//
//  Created by Tony Short on 19/02/2023.
//

import HealthKit
import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
    let healthStore: HealthStore

    init(healthStore: HealthStore) {
        self.healthStore = healthStore
    }

    func placeholder(in context: Context) -> CanEatEntry {
        CanEatEntry(date: Date(), calories: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (CanEatEntry) -> ()) {
        let entry = CanEatEntry(date: Date(), calories: 100)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        var entries: [CanEatEntry] = []
        let entryDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        fetchCanEatCalories { canEat in
            let entry = CanEatEntry(date: entryDate, calories: canEat)
            entries.append(entry)
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }

    func fetchCanEatCalories(completion: @escaping ((Int) -> Void)) {
        let date = Date()
        Task {
            do {
                let bmr = try await healthStore.bmr(date: date)
                let exercise = try await healthStore.exercise(date: date)
                let caloriesConsumed = try await healthStore.caloriesConsumed(date: date)
                let difference = -(caloriesConsumed - (bmr + exercise))
                completion(difference)
            } catch {
                completion(0)
            }
        }
    }
}

struct CanEatEntry: TimelineEntry {
    var date: Date
    let calories: Int
}

struct CaloriesWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        Text("\(entry.calories)")
    }
}

@main
struct CaloriesWidget: Widget {
    let kind: String = "CaloriesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CaloriesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Can Eat")
        .description("View how many calories you can eat and still be in deficit according to your goal.")
    }
}
