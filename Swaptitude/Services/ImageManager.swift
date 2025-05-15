//
//  ImageManager.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/7/25.
//
import Foundation
import UIKit
import SwiftUI

class ImageManager {
    static let shared = ImageManager()
    
    private init() {}
    
    // Save image to document directory
    func saveImage(_ image: UIImage, userId: String) -> String? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let imageData = image.jpegData(compressionQuality: 0.7) else {
            return nil
        }
        
        // Create a unique filename
        let fileName = "profile_\(userId)_\(Date().timeIntervalSince1970).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            return fileName
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    // Load image from document directory
    func loadImage(fromPath path: String) -> UIImage? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(path)
        
        if let imageData = try? Data(contentsOf: fileURL) {
            return UIImage(data: imageData)
        }
        
        return nil
    }
    
    // Delete image from document directory
    func deleteImage(atPath path: String) -> Bool {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(path)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            return true
        } catch {
            print("Error deleting image: \(error)")
            return false
        }
    }
    
    // For backward compatibility with ProfileImageManager
    func saveProfileImage(_ image: UIImage, forUserId userId: String) -> Bool {
        return saveImage(image, userId: userId) != nil
    }
    
    func loadProfileImage(forUserId userId: String) -> UIImage? {
        let fileName = "\(userId)_profile.jpg"
        return loadImage(fromPath: fileName)
    }
    
    func deleteProfileImage(forUserId userId: String) -> Bool {
        let fileName = "\(userId)_profile.jpg"
        return deleteImage(atPath: fileName)
    }
}
