//
//  SwaptitudeApp.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/6/25.
//
import SwiftUI
import Firebase
import FirebaseAuth
import UserNotifications

@main
struct SwaptitudeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
            // Configure Firebase
            FirebaseApp.configure()
            
            // Clean up expired meetings on app launch
            MeetingService.shared.cleanupExpiredMeetings()
            
            // Configure notifications
            UNUserNotificationCenter.current().delegate = self
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if granted {
                    print("Notification permission granted")
                    
                    // Register for remote notifications
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                } else if let error = error {
                    print("Notification permission denied: \(error)")
                }
            }
            
            return true
        }
    
    // show notifications when the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    // Handle notification taps
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {

        completionHandler()
    }
}
