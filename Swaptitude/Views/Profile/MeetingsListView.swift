//
//  MeetingsListView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/25/25.
//
import SwiftUI
import Firebase
import FirebaseAuth

struct MeetingsListView: View {
    @StateObject private var meetingViewModel = MeetingViewModel()
    @State private var showCopiedAlert = false
    @State private var selectedMeetingLink = ""
    @Environment(\.presentationMode) private var presentationMode
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack {
            if meetingViewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                    .padding()
            } else if meetingViewModel.meetings.isEmpty {
                EmptyStateView(
                    icon: "calendar.badge.clock",
                    title: "No Scheduled Meetings",
                    message: "You don't have any upcoming meetings scheduled."
                )
            } else {
                List {
                    ForEach(meetingViewModel.meetings.sorted(by: { $0.startTime > $1.startTime })) { meeting in
                        // Use a plain wrapper view to prevent List from adding its own tap behavior
                        ZStack {
                            MeetingCardView(
                                meeting: meeting,
                                onCopyLink: {
                                    // Copy link functionality
                                    UIPasteboard.general.string = meeting.zoomLink
                                    selectedMeetingLink = meeting.zoomLink
                                    showCopiedAlert = true
                                },
                                onDelete: {
                                    // Delete functionality
                                    if let meetingId = meeting.id {
                                        meetingViewModel.deleteMeeting(meetingId: meetingId) { _ in
                                            // Refresh after deletion
                                            meetingViewModel.fetchMeetings()
                                        }
                                    }
                                }
                            )
                        }
                        .listRowInsets(EdgeInsets()) // Remove default list row insets
                        .listRowBackground(Color.clear) // Clear background
                        .buttonStyle(PlainButtonStyle()) // Use plain style to prevent tap highlighting
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle("Scheduled Meetings")
        .onAppear {
            meetingViewModel.fetchMeetings()
        }
        .alert("Link Copied!", isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) { }
            Button("Open Link") {
                if let url = URL(string: selectedMeetingLink), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Meeting link has been copied to clipboard.")
        }
    }
}

struct MeetingCardView: View {
    let meeting: MeetingSchedule
    let onCopyLink: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteConfirmation = false
    @State private var showParticipantInfo = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Meeting title
            Text(meeting.meetingTitle)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
            
            // Date and time
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(AppColors.primary)
                Text(dateFormatter.string(from: meeting.startTime))
                    .font(.system(.subheadline, design: .rounded))
            }
            
            // Duration
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(AppColors.primary)
                let duration = Calendar.current.dateComponents([.hour, .minute], from: meeting.startTime, to: meeting.endTime)
                Text("\(duration.hour ?? 0)h \(duration.minute ?? 0)m")
                    .font(.system(.subheadline, design: .rounded))
            }
            
            // Status
            HStack {
                Image(systemName: meeting.isConfirmed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(meeting.isConfirmed ? .green : .orange)
                Text(meeting.isConfirmed ? "Confirmed" : "Pending")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(meeting.isConfirmed ? .green : .orange)
            }
            
            
            // Meeting link if available
            if !meeting.zoomLink.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Meeting Link:")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text(meeting.zoomLink)
                            .font(.system(.caption, design: .rounded))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        Spacer()
                        
                        Button(action: onCopyLink) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(AppColors.primary)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.top, 5)
            } else {
                Text("No meeting link yet. Click 'Join Meeting' to create one.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.top, 5)
            }
            
            // Participant info button
            Button(action: {
                showParticipantInfo.toggle()
            }) {
                HStack {
                    Image(systemName: "person.fill")
                    Text(meeting.hostId == Auth.auth().currentUser?.uid ? "You're hosting" : "You're participating")
                        .font(.system(.caption, design: .rounded))
                }
                .foregroundColor(.blue)
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(.top, 5)
            
            if showParticipantInfo {
                HStack {
                    Text("Role: \(meeting.hostId == Auth.auth().currentUser?.uid ? "Host" : "Participant")")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
            
            // Delete button - Separated and with its own ButtonStyle
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                    Text("Delete Meeting")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.red)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(BorderlessButtonStyle()) 
            .padding(.top, 5)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .alert("Delete Meeting", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this meeting?")
        }
    }

}
