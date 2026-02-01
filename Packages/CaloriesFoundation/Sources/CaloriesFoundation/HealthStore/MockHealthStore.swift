//
//  MockHealthStore.swift
//  Calories
//
//  Created by Tony Short on 06/06/2024.
//

import Foundation

public class MockHealthStore: HealthStore {
    public var authorizeError: Error?
    public var bmr: Int = 0
    public var exercise: Int = 0
    public var caloriesConsumed: Int = 0
    public var caloriesBurned: Int = 0
    public var weight: Int = 0
    public var weightBetweenDatesIndex = 0
    public var caloriesConsumedAllDataPoints = [(Date, Int)]()
    public var bmrAllDataPoints = [(Date, Int)]()
    public var activeCaloriesAllDataPoints = [(Date, Int)]()
    public var weightAllDataPoints = [(Date, Int)]()
    public var addDelayFetchingWeights = false

    public init() {}

    public func authorize() async throws {
        guard let error = authorizeError else {
            return
        }
        throw error
    }

    public func bmr(date: Date) async throws -> Int {
        bmr
    }

    public func exercise(date: Date) async throws -> Int {
        exercise
    }

    public func caloriesConsumed(date: Date) async throws -> Int {
        caloriesConsumed
    }

    public func weight(date: Date?) async throws -> Int {
        weight
    }

    public func addFoodEntry(_ foodEntry: FoodEntry) async throws {
        caloriesConsumed += Int(foodEntry.calories)
    }

    public func deleteFoodEntry(_ foodEntry: FoodEntry) async throws {
        caloriesConsumed -= Int(foodEntry.calories)
    }

    public func addExerciseEntry(_ exerciseEntry: ExerciseEntry) async throws {
        caloriesBurned += Int(exerciseEntry.calories)
    }

    private func waitForResult() async {
        let _ = await withCheckedContinuation { continuation in
            Task.detached {
                try? await Task.sleep(for: .seconds(0.01))
                return continuation.resume()
            }
        }
    }

    public func weight(fromDate: Date, toDate: Date) async throws -> Int? {
        if addDelayFetchingWeights {
            await waitForResult()
        }

        guard weightBetweenDatesIndex < weightAllDataPoints.count else { return nil }
        // Returns most recent first then goes back, so we reverse here
        let weight = weightAllDataPoints.reversed()[weightBetweenDatesIndex]
        weightBetweenDatesIndex += 1
        return weight.1
    }

    public func weeklyWeightChange() async throws -> Int {
        0
    }

    public func monthlyWeightChange() async throws -> Int {
        0
    }

    public func addWeightEntry(_ weightEntry: WeightEntry) async throws {
        weightAllDataPoints.append((weightEntry.timeRecorded, weightEntry.weight))
        weightBetweenDatesIndex = 0
    }

    public func caloriesConsumedAllDataPoints(applyModifier: Bool) async throws -> [(Date, Int)] {
        caloriesConsumedAllDataPoints
    }

    public func caloriesConsumedAllDataPoints(fromDate: Date, toDate: Date, applyModifier: Bool)
        async throws -> [(Date, Int)]
    {
        caloriesConsumedAllDataPoints
    }

    public func bmrBetweenDates(fromDate: Date, toDate: Date, applyModifier: Bool) async throws
        -> [(
            Date, Int
        )]
    {
        bmrAllDataPoints
    }

    public func activeBetweenDates(fromDate: Date, toDate: Date, applyModifier: Bool) async throws
        -> [(
            Date, Int
        )]
    {
        activeCaloriesAllDataPoints
    }

    public func weightBetweenDates(fromDate: Date, toDate: Date) async throws -> [(Date, Int)] {
        weightAllDataPoints
    }

    public static var uiTests: MockHealthStore {
        let healthStore = MockHealthStore()
        healthStore.addDelayFetchingWeights = true
        healthStore.weightAllDataPoints = [
            (Date().startOfWeek.addingTimeInterval(-(7 * 86400) - 1), 200),
            (Date().startOfWeek.addingTimeInterval(-1), 199),
            (Date(), 198),
        ]
        healthStore.bmr = 1500
        healthStore.exercise = 600
        healthStore.caloriesConsumed = 1800
        return healthStore
    }
}
