//
//  MockHealthStore.swift
//  Calories
//
//  Created by Tony Short on 06/06/2024.
//

import Foundation
@testable import Calories

class MockHealthStore: HealthStore {
    var authorizeError: Error?
    var bmr: Int = 0
    var exercise: Int = 0
    var caloriesConsumed: Int = 0
    var caloriesBurned: Int = 0
    var weight: Double = 0
    var weightBetweenDatesIndex = 0
    var weightBetweenDates = [Double]()
    var caloriesConsumedAllDataPoints = [(Date, Int)]()
    var bmrAllDataPoints = [(Date, Int)]()
    var activeCaloriesAllDataPoints = [(Date, Int)]()
    var weightAllDataPoints = [(Date, Double)]()
    
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

    func weight(date: Date?) async throws -> Double {
        weight
    }

    func addFoodEntry(_ foodEntry: Calories.FoodEntry) async throws {
        caloriesConsumed += Int(foodEntry.calories)
    }

    func deleteFoodEntry(_ foodEntry: Calories.FoodEntry) async throws {
        caloriesConsumed -= Int(foodEntry.calories)
    }

    func addExerciseEntry(_ exerciseEntry: Calories.ExerciseEntry) async throws {
        caloriesBurned += exerciseEntry.calories
    }

    func weight(fromDate: Date, toDate: Date) async throws -> Double? {
        let weight = weightBetweenDates.reversed()[weightBetweenDatesIndex] // The concrete function returns most recent first then goes back, so we reverse here.
        weightBetweenDatesIndex += 1
        return weight
    }

    func addWeightEntry(_ weightEntry: Calories.WeightEntry) async throws {
        weight = Double(weightEntry.weight)
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
    
    func weightBetweenDates(fromDate: Date, toDate: Date) async throws -> [(Date, Double)] {
        weightAllDataPoints
    }
}
