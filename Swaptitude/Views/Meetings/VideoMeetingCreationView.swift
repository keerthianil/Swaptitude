//
//  ZoomMeetingCreationView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/25/25.
//

import SwiftUI
import EventKit
import FirebaseFirestore
import FirebaseAuth
import SafariServices
struct VideoMeetingCreationView: View {
    let meeting: MeetingSchedule
    let match: Match
    let onComplete: () -> Void
    private let db = Firestore.firestore()
    @State private var isCreatingMeeting = false
    @State private var meetingUrl: String = ""
    @State private var showCalendarExport = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showJitsiView = false
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    // Add an init to verify the meeting ID
    init(meeting: MeetingSchedule, match: Match, onComplete: @escaping () -> Void) {
        self.meeting = meeting
        self.match = match
        self.onComplete = onComplete
        
        print("VideoMeetingCreationView initialized with meeting ID: \(meeting.id ?? "nil")")
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "video.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.primary)
                .padding()
            
            Text("Create Video Meeting")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Meeting: \(meeting.meetingTitle)")
                    .font(.headline)
                
                Text("Time: \(dateFormatter.string(from: meeting.startTime))")
                Text("With: \(match.otherUserName(currentUserId: Auth.auth().currentUser?.uid ?? ""))")
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            if isCreatingMeeting {
                ProgressView("Creating meeting...")
                    .padding()
            } else if !meetingUrl.isEmpty {
                Text("Meeting created!")
                    .foregroundColor(.green)
                    .fontWeight(.bold)
                
                Text("Meeting link: \(meetingUrl)")
                    .font(.caption)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                // Join meeting button - blue color
                Button(action: {
                    joinMeeting()
                }) {
                    HStack {
                        Image(systemName: "video.fill")
                            .font(.system(size: 16))
                        Text("Join Meeting")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue)
                )
                .padding(.horizontal)
                
                // Add to Calendar button - purple color for contrast
                Button(action: {
                    addToCalendar()
                }) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 16))
                        Text("Add to Calendar")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.purple)
                )
                .padding(.horizontal)
                
                // Done button - using AppColors.primary with enough contrast
                Button(action: onComplete) {
                    Text("Done")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.primary) // Using yellow color which is visible in dark mode
                )
                .padding(.horizontal)
            } else {
                // Create meeting button
                Button(action: {
                    createJitsiMeeting()
                }) {
                    HStack {
                        Image(systemName: "video.fill")
                            .font(.system(size: 16))
                        Text("Create Video Meeting")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue)
                )
                .padding(.horizontal)
                
                Text("No download required - works directly in browser")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showCalendarExport) {
            CalendarExportView(meeting: meeting, match: match)
        }
        .sheet(isPresented: $showJitsiView) {
            // Display the Jitsi Meet interface in a browser
            SafariView(url: URL(string: meetingUrl)!)
        }
    }
    
    func createJitsiMeeting() {
        isCreatingMeeting = true
        
        // Create a unique room ID based on meeting title and timestamp
        let timestamp = Int(Date().timeIntervalSince1970)
        let sanitizedTitle = meeting.meetingTitle.replacingOccurrences(of: " ", with: "-").lowercased()
        let roomId = "swaptitude-\(sanitizedTitle)-\(timestamp)"
        
        // Generate Jitsi meeting URL
        let jitsiUrl = "https://meet.jit.si/\(roomId)"
        self.meetingUrl = jitsiUrl
        
        // Debug log to see the meeting ID
        print("Meeting ID from meeting object: \(meeting.id ?? "nil")")
        
        // Check if meeting ID exists before trying to update
        if let meetingId = meeting.id, !meetingId.isEmpty {
            print("Updating meeting link for meetingId: \(meetingId) with link: \(jitsiUrl)")
            
            MeetingService.shared.updateMeetingLink(meetingId: meetingId, zoomLink: jitsiUrl) { error in
                DispatchQueue.main.async {
                    self.isCreatingMeeting = false
                    
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                        print("Error updating meeting link: \(error.localizedDescription)")
                    } else {
                        print("Successfully updated meeting link: \(jitsiUrl)")
                        
                        // Update the local meeting object
                        var updatedMeeting = self.meeting
                        updatedMeeting.zoomLink = jitsiUrl
                        updatedMeeting.isConfirmed = true
                        
                        // Schedule notification for the meeting
                        NotificationManager.shared.scheduleMeetingNotification(
                            meeting: updatedMeeting,
                            otherUserName: self.match.otherUserName(currentUserId: Auth.auth().currentUser?.uid ?? "")
                        )
                    }
                }
            }
        } else {
            self.isCreatingMeeting = false
            self.errorMessage = "Missing meeting ID"
            self.showError = true
            print("Error: Meeting ID is nil or empty when trying to update meeting link")
        }
    }
    // Fix for Jitsi meeting link not opening in Safari
    func joinMeeting() {
        guard !meetingUrl.isEmpty else { return }
        
        // Make sure the URL is properly formed
        guard var urlComponents = URLComponents(string: meetingUrl) else {
            errorMessage = "Invalid meeting URL format"
            showError = true
            return
        }
        
        // Ensure the URL has the proper scheme
        if urlComponents.scheme == nil {
            urlComponents.scheme = "https"
        }
        
        guard let url = urlComponents.url else {
            errorMessage = "Unable to create meeting URL"
            showError = true
            return
        }
        
        print("Attempting to open URL: \(url.absoluteString)")
        
        // Use UIApplication.shared.open with options for better compatibility
        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                print("Failed to open URL: \(url.absoluteString)")
                self.errorMessage = "Unable to open meeting link in browser"
                self.showError = true
            }
        }
    }
    
    // Add to calendar
    func addToCalendar() {
        showCalendarExport = true
    }
}

// SafariView for displaying Jitsi
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.preferredControlTintColor = UIColor(AppColors.primary)
        return safariViewController
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
