//
//  CalendarExportView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/25/25.
//
import SwiftUI
import EventKit
import FirebaseAuth

struct CalendarExportView: View {
    let meeting: MeetingSchedule
    let match: Match
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var isExporting = true
    @State private var exportSuccess = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var permissionStatus: EKAuthorizationStatus?
   
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding()
            
            Text("Add to Calendar")
                .font(.title)
                .fontWeight(.bold)
            
            // Meeting details view
            VStack(alignment: .leading, spacing: 10) {
                Text("Meeting: \(meeting.meetingTitle)")
                    .font(.headline)
                
                Text("From: \(dateFormatter.string(from: meeting.startTime))")
                Text("To: \(dateFormatter.string(from: meeting.endTime))")
                
                Text("With: \(match.otherUserName(currentUserId: Auth.auth().currentUser?.uid ?? ""))")
                
                if !meeting.zoomLink.isEmpty {
                    Text("Video Meeting Link: \(meeting.zoomLink)")
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            if isExporting {
                ProgressView("Adding to calendar...")
                    .padding()
            } else if exportSuccess {
                Text("Meeting added to your calendar!")
                    .foregroundColor(.green)
                    .fontWeight(.bold)
                    .padding()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppColors.primary)
                        )
                }
                .padding(.horizontal)
            } else if permissionStatus == .denied {
                // Show instructions to enable calendar permissions
                VStack(spacing: 10) {
                    Text("Calendar access is required")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text("Please enable calendar access for Swaptitude in your device settings:")
                        .font(.subheadline)
                    
                    Text("Settings > Privacy > Calendars > Swaptitude")
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    Button(action: {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL)
                        }
                    }) {
                        Text("Open Settings")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue)
                            )
                    }
                    .padding(.horizontal)
                }
                .padding()
            } else {
                Button(action: addToCalendar) {
                    Label("Add to Calendar", systemImage: "calendar.badge.plus")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                        )
                }
                .padding(.horizontal)
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .padding()
                        .foregroundColor(.gray)
                }
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
        .onAppear {
            // Check calendar permission status on appear
            checkCalendarAuthorizationStatus()
            
            // Automatically start the calendar add process
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                addToCalendar()
            }
        }
    }
    
    func checkCalendarAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        DispatchQueue.main.async {
            self.permissionStatus = status
        }
    }
    
    func addToCalendar() {
        isExporting = true
        
        let eventStore = EKEventStore()
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .notDetermined:
            // Request permission
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    if granted {
                        self.createCalendarEvent(eventStore: eventStore)
                    } else {
                        self.isExporting = false
                        self.permissionStatus = .denied
                        if let error = error {
                            self.errorMessage = error.localizedDescription
                            self.showError = true
                        }
                    }
                }
            }
        case .authorized:
            // Already authorized
            createCalendarEvent(eventStore: eventStore)
        case .denied, .restricted:
            // Show settings prompt
            DispatchQueue.main.async {
                self.isExporting = false
                self.permissionStatus = .denied
            }
        @unknown default:
            DispatchQueue.main.async {
                self.isExporting = false
                self.errorMessage = "Unknown authorization status"
                self.showError = true
            }
        }
    }
    func createCalendarEvent(eventStore: EKEventStore) {
        // Create calendar event
        let event = EKEvent(eventStore: eventStore)
        event.title = "Swaptitude: \(meeting.meetingTitle)"  // Add app name in title
        event.startDate = meeting.startTime
        event.endDate = meeting.endTime
        
        // Make sure the meeting link is prominent in both notes and location
        if !meeting.zoomLink.isEmpty {
            // Set location to the actual link so it's visible in calendar notifications
            event.location = "Video: \(meeting.zoomLink)"
            
            // Add detailed notes with the link prominently displayed
            event.notes = """
            Swaptitude Skill Exchange Meeting
            ━━━━━━━━━━━━━━━━━━
            
            With: \(match.otherUserName(currentUserId: Auth.auth().currentUser?.uid ?? ""))
            
            JOIN LINK: \(meeting.zoomLink)
            
            (No download required - works directly in browser)
            """
        } else {
            event.location = "Swaptitude Video Meeting"
            event.notes = "Skill Exchange with \(match.otherUserName(currentUserId: Auth.auth().currentUser?.uid ?? ""))"
        }
        
        // Set an alert to remind user 10 minutes before meeting
        let alarm = EKAlarm(relativeOffset: -600) // 10 minutes before
        event.addAlarm(alarm)
        
        // Add to default calendar
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            DispatchQueue.main.async {
                exportSuccess = true
                isExporting = false
            }
        } catch {
            DispatchQueue.main.async {
                errorMessage = error.localizedDescription
                showError = true
                isExporting = false
            }
        }
    }
}
