//
//  MockHealthStore.swift
//  Calories
//
//  Created by Tony Short on 06/06/2024.
//

import Foundation

class MockHealthStore: HealthStore {
    var authorizeError: Error?
    var bmr: Int = 0
    var exercise: Int = 0
    var caloriesConsumed: Int = 0
    var caloriesBurned: Int = 0
    var weight: Int = 0
    var weightBetweenDatesIndex = 0
    var caloriesConsumedAllDataPoints = [(Date, Int)]()
    var bmrAllDataPoints = [(Date, Int)]()
    var activeCaloriesAllDataPoints = [(Date, Int)]()
    var weightAllDataPoints = [(Date, Int)]()
    var addDelayFetchingWeights = false

    func authorize() async throws {
        guard let error = authorizeError else {
            return
        }
        throw error
    }

    func bmr(date: Date) async throws -> Int {
        bmr
    }

    func exercise(date: Date) async throws -> Int {
        exercise
    }

    func caloriesConsumed(date: Date) async throws -> Int {
        caloriesConsumed
    }

    func weight(date: Date?) async throws -> Int {
        weight
    }

    func addFoodEntry(_ foodEntry: Calories.FoodEntry) async throws {
        caloriesConsumed += Int(foodEntry.calories)
    }

    func deleteFoodEntry(_ foodEntry: Calories.FoodEntry) async throws {
        caloriesConsumed -= Int(foodEntry.calories)
    }

    func addExerciseEntry(_ exerciseEntry: Calories.ExerciseEntry) async throws {
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

    func weight(fromDate: Date, toDate: Date) async throws -> Int? {
        if addDelayFetchingWeights {
            await waitForResult()
        }

        guard weightBetweenDatesIndex < weightAllDataPoints.count else { return nil }
        let weight = weightAllDataPoints.reversed()[weightBetweenDatesIndex] // The concrete function returns most recent first then goes back, so we reverse here.
        weightBetweenDatesIndex += 1
        return weight.1
    }

    func weeklyWeightChange() async throws -> Int {
        0
    }

    func monthlyWeightChange() async throws -> Int {
        0
    }

    func addWeightEntry(_ weightEntry: Calories.WeightEntry) async throws {
        weightAllDataPoints.append((weightEntry.timeRecorded, weightEntry.weight))
        weightBetweenDatesIndex = 0
    }

    func caloriesConsumedAllDataPoints(applyModifier: Bool) async throws -> [(Date, Int)] {
        caloriesConsumedAllDataPoints
    }

    func caloriesConsumedAllDataPoints(fromDate: Date, toDate: Date, applyModifier: Bool) async throws -> [(Date, Int)] {
        caloriesConsumedAllDataPoints
    }

    func bmrBetweenDates(fromDate: Date, toDate: Date, applyModifier: Bool) async throws -> [(Date, Int)] {
        bmrAllDataPoints
    }

    func activeBetweenDates(fromDate: Date, toDate: Date, applyModifier: Bool) async throws -> [(Date, Int)] {
        activeCaloriesAllDataPoints
    }

    func weightBetweenDates(fromDate: Date, toDate: Date) async throws -> [(Date, Int)] {
        weightAllDataPoints
    }

    static var uiTests: MockHealthStore {
        let healthStore = MockHealthStore()
        healthStore.addDelayFetchingWeights = true
        healthStore.weightAllDataPoints = [(Date().startOfWeek.addingTimeInterval(-(7 * 86400) - 1), 200),
                                           (Date().startOfWeek.addingTimeInterval(-1), 199),
                                           (Date(), 198)]
        healthStore.bmr = 1500
        healthStore.exercise = 600
        healthStore.caloriesConsumed = 1800
        return healthStore
    }
}