//
//  SlackNotificationService.swift
//  ProgressionTracker
//
//  Created on 10/22/2025
//

import Foundation
import UIKit

class SlackNotificationService {
    static let shared = SlackNotificationService()
    
    // IMPORTANT: Replace with your actual Slack Webhook URL
    private let slackWebhookURL = "https://hooks.slack.com/services/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"
    
    private init() {}
    
    func sendBugReportNotification(description: String) {
        guard let url = URL(string: slackWebhookURL) else { return }
        
        // Prepare message payload
        let message = """
        🐛 New Bug Report Received! 🐛
        
        *Description:* \(description)
        *App Version:* \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
        *Device:* \(UIDevice.current.model)
        *iOS Version:* \(UIDevice.current.systemVersion)
        *Timestamp:* \(Date())
        """
        
        // Prepare network request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = ["text": message]
        
        do {
            request.httpBody = try JSONEncoder().encode(payload)
            
            // Send notification
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Slack Notification Error: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("Slack notification sent successfully")
                    } else {
                        print("Slack notification failed with status code: \(httpResponse.statusCode)")
                    }
                }
            }.resume()
        } catch {
            print("Error encoding Slack notification: \(error)")
        }
    }
}

