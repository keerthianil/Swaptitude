//
//  ScheduleMeetingView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/25/25.
//
import SwiftUI
import Firebase
import FirebaseAuth

struct ScheduleMeetingView: View {
    let match: Match
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var meetingTitle = ""
    @State private var startDate = Date()
    @State private var duration: TimeInterval = 3600 // 1 hour default
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var meetingScheduled: MeetingSchedule?
    
    // Pre-defined durations
    private let durations = [
        (label: "30 minutes", value: TimeInterval(30 * 60)),
        (label: "45 minutes", value: TimeInterval(45 * 60)),
        (label: "1 hour", value: TimeInterval(60 * 60)),
        (label: "1.5 hours", value: TimeInterval(90 * 60)),
        (label: "2 hours", value: TimeInterval(120 * 60))
    ]
    
    private var endDate: Date {
        return startDate.addingTimeInterval(duration)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("MEETING DETAILS")) {
                    TextField("Meeting Title", text: $meetingTitle)
                        .autocapitalization(.sentences)
                    
                    DatePicker("Date & Time", selection: $startDate, in: Date()...)
                    
                    Picker("Duration", selection: $duration) {
                        ForEach(durations, id: \.value) { duration in
                            Text(duration.label).tag(duration.value)
                        }
                    }
                }
                
                Section(header: Text("PARTICIPANT")) {
                    HStack {
                        Text("With:")
                        Spacer()
                        Text(match.otherUserName(currentUserId: Auth.auth().currentUser?.uid ?? ""))
                            .foregroundColor(.gray)
                    }
                }
                
                Section {
                    // Fixed button that works in dark mode
                    Button(action: scheduleMeeting) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .foregroundColor(.white)
                            } else {
                                Spacer()
                                Text("Schedule Meeting")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .dark ? Color.blue : AppColors.primary)
                        )
                    }
                    .listRowInsets(EdgeInsets())
                    .disabled(meetingTitle.isEmpty || isLoading)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Schedule Meeting")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }

            .sheet(isPresented: $showSuccess) {
                if let scheduledMeeting = meetingScheduled {
                    VideoMeetingCreationView(meeting: scheduledMeeting, match: match) {
                        presentationMode.wrappedValue.dismiss()
                    }
                } else {
                    // Provide a fallback view if meetingScheduled is nil
                    Text("No meeting data available")
                        .padding()
                }
            }
        }
    }
    
   
    func scheduleMeeting() {
        guard !meetingTitle.isEmpty else { return }
        
        isLoading = true
        
        // Create meeting with empty zoom link
        MeetingService.shared.createMeeting(
            matchId: match.id ?? "",
            participantId: match.otherUserId(currentUserId: Auth.auth().currentUser?.uid ?? ""),
            meetingTitle: meetingTitle,
            startTime: startDate,
            endTime: endDate
        ) { error, meeting in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    return
                }
                
                if let meeting = meeting {
                    print("Meeting created with ID: \(meeting.id ?? "nil")")
                    self.meetingScheduled = meeting
                    self.showSuccess = true
                }
            }
        }
    }
}
