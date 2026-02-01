//
//  StubbedHealthStore.swift
//  Calories
//
//  Created by Tony Short on 06/06/2024.
//

import Foundation

public class StubbedHealthStore: HealthStore {
    public var initialWeight = 200
    public var caloriesConsumedReads = 0
    public var weightBetweenDatesIndex = 0
    public var weightAllDataPoints: [(Date, Int)] = [
        (Date().startOfWeek.addingTimeInterval(-(7 * 86400) - 1), 200),
        (Date().startOfWeek.addingTimeInterval(-1), 199),
        (Date(), 198),
    ]

    public init() {}

    public func authorize() async throws {
    }

    public func bmr(date: Date) async throws -> Int {
        1500
    }

    public func exercise(date: Date) async throws -> Int {
        600
    }

    public func caloriesConsumed(date: Date) async throws -> Int {
        caloriesConsumedReads += 1
        return 1800
    }

    public func weight(date: Date?) async throws -> Int {
        initialWeight
    }

    public func addFoodEntry(_ foodEntry: FoodEntry) async throws {
    }

    public func deleteFoodEntry(_ foodEntry: FoodEntry) async throws {
    }

    public func addExerciseEntry(_ exerciseEntry: ExerciseEntry) async throws {
    }

    public func addWeightEntry(_ weightEntry: WeightEntry) async throws {
    }

    public func caloriesConsumedAllDataPoints(applyModifier: Bool) async throws -> [(Date, Int)] {
        [(Date(), 1800)]
    }

    public func caloriesConsumedAllDataPoints(fromDate: Date, toDate: Date, applyModifier: Bool)
        async throws -> [(Date, Int)]
    {
        [(Date(), 1800)]
    }

    public func bmrBetweenDates(fromDate: Date, toDate: Date, applyModifier: Bool) async throws
        -> [(Date, Int)]
    {
        [(Date(), 1500)]
    }

    public func activeBetweenDates(fromDate: Date, toDate: Date, applyModifier: Bool) async throws
        -> [(Date, Int)]
    {
        [(Date(), 600)]
    }

    public func weight(fromDate: Date, toDate: Date) async throws -> Int? {
        guard weightBetweenDatesIndex < weightAllDataPoints.count else { return nil }
        let weight = weightAllDataPoints.reversed()[weightBetweenDatesIndex]
        weightBetweenDatesIndex += 1
        return weight.1
    }

    public func weeklyWeightChange() async throws -> Int {
        2
    }

    public func monthlyWeightChange() async throws -> Int {
        5
    }

    public func weightBetweenDates(fromDate: Date, toDate: Date) async throws -> [(Date, Int)] {
        weightAllDataPoints
    }
}
