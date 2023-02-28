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
    func caloriesConsumed(date: Date?) async throws -> Int
    func bmr(date: Date?) async throws -> Int
    func exercise(date: Date?) async throws -> Int
    func weight(fromDate: Date, toDate: Date) async throws -> Double?

    func addFoodEntry(_ foodEntry: FoodEntry) async throws
    func deleteFoodEntry(_ foodEntry: FoodEntry) async throws
    func addExerciseEntry(_ exerciseEntry: ExerciseEntry) async throws
    func addWeightEntry(_ weightEntry: WeightEntry) async throws
}

enum HealthStoreError: Error {
    case ErrorNoHealthDataAvailable
}

extension HKHealthStore: HealthStore {
    func authorize() async throws {
        if HKHealthStore.isHealthDataAvailable(),
           let dietaryEnergyConsumed = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed),
           let basalEnergyBurned = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.basalEnergyBurned),
           let activeEnergyBurned = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned),
           let weight = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)
        {
            try await requestAuthorization(toShare: [dietaryEnergyConsumed, activeEnergyBurned, weight],
                                           read: [dietaryEnergyConsumed, basalEnergyBurned, activeEnergyBurned, weight])
        } else {
            throw HealthStoreError.ErrorNoHealthDataAvailable
        }
    }

    private func countForType(_ typeIdentifier: HKQuantityTypeIdentifier, date: Date? = nil) async throws -> Int {
        guard let type = HKObjectType.quantityType(forIdentifier: typeIdentifier) else {
            return 0
        }

        let endOfDay = date ?? Date()
        let startOfDay = Calendar.current.startOfDay(for: endOfDay)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

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

    func bmr(date: Date?) async throws -> Int {
        try await countForType(.basalEnergyBurned, date: date)
    }

    func exercise(date: Date?) async throws -> Int {
        try await countForType(.activeEnergyBurned, date: date)
    }

    func caloriesConsumed(date: Date?) async throws -> Int {
        try await countForType(.dietaryEnergyConsumed, date: date)
    }

    func weight(fromDate: Date, toDate: Date) async throws -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            return 0
        }

        let predicate = HKQuery.predicateForSamples(withStart: fromDate, end: toDate, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type,
                                          quantitySamplePredicate: predicate,
                                          options: .mostRecent) { _, result, error in
                guard let result = result?.mostRecentQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: result.doubleValue(for: HKUnit.pound()))
            }
            execute (query)
        }
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
                guard let result = (results as? [HKQuantitySample])?.first(where: { result in
                    if result.quantity.doubleValue(for: .largeCalorie()) == foodEntry.calories,
                       result.metadata?[HKMetadataKeyFoodType] as? String == foodEntry.foodDescription {
                        return true
                    } else {
                        return false
                    }
                }) else {
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

    func addExerciseEntry(_ exerciseEntry: ExerciseEntry) async throws {
        guard let activeEnergyBurnedType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned) else {
            return
        }
        let quantity = HKQuantity(unit: .largeCalorie(), doubleValue: Double(exerciseEntry.calories))
        let timeConsumed = exerciseEntry.timeExercised
        let exercise = HKQuantitySample(type: activeEnergyBurnedType,
                                        quantity: quantity,
                                        start: timeConsumed,
                                        end: timeConsumed,
                                        metadata: [HKMetadataKeyWorkoutBrandName: exerciseEntry.exerciseDescription])
        try await save(exercise)
    }

    func addWeightEntry(_ weightEntry: WeightEntry) async throws {
        guard let bodyMassType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass) else {
            return
        }
        let weight = HKQuantity(unit: .pound(), doubleValue: Double(weightEntry.weight))
        let timeRecorded = weightEntry.timeRecorded
        let newBodyMass = HKQuantitySample(type: bodyMassType,
                                        quantity: weight,
                                        start: timeRecorded,
                                        end: timeRecorded,
                                        metadata: [HKMetadataKeyWasUserEntered: true])
        try await save(newBodyMass)
    }
}
