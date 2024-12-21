//
//  NotificationSender.swift
//  Calories
//
//  Created by Tony Short on 18/08/2024.
//

import Foundation
import SwiftUI

@MainActor
protocol NotificationSenderType {
    func numPendingRequests() async -> Int
    func add(_ request: UNNotificationRequest) async throws
}

class NotificationSender: NotificationSenderType {
    func numPendingRequests() async -> Int {
        let requests = await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                Task {
                    continuation.resume(returning: requests)
                }
            }
        }
        return requests.count
    }
    
    func add(_ request: UNNotificationRequest) async throws {
        let _ = await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().add(request) { _ in
                Task {
                    continuation.resume()
                }
            }
        }
    }
}

class StubbedNotificationSender: NotificationSenderType {
    private var requests = [UNNotificationRequest]()
    var requestDates: [DateComponents] {
        requests.compactMap { ($0.trigger as? UNCalendarNotificationTrigger)?.dateComponents }
    }
    
    func numPendingRequests() async -> Int {
        requests.count
    }
    
    func add(_ request: UNNotificationRequest) async throws {
        requests.append(request)
    }
}

