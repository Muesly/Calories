//
//  NotificationSender.swift
//  Calories
//
//  Created by Tony Short on 18/08/2024.
//

import Foundation
import SwiftUI

protocol NotificationSender {
    func pendingNotificationRequests() async -> [UNNotificationRequest]
    func add(_ request: UNNotificationRequest) async throws
}

extension UNUserNotificationCenter: NotificationSender {}

class StubbedNotificationSender: NotificationSender {
    private var requests = [UNNotificationRequest]()
    var requestDates: [DateComponents] {
        requests.compactMap { ($0.trigger as? UNCalendarNotificationTrigger)?.dateComponents }
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        requests
    }
    
    func add(_ request: UNNotificationRequest) async throws {
        requests.append(request)
    }
}
