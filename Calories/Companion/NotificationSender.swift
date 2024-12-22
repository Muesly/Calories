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
    func requestNotificationsPermission() async
    func hasPendingRequests() async -> Bool
    func add(_ request: UNNotificationRequest) async throws
}

class NotificationSender: NotificationSenderType {
    func requestNotificationsPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization()
            if granted {
                // No need to report anything
            }
        } catch {
                print("Permission denied: \(error.localizedDescription)")
        }
    }

    func hasPendingRequests() async -> Bool {
        await UNUserNotificationCenter.current().hasPendingRequests()
    }

    func add(_ request: UNNotificationRequest) async throws {
        Task { @MainActor in
            try await UNUserNotificationCenter.current().add(request)
        }
    }
}

extension UNUserNotificationCenter {
    func hasPendingRequests() async -> Bool {
        await pendingNotificationRequests().count > 0
    }
}

class StubbedNotificationSender: NotificationSenderType {
    private var requests = [UNNotificationRequest]()
    var requestedPermission = false

    var requestDates: [DateComponents] {
        requests.compactMap { ($0.trigger as? UNCalendarNotificationTrigger)?.dateComponents }
    }

    func requestNotificationsPermission() {
        requestedPermission = true
    }

    func hasPendingRequests() async -> Bool {
        requests.count > 0
    }
    
    func add(_ request: UNNotificationRequest) async throws {
        requests.append(request)
    }
}

