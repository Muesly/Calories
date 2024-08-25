//
//  HealthStore.swift
//  Calories
//
//  Created by Tony Short on 08/02/2023.
//

import Foundation
import HealthKit
import SwiftUI

protocol HealthStore {
    func authorize() async throws
    func caloriesConsumed(date: Date) async throws -> Int
    func bmr(date: Date) async throws -> Int
    func exercise(date: Date) async throws -> Int
    func weight(fromDate: Date, toDate: Date) async throws -> Int?

    func caloriesConsumedAllDataPoints(applyModifier: Bool) async throws -> [(Date, Int)]
    func caloriesConsumedAllDataPoints(fromDate: Date, toDate: Date, applyModifier: Bool) async throws -> [(Date, Int)]
    func bmrBetweenDates(fromDate: Date, toDate: Date, applyModifier: Bool) async throws -> [(Date, Int)]
    func activeBetweenDates(fromDate: Date, toDate: Date, applyModifier: Bool) async throws -> [(Date, Int)]
    func weightBetweenDates(fromDate: Date, toDate: Date) async throws -> [(Date, Int)]

    func weeklyWeightChange() async throws -> Int
    func monthlyWeightChange() async throws -> Int

    func addFoodEntry(_ foodEntry: FoodEntry) async throws
    func deleteFoodEntry(_ foodEntry: FoodEntryCD) async throws
    func addExerciseEntry(_ exerciseEntry: ExerciseEntryCD) async throws
    func addWeightEntry(_ weightEntry: WeightEntry) async throws
}

struct HealthStoreFactory {
    static func create() -> HealthStore {
        HKHealthStore()
    }

    static func createNull() -> HealthStore {
        StubbedHealthStore()
    }
}
enum HealthStoreError: Error {
    case errorNoHealthDataAvailable
}

extension HKHealthStore: HealthStore {
    func calorieConsumedModifier() -> Double {
        1.1
    }

    func bmrModifier() -> Double {
        1.0
    }

    func activeEnergyModifier() -> Double {
        0.8
    }

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
            throw HealthStoreError.errorNoHealthDataAvailable
        }
    }

    private func countForType(_ typeIdentifier: HKQuantityTypeIdentifier, date: Date) async throws -> Int {
        guard let type = HKObjectType.quantityType(forIdentifier: typeIdentifier) else {
            return 0
        }

        let endOfDay = date.endOfDay
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

    func bmr(date: Date) async throws -> Int {
        try await Int(Double(countForType(.basalEnergyBurned, date: date)) * bmrModifier())
    }

    func exercise(date: Date) async throws -> Int {
        try await Int(Double(countForType(.activeEnergyBurned, date: date)) * activeEnergyModifier())
    }

    func caloriesConsumed(date: Date) async throws -> Int {
        try await Int(Double(countForType(.dietaryEnergyConsumed, date: date)) * calorieConsumedModifier())
    }

    func caloriesConsumedAllDataPoints(applyModifier: Bool) async throws -> [(Date, Int)] {
        try await caloriesConsumedAllDataPoints(predicate: nil, applyModifier: applyModifier)
    }
    
    func caloriesConsumedAllDataPoints(fromDate: Date, toDate: Date, applyModifier: Bool) async throws -> [(Date, Int)] {
        let predicate = HKQuery.predicateForSamples(withStart: fromDate, end: toDate, options: .strictStartDate)
        return try await caloriesConsumedAllDataPoints(predicate: predicate, applyModifier: applyModifier)
    }

    private func dataPointsForType(_ typeIdentifier: HKQuantityTypeIdentifier, 
                                   predicate: NSPredicate?,
                                   modifierFactor: Double) async throws -> [(Date, Int)] {
        guard let type = HKObjectType.quantityType(forIdentifier: typeIdentifier) else {
            return []
        }

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type,
                                      predicate: predicate,
                                      limit: Int(HKObjectQueryNoLimit),
                                      sortDescriptors: nil) { _, result, error in
                guard let result = result,
                      let dataPoints = result as? [HKCumulativeQuantitySample]  else {
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: dataPoints.map {
                    let date = $0.startDate
                    let calories = Int($0.quantity.doubleValue(for: .kilocalorie()) * modifierFactor)
                    return (date, calories)
                })
            }
            execute (query)
        }
    }

    private func caloriesConsumedAllDataPoints(predicate: NSPredicate?, 
                                               applyModifier: Bool) async throws -> [(Date, Int)] {
        try await dataPointsForType(.dietaryEnergyConsumed,
                                    predicate: predicate,
                                    modifierFactor: applyModifier ? calorieConsumedModifier() : 1.0)
    }

    func bmrBetweenDates(fromDate: Date, 
                         toDate: Date,
                         applyModifier: Bool) async throws -> [(Date, Int)] {
        let predicate = HKQuery.predicateForSamples(withStart: fromDate, end: toDate, options: .strictStartDate)
        return try await dataPointsForType(.basalEnergyBurned, 
                                           predicate: predicate,
                                           modifierFactor: applyModifier ? bmrModifier() : 1.0)
    }

    func activeBetweenDates(fromDate: Date, 
                            toDate: Date,
                            applyModifier: Bool) async throws -> [(Date, Int)] {
        let predicate = HKQuery.predicateForSamples(withStart: fromDate, end: toDate, options: .strictStartDate)
        return try await dataPointsForType(.activeEnergyBurned, 
                                           predicate: predicate,
                                           modifierFactor: applyModifier ? activeEnergyModifier() : 1.0)
    }

    func weightBetweenDates(fromDate: Date, toDate: Date) async throws -> [(Date, Int)] {
        guard let type = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(withStart: fromDate, end: toDate, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type,
                                      predicate: predicate,
                                      limit: Int(HKObjectQueryNoLimit),
                                      sortDescriptors: nil) { _, result, error in
                guard let result = result,
                      let dataPoints = result as? [HKQuantitySample]  else {
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: dataPoints.map {
                    let date = $0.startDate
                    let weight = Int(round($0.quantity.doubleValue(for: HKUnit.pound())))
                    return (date, weight)
                })
            }
            execute (query)
        }
    }

    func weight(fromDate: Date, toDate: Date) async throws -> Int? {
        guard let type = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            return nil
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
                continuation.resume(returning: Int(round(result.doubleValue(for: HKUnit.pound()))))
            }
            execute (query)
        }
    }

    func weeklyWeightChange() async throws -> Int {
        try await weightChange(days: 7)
    }

    func monthlyWeightChange() async throws -> Int {
        try await weightChange(days: 31)
    }

    func weightChange(days: Int) async throws -> Int {
        let weightDataPoints = try await weightBetweenDates(fromDate: Date().addingTimeInterval(TimeInterval(-86400 * days)), toDate: Date())
        guard let first = weightDataPoints.first,
              let last = weightDataPoints.last else {
            return 0
        }
        return last.1 - first.1
    }

    func addFoodEntry(_ foodEntry: FoodEntry) async throws {
        guard let caloriesConsumedType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed) else {
            return
        }
        let quantity = HKQuantity(unit: .largeCalorie(), doubleValue: foodEntry.calories)
        let timeConsumed = foodEntry.timeConsumed
        let caloriesConsumed = HKQuantitySample(type: caloriesConsumedType,
                                                quantity: quantity,
                                                start: timeConsumed,
                                                end: timeConsumed,
                                                metadata: [HKMetadataKeyFoodType: foodEntry.foodDescription])
        try await save(caloriesConsumed)
    }

    func deleteFoodEntry(_ foodEntry: FoodEntryCD) async throws {
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

    func addExerciseEntry(_ exerciseEntry: ExerciseEntryCD) async throws {
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

private struct HealthStoreKey: EnvironmentKey {
    static let defaultValue: HealthStore = HKHealthStore()
}

extension EnvironmentValues {
    var healthStore: HealthStore {
        get { self[HealthStoreKey.self] }
        set { self[HealthStoreKey.self] = newValue }
    }
}
