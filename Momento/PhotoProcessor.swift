//
//  PhotoProcessor.swift
//  Momento
//
//  Created by Nicholas Dapolito on 11/24/24.
//

import Foundation
import SwiftUI

class PhotoProcessor {
    static func processImage(_ imageData: Data) -> Data? {
        guard let ciImage = CIImage(data: imageData) else { return nil }
        let context = CIContext()
        
        // Apply basic enhancements
        var processedImage = ciImage
        
        // Enhance colors
        if let colorAdjust = CIFilter(name: "CIColorControls") {
            colorAdjust.setValue(processedImage, forKey: kCIInputImageKey)
            colorAdjust.setValue(1.1, forKey: kCIInputSaturationKey) // Slight saturation boost
            colorAdjust.setValue(1.05, forKey: kCIInputContrastKey) // Subtle contrast
            if let output = colorAdjust.outputImage {
                processedImage = output
            }
        }
        
        // Smart HDR-like effect
        if let highlightShadow = CIFilter(name: "CIHighlightShadowAdjust") {
            highlightShadow.setValue(processedImage, forKey: kCIInputImageKey)
            highlightShadow.setValue(0.3, forKey: "inputShadowAmount") // Lift shadows
            highlightShadow.setValue(-0.3, forKey: "inputHighlightAmount") // Recover highlights
            if let output = highlightShadow.outputImage {
                processedImage = output
            }
        }
        
        // Convert back to data
        if let cgImage = context.createCGImage(processedImage, from: processedImage.extent),
           let processedData = UIImage(cgImage: cgImage).heicData() {
            return processedData
        }
        
        return nil
    }
}
