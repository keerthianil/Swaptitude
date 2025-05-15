//
//  NotificationManager.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/25/25.
//
import SwiftUI
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func checkPermissions(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let authorized = settings.authorizationStatus == .authorized
                completion(authorized)
            }
        }
    }
    
    func scheduleMatchNotification(matchName: String) {
        checkPermissions { granted in
            guard granted else {
                print("Notification permissions not granted")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = "New Match!"
            content.body = "You matched with \(matchName). Start a conversation!"
            content.sound = UNNotificationSound.default
            
            // Show notification immediately for testing
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "match-\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling match notification: \(error)")
                } else {
                    print("Match notification scheduled successfully")
                }
            }
        }
    }
    
 
    func scheduleMessageNotification(senderName: String, message: String) {
        checkPermissions { granted in
            guard granted else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "New Message from \(senderName)"
            content.body = message.count > 50 ? "\(message.prefix(50))..." : message
            content.sound = UNNotificationSound.default
            
            // Trigger immediately
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "message-\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling message notification: \(error)")
                } else {
                    print("Message notification scheduled successfully")
                }
            }
        }
    }
    
    func scheduleMeetingNotification(meeting: MeetingSchedule, otherUserName: String) {
        checkPermissions { granted in
            guard granted else { return }
            
            // Create confirmation notification content
            let confirmContent = UNMutableNotificationContent()
            confirmContent.title = "Meeting Scheduled"
            confirmContent.body = "Your meeting '\(meeting.meetingTitle)' with \(otherUserName) has been scheduled"
            confirmContent.sound = UNNotificationSound.default
            
            // Confirmation notification shows immediately
            let confirmTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
            let confirmRequest = UNNotificationRequest(
                identifier: "meeting-confirm-\(UUID().uuidString)",
                content: confirmContent,
                trigger: confirmTrigger
            )
            
            // Create reminder notification content
            let reminderContent = UNMutableNotificationContent()
            reminderContent.title = "Upcoming Meeting: \(meeting.meetingTitle)"
            reminderContent.body = "Your meeting with \(otherUserName) starts in 10 minutes"
            reminderContent.sound = UNNotificationSound.default
            
            // Calculate the time 10 minutes before the meeting
            let reminderDate = Calendar.current.date(byAdding: .minute, value: -10, to: meeting.startTime)
            
            // Only schedule the reminder if the meeting is more than 10 minutes in the future
            if let reminderDate = reminderDate, reminderDate.timeIntervalSinceNow > 0 {
                // Use calendar components for the reminder
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
                let reminderTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                
                let reminderRequest = UNNotificationRequest(
                    identifier: "meeting-reminder-\(UUID().uuidString)",
                    content: reminderContent,
                    trigger: reminderTrigger
                )
                
                // Schedule both notifications
                UNUserNotificationCenter.current().add(confirmRequest) { error in
                    if let error = error {
                        print("Error scheduling meeting confirmation notification: \(error)")
                    } else {
                        print("Meeting confirmation notification scheduled successfully")
                    }
                }
                
                UNUserNotificationCenter.current().add(reminderRequest) { error in
                    if let error = error {
                        print("Error scheduling meeting reminder notification: \(error)")
                    } else {
                        print("Meeting reminder notification scheduled for: \(reminderDate)")
                    }
                }
            } else {
                // Only schedule the confirmation notification if the meeting is too soon
                UNUserNotificationCenter.current().add(confirmRequest) { error in
                    if let error = error {
                        print("Error scheduling meeting confirmation notification: \(error)")
                    } else {
                        print("Meeting confirmation notification scheduled successfully")
                        print("Meeting is too soon for a 10-minute reminder notification")
                    }
                }
            }
        }
    }
    
    func scheduleReviewNotification(reviewerName: String) {
        checkPermissions { granted in
            guard granted else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "New Review"
            content.body = "\(reviewerName) left you a review. Check it out!"
            content.sound = UNNotificationSound.default
            
            // Trigger immediately
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "review-\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling review notification: \(error)")
                } else {
                    print("Review notification scheduled successfully")
                }
            }
        }
    }
}

// Helper extension to create a new notification content with modified properties
extension UNMutableNotificationContent {
    convenience init(_ original: UNNotificationContent, title: String? = nil) {
        self.init()
        self.title = title ?? original.title
        self.subtitle = original.subtitle
        self.body = original.body
        self.sound = original.sound
        self.badge = original.badge
        self.userInfo = original.userInfo
        self.categoryIdentifier = original.categoryIdentifier
    }
}
