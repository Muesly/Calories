//
//  HealthStore.swift
//  Calories
//
//  Created by Tony Short on 08/02/2023.
//

import Foundation
import HealthKit

protocol HealthStore {
    func authorize() async throws
    func caloriesConsumed() async throws -> Int
    func bmr() async throws -> Int
    func exercise() async throws -> Int
    func addFoodEntry(_ foodEntry: FoodEntry) async throws
    func deleteFoodEntry(_ foodEntry: FoodEntry) async throws
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

    private func countForType(_ typeIdentifier: HKQuantityTypeIdentifier) async throws -> Int {
        guard let type = HKObjectType.quantityType(forIdentifier: typeIdentifier) else {
            return 0
        }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type,
                                          quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { _, result, error in
                guard let result = result,
                      let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                continuation.resume(returning: Int(sum.doubleValue(for: HKUnit.kilocalorie())))
            }
            execute (query)
        }
    }

    func bmr() async throws -> Int {
        try await countForType(.basalEnergyBurned)
    }

    func exercise() async throws -> Int {
        try await countForType(.activeEnergyBurned)
    }

    func caloriesConsumed() async throws -> Int {
        try await countForType(.dietaryEnergyConsumed)
    }

    func addFoodEntry(_ foodEntry: FoodEntry) async throws {
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

    func deleteFoodEntry(_ foodEntry: FoodEntry) async throws {
        guard let caloriesConsumedType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed),
            let timeConsumed = foodEntry.timeConsumed else {
            return
        }

        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: timeConsumed, end: timeConsumed.addingTimeInterval(1))
            let query = HKSampleQuery.init(sampleType: caloriesConsumedType,
                                           predicate: predicate,
                                           limit: HKObjectQueryNoLimit,
                                           sortDescriptors: nil) { [weak self] (query, results, error) in
                guard let result = (results as? [HKQuantitySample])?.first,
                      result.quantity.doubleValue(for: .largeCalorie()) == foodEntry.calories,
                      result.metadata?[HKMetadataKeyFoodType] as? String == foodEntry.foodDescription else {
                    print("Failed to delete record")
                    continuation.resume()
                    return
                }

                self?.delete(result) { success, error in
                    if let error = error {
                        print("Error: \(error)")
                    }
                }
                continuation.resume()
            }
            execute(query)
        }
    }
}
