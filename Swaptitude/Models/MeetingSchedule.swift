//
//  MeetingSchedule.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/25/25.
//

import Foundation
import FirebaseFirestore

struct MeetingSchedule: Identifiable, Codable {
    @DocumentID var id: String?
    var matchId: String
    var hostId: String
    var participantId: String
    var zoomLink: String
    var meetingTitle: String
    var startTime: Date
    var endTime: Date
    var isConfirmed: Bool = false
    var createdAt: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case id
        case matchId
        case hostId
        case participantId
        case zoomLink
        case meetingTitle
        case startTime
        case endTime
        case isConfirmed
        case createdAt
    }
    
    // initializer to fix potential nil handling
    init(id: String? = nil, matchId: String, hostId: String, participantId: String,
         zoomLink: String = "", meetingTitle: String, startTime: Date, endTime: Date,
         isConfirmed: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.matchId = matchId
        self.hostId = hostId
        self.participantId = participantId
        self.zoomLink = zoomLink
        self.meetingTitle = meetingTitle
        self.startTime = startTime
        self.endTime = endTime
        self.isConfirmed = isConfirmed
        self.createdAt = createdAt
    }
}
