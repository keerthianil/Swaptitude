//
//  FirebaseManager.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/6/25.
//

import Foundation
import Firebase
import FirebaseFirestore

class FirebaseService {
    static let shared = FirebaseService()
    
    private let db = Firestore.firestore()
    
    // Simple verification code generation
    func generateVerificationCode() -> String {
        let digits = "0123456789"
        var code = ""
        for _ in 0..<6 {
            let randomIndex = Int.random(in: 0..<digits.count)
            let digit = digits[digits.index(digits.startIndex, offsetBy: randomIndex)]
            code.append(digit)
        }
        return code
    }
    
    // Store verification code in Firestore
    func storeVerificationCode(for userId: String, code: String, completion: @escaping (Error?) -> Void) {
        let data: [String: Any] = [
            "verificationCode": code,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        db.collection("verification_codes").document(userId).setData(data) { error in
            completion(error)
        }
    }
    
    // Verify the code
    func verifyCode(userId: String, enteredCode: String, completion: @escaping (Bool, Error?) -> Void) {
        db.collection("verification_codes").document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(false, error)
                return
            }
            
            guard let data = snapshot?.data(),
                  let storedCode = data["verificationCode"] as? String else {
                completion(false, nil)
                return
            }
            
            let isMatch = storedCode == enteredCode
            
            if isMatch {
                // Update user as verified
                self.db.collection("users").document(userId).updateData([
                    "isVerified": true
                ]) { error in
                    completion(true, error)
                }
            } else {
                completion(false, nil)
            }
        }
    }
}
