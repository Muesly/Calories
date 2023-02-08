//
//  CaloriesViewModel.swift
//  Calories
//
//  Created by Tony Short on 06/02/2023.
//

import CoreData
import Foundation
import HealthKit

protocol FoodEntryType {

}

extension FoodEntry: FoodEntryType {

}

protocol FoodEntryFactoryType {
    func makeFoodEntry(foodDescription: String,
                       calories: Int,
                       timeConsumed: Date) -> FoodEntry
}

struct FoodEntryFactory: FoodEntryFactoryType {
    let context: NSManagedObjectContext

    func makeFoodEntry(foodDescription: String, calories: Int, timeConsumed: Date) -> FoodEntry {
        FoodEntry(context: context, foodDescription: foodDescription, calories: Double(calories), timeConsumed: timeConsumed)
    }
}

@MainActor
class CaloriesViewModel {
    let healthStore: HealthStore
    let container: NSPersistentContainer
    var foodEntries: [FoodEntry] {
        let request = FoodEntry.fetchRequest()
        let sort = NSSortDescriptor(keyPath: \FoodEntry.timeConsumed, ascending: false)
        request.sortDescriptors = [sort]

        do {
          if let entries = try container.viewContext.fetch(request) as? [FoodEntry] {
              return entries
          } else {
              return []
          }
        } catch {
            return []
        }
    }

    init(healthStore: HealthStore = HKHealthStore(),
         container: NSPersistentContainer) {
        self.healthStore = healthStore
        self.container = container
    }

    func totalCaloriesConsumed() async throws -> Double {
        try await healthStore.totalCaloriesConsumed()
    }

    func addFood(foodDescription: String, calories: Int, timeConsumed: Date) async throws {
        let foodEntry = FoodEntry(context: container.viewContext,
                                  foodDescription: foodDescription,
                                  calories: Double(calories),
                                  timeConsumed: timeConsumed)
        try await healthStore.authorize()
        try await healthStore.writeFoodEntry(foodEntry)
        try container.viewContext.save()
    }
}

protocol HealthStore {
    func authorize() async throws
    func totalCaloriesConsumed() async throws -> Double
    func writeFoodEntry(_ foodEntry: FoodEntry) async throws
}

enum HealthStoreError: Error {
    case ErrorNoHealthDataAvailable
}

extension HKHealthStore: HealthStore {
    func authorize() async throws {
        if HKHealthStore.isHealthDataAvailable(),
           let dietaryEnergyConsumed = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed),
           let basalEnergyBurned = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.basalEnergyBurned),
           let activeEnergyBurned = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)
        {
            try await requestAuthorization(toShare: [dietaryEnergyConsumed], read: [dietaryEnergyConsumed, basalEnergyBurned, activeEnergyBurned])
        } else {
            throw HealthStoreError.ErrorNoHealthDataAvailable
        }
    }

    func totalCaloriesConsumed() async throws -> Double {
        guard let caloriesConsumedType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed) else {
            return 0.0
        }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: caloriesConsumedType,
                                          quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { _, result, error in
                guard let result = result,
                      let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0.0)
                    return
                }
                continuation.resume(returning: sum.doubleValue(for: HKUnit.kilocalorie()))
            }
            execute (query)
        }
    }

    func writeFoodEntry(_ foodEntry: FoodEntry) async throws {
        guard let caloriesConsumedType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed) else {
            return
        }
        let quantity = HKQuantity(unit: .largeCalorie(), doubleValue: foodEntry.calories)
        let timeConsumed = foodEntry.timeConsumed ?? Date()
        let caloriesConsumed = HKQuantitySample(type: caloriesConsumedType,
                                                quantity: quantity,
                                                start: timeConsumed,
                                                end: timeConsumed,
                                                metadata: [HKMetadataKeyFoodType: foodEntry.foodDescription])
        try await save(caloriesConsumed)
    }
}

protocol ManagedContext {
    func save() throws
}

extension NSManagedObjectContext: ManagedContext {}
