//
//  MeetingService.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/25/25.
//
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class MeetingService {
    static let shared = MeetingService()
    private let db = Firestore.firestore()
    
    // Private init to ensure singleton pattern
    private init() {}

    func createMeeting(matchId: String, participantId: String, meetingTitle: String, startTime: Date, endTime: Date, completion: @escaping (Error?, MeetingSchedule?) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "MeetingService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]), nil)
            return
        }
        
        // Create meeting data
        let meetingData: [String: Any] = [
            "matchId": matchId,
            "hostId": currentUserId,
            "participantId": participantId,
            "zoomLink": "", // Will be updated after Zoom/Jitsi integration
            "meetingTitle": meetingTitle,
            "startTime": Timestamp(date: startTime),
            "endTime": Timestamp(date: endTime),
            "isConfirmed": false,
            "createdAt": Timestamp(date: Date())
        ]
        
        // Save to Firestore
        let docRef = db.collection("meetings").addDocument(data: meetingData) { error in
            if let error = error {
                print("Error creating meeting: \(error.localizedDescription)")
                completion(error, nil)
                return
            }
        }
        
        // Get the document ID from the reference
        let documentId = docRef.documentID
        print("Created meeting with ID: \(documentId)")
        
        // Create notification for participant
        self.createMeetingNotification(participantId: participantId, meetingTitle: meetingTitle, startTime: startTime)
        
        // Return the meeting with the document ID
        let meeting = MeetingSchedule(
            id: documentId,
            matchId: matchId,
            hostId: currentUserId,
            participantId: participantId,
            zoomLink: "",
            meetingTitle: meetingTitle,
            startTime: startTime,
            endTime: endTime
        )
        
        completion(nil, meeting)
    }
    func updateZoomLink(meetingId: String, zoomLink: String, completion: @escaping (Error?) -> Void) {
        db.collection("meetings").document(meetingId).updateData([
            "zoomLink": zoomLink
        ]) { error in
            completion(error)
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
    
    private func createMeetingNotification(participantId: String, meetingTitle: String, startTime: Date, zoomLink: String = "") {
        // Format date for the notification
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let formattedDate = dateFormatter.string(from: startTime)
        
        // Create notification data
        let notificationData: [String: Any] = [
            "userId": participantId,
            "type": "meeting",
            "title": "New Meeting Invitation",
            "message": "You've been invited to: '\(meetingTitle)' on \(formattedDate)",
            "relatedId": zoomLink.isEmpty ? nil : zoomLink, // Use relatedId for zoom link if available
            "isRead": false,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        // Add notification to Firestore
        db.collection("notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("Error creating meeting notification: \(error.localizedDescription)")
            }
        }
    }
  
    func updateMeetingLink(meetingId: String, zoomLink: String, completion: @escaping (Error?) -> Void) {
        print("Starting update meeting link for ID: \(meetingId) with link: \(zoomLink)")
        
        // Explicitly check for empty meetingId
        guard !meetingId.isEmpty else {
            let error = NSError(domain: "MeetingService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing meeting ID"])
            print("Error: \(error.localizedDescription)")
            completion(error)
            return
        }
        
        // Get reference to the meeting document
        let meetingRef = db.collection("meetings").document(meetingId)
        
        // First verify the document exists
        meetingRef.getDocument { (document, error) in
            if let error = error {
                print("Error checking meeting document: \(error.localizedDescription)")
                completion(error)
                return
            }
            
            guard let document = document, document.exists else {
                let error = NSError(domain: "MeetingService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Meeting document not found: \(meetingId)"])
                print("Error: \(error.localizedDescription)")
                completion(error)
                return
            }
            
            // Document exists, proceed with update
            meetingRef.updateData([
                "zoomLink": zoomLink,
                "isConfirmed": true
            ]) { error in
                if let error = error {
                    print("Error updating meeting document: \(error.localizedDescription)")
                    completion(error)
                } else {
                    print("Successfully updated meeting link to: \(zoomLink)")
                    completion(nil)
                }
            }
        }
    }
 
    func cleanupExpiredMeetings() {
        print("Cleaning up expired meetings...")
        let now = Date()
        
        // Find meetings that have ended
        db.collection("meetings")
            .whereField("endTime", isLessThan: Timestamp(date: now))
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error finding expired meetings: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("No expired meetings to clean up")
                    return
                }
                
                print("Found \(documents.count) expired meetings to clean up")
                
                // Create a batch delete operation
                let batch = self.db.batch()
                
                for document in documents {
                    batch.deleteDocument(document.reference)
                }
                
                // Execute the batch
                batch.commit { error in
                    if let error = error {
                        print("Error deleting expired meetings: \(error.localizedDescription)")
                    } else {
                        print("Successfully deleted \(documents.count) expired meetings")
                    }
                }
            }
    }
}
