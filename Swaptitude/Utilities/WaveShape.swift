//
//  WaveShape.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/7/25.
//
import SwiftUI

struct WaveShape: Shape {
    var offset: Double = 0
    var percent: Double = 0.8
    
    var animatableData: Double {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // a sine wave with the given frequency
        let width = Double(rect.width)
        let height = Double(rect.height)
        let midHeight = height * percent
        let wavelength = width / 1.5
        
        path.move(to: CGPoint(x: 0, y: height))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / wavelength
            let sine = sin(relativeX + offset / 100)
            let y = midHeight + sine * 12
            
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        
        return path
    }
}
