//
//  MeetingViewModel.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/25/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class MeetingViewModel: ObservableObject {
    @Published var meetings: [MeetingSchedule] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    
    private let db = Firestore.firestore()
    
    func fetchMeetings() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in"
            showError = true
            return
        }
        
        isLoading = true
        meetings = []
        
        print("Fetching meetings for user ID: \(userId)")
        
        MeetingService.shared.getMeetings(forUserId: userId) { [weak self] meetings, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.showError = true
                    print("Error fetching meetings: \(error.localizedDescription)")
                    return
                }
                
                print("Fetched \(meetings.count) meetings")
                
                // Log meeting details for debugging
                for (index, meeting) in meetings.enumerated() {
                    print("Meeting \(index + 1):")
                    print("  ID: \(meeting.id ?? "nil")")
                    print("  Title: \(meeting.meetingTitle)")
                    print("  Link: \(meeting.zoomLink.isEmpty ? "No link" : meeting.zoomLink)")
                    print("  Confirmed: \(meeting.isConfirmed)")
                }
                
                // Filter out meetings that have already passed
                let now = Date()
                self?.meetings = meetings.filter { $0.endTime > now }
                
                print("After filtering, displaying \(self?.meetings.count ?? 0) upcoming meetings")
            }
        }
        
        // Also clean up expired meetings
        cleanupExpiredMeetings()
    }
    
    func cleanupExpiredMeetings() {
        MeetingService.shared.cleanupExpiredMeetings()
    }
    
    func joinMeeting(withLink link: String) -> Bool {
        guard let url = URL(string: link), UIApplication.shared.canOpenURL(url) else {
            errorMessage = "Invalid meeting link"
            showError = true
            return false
        }
        
        UIApplication.shared.open(url)
        return true
    }
    
    func deleteMeeting(meetingId: String, completion: @escaping (Bool) -> Void) {
        guard !meetingId.isEmpty else {
            errorMessage = "Invalid meeting ID"
            showError = true
            completion(false)
            return
        }
        
        isLoading = true
        
        db.collection("meetings").document(meetingId).delete { [weak self] error in
            guard let self = self else {
                completion(false)
                return
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    completion(false)
                } else {
                    // Remove from local array
                    if let index = self.meetings.firstIndex(where: { $0.id == meetingId }) {
                        self.meetings.remove(at: index)
                    }
                    completion(true)
                }
            }
        }
    }
   
    func getMeetings(forUserId userId: String, completion: @escaping ([MeetingSchedule], Error?) -> Void) {
        print("Getting meetings for user ID: \(userId)")
        
        // Get meetings where user is host or participant
        let query1 = db.collection("meetings").whereField("hostId", isEqualTo: userId)
        let query2 = db.collection("meetings").whereField("participantId", isEqualTo: userId)
        
        let group = DispatchGroup()
        var allMeetings: [MeetingSchedule] = []
        var finalError: Error? = nil
        
        // Get meetings as host
        group.enter()
        query1.getDocuments { snapshot, error in
            defer { group.leave() }
            
            if let error = error {
                print("Error fetching meetings as host: \(error.localizedDescription)")
                finalError = error
                return
            }
            
            if let documents = snapshot?.documents {
                print("Found \(documents.count) meetings as host")
                
                for document in documents {
                    do {
                        var meeting = try document.data(as: MeetingSchedule.self)
                        meeting.id = document.documentID // Ensure ID is set correctly
                        allMeetings.append(meeting)
                        print("Successfully parsed meeting: \(document.documentID)")
                    } catch {
                        print("Error parsing meeting: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        // Get meetings as participant
        group.enter()
        query2.getDocuments { snapshot, error in
            defer { group.leave() }
            
            if let error = error {
                print("Error fetching meetings as participant: \(error.localizedDescription)")
                finalError = error
                return
            }
            
            if let documents = snapshot?.documents {
                print("Found \(documents.count) meetings as participant")
                
                for document in documents {
                    do {
                        var meeting = try document.data(as: MeetingSchedule.self)
                        meeting.id = document.documentID // Ensure ID is set correctly
                        allMeetings.append(meeting)
                        print("Successfully parsed meeting: \(document.documentID)")
                    } catch {
                        print("Error parsing meeting: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        // Return results when both queries complete
        group.notify(queue: .main) {
            print("Total meetings found: \(allMeetings.count)")
            completion(allMeetings, finalError)
        }
    }
}
