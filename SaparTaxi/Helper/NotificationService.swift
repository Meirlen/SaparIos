//
//  NotificationService.swift
//  UITestCripto
//
//  Created by Max on 10.10.2022.
//

import UIKit
import UserNotifications

class NotificationService: NSObject {

    static let shared = NotificationService()
    private var rootVC: UIViewController?
    
    func setup(rootViewController: UIViewController?) {
        rootVC = rootViewController
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    static func requestPermission(completion:((Bool)->Void)?) {
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }
    
    @discardableResult static func setupNotification(identifier: String, threadID: String, text: String, time: Date) -> Bool {
        let timeInterval = time.timeIntervalSince(Date())
        guard timeInterval > 0, identifier.count > 0 else {
            return false
        }
        let content = UNMutableNotificationContent()
        content.badge = NSNumber(value: 1)
        content.body = text
        content.threadIdentifier = threadID
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error) in
            
        }
        return true
    }
    
    static func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        

    }
}
