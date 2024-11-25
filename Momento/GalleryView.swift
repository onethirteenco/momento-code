//
//  GalleryView.swift
//  Momento
//
//  Created by Nicholas Dapolito on 8/20/24.
//

import SwiftUI
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins


struct GalleryView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var photos: [UIImage] = []
    @State private var selectedPhoto: UIImage? = nil
    @State private var currentPhotoIndex: Int = 0
    @State private var showSaveActionSheet: Bool = false
    @State private var showDeletePrompt: Bool = false
    @State private var filterType: FilterType = .none
    @State private var filterIntensity: Float = 1.0
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    enum FilterType: String, CaseIterable, Identifiable {
        case none
        case noir
        case suburbia
        case summerSky
        case bayDays
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .none: return "None"
            case .noir: return "Noir"
            case .suburbia: return "Suburbia"
            case .summerSky: return "Summer Sky"
            case .bayDays: return "Bay Days"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView("Loading photos...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.gray)
                        .padding()
                } else if photos.isEmpty {
                    VStack {
                        Text("No momentos.")
                            .foregroundColor(.gray)
                            .fontDesign(.monospaced)
                            .padding()
                    }
                } else {
                    ZStack {
                        BlurView(style: .dark)
                            .edgesIgnoringSafeArea(.all)
                        VStack {
                            TabView(selection: $currentPhotoIndex) {
                                ForEach(photos.indices, id: \.self) { index in
                                    GeometryReader { proxy in
                                        VStack {
                                            Image(uiImage: applyFilter(to: photos[index]))
                                                .resizable()
                                                .scaledToFit()
                                                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                                                .padding(.horizontal, 25)
                                                .padding(.vertical, 15)
                                        }
                                        .frame(width: proxy.size.width, height: proxy.size.height)
                                    }
                                    .tag(index) // Tag for TabView selection
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                            .padding(.bottom, 50) // Add space for the bottom bar
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.gray)
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Picker("Filter", selection: $filterType) {
                        ForEach(FilterType.allCases) { filter in
                            Text(filter.displayName).tag(filter)
                        }
                    }
                    .pickerStyle(.menu)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if !photos.isEmpty {
                        Menu {
                            // Save to Gallery button
                            Button(action: {
                                    showSaveActionSheet = true
                            }) {
                                Label("Save to Gallery", systemImage: "square.and.arrow.down.fill")
                                    .foregroundColor(selectedPhoto == nil ? .gray : .primary) // Change color based on selection
                            }
                            
                            // Delete All Photos button
                            Button(action: {
                                showDeletePrompt = true
                            }) {
                                Label("Delete Momentos", systemImage: "trash")
                                    .foregroundColor(.red)
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundStyle(Color.gray)
                        }
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Gallery")
                        .font(.title2)
                        .fontDesign(.monospaced)
                        .fontWeight(.bold)
                        .tint(.primary)
                }

            }
            .actionSheet(isPresented: $showSaveActionSheet) {
                ActionSheet(title: Text("Save Photo"), message: Text("Would you like to save the cropped image or the full-size image?"), buttons: [
                    .default(Text("Cropped Image")) {
                        if let selectedPhoto = selectedPhoto {
                            savePhoto(image: selectedPhoto, isFullSize: false)
                        }
                    },
                    .default(Text("Full-Size Image")) {
                        if let selectedPhoto = selectedPhoto {
                            savePhoto(image: selectedPhoto, isFullSize: true)
                        }
                    },
                    .cancel()
                ])
            }
            .alert(isPresented: $showDeletePrompt) {
                Alert(
                    title: Text("Delete Momentos"),
                    message: Text("Do you want to delete every momento?"),
                    primaryButton: .destructive(Text("Delete All")) {
                        deleteAllPhotos()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .onAppear(perform: loadPhotos)
    }

    func loadPhotos() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "Could not access photos directory"
                }
                return
            }
            
            let photoDirectoryURL = documentsURL.appendingPathComponent("MomentoPhotos", isDirectory: true)
            
            // Create directory if it doesn't exist
            if !fileManager.fileExists(atPath: photoDirectoryURL.path) {
                do {
                    try fileManager.createDirectory(at: photoDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    DispatchQueue.main.async {
                        isLoading = false
                        errorMessage = "Could not create photos directory"
                    }
                    return
                }
            }
            
            do {
                // Get all files in the directory
                let photoURLs = try fileManager.contentsOfDirectory(
                    at: photoDirectoryURL,
                    includingPropertiesForKeys: [.creationDateKey],
                    options: [.skipsHiddenFiles]
                )
                
                // Filter for images and sort by creation date
                let sortedPhotoURLs = photoURLs
                    .filter { $0.pathExtension.lowercased() == "heic" }
                    .sorted { url1, url2 in
                        let date1 = try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                        let date2 = try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                        return date1 ?? Date.distantPast > date2 ?? Date.distantPast
                    }
                
                // Load the images
                let loadedPhotos = sortedPhotoURLs.compactMap { url -> UIImage? in
                    if let imageData = try? Data(contentsOf: url) {
                        return UIImage(data: imageData)
                    }
                    return nil
                }
                
                DispatchQueue.main.async {
                    self.photos = loadedPhotos
                    self.isLoading = false
                    if loadedPhotos.isEmpty {
                        self.errorMessage = "No photos found"
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Error loading photos: \(error.localizedDescription)"
                }
            }
        }
    }

    private func savePhoto(image: UIImage, isFullSize: Bool) {
        if isFullSize {
            // Save full-size image
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        } else {
            // Save cropped image (example cropping logic)
            let croppedImage = cropToSquare(image: image)
            UIImageWriteToSavedPhotosAlbum(croppedImage, nil, nil, nil)
        }

        // Show alert and vibration
        showSaveAlert()
    }

    private func cropToSquare(image: UIImage) -> UIImage {
        let size = min(image.size.width, image.size.height)
        let cropRect = CGRect(x: (image.size.width - size) / 2, y: (image.size.height - size) / 2, width: size, height: size)
        
        if let cgImage = image.cgImage?.cropping(to: cropRect) {
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }
        return image
    }

    private func showSaveAlert() {
        // Trigger vibration
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactFeedbackGenerator.impactOccurred()
        
        // Show alert (use .alert or .confirmationDialog)
        print("Image saved to photo library")
    }

    private func deleteAllPhotos() {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

        let photoDirectoryURL = documentsURL.appendingPathComponent("MomentoPhotos", isDirectory: true)

        do {
            let photoURLs = try fileManager.contentsOfDirectory(at: photoDirectoryURL, includingPropertiesForKeys: nil)
            for photoURL in photoURLs {
                try fileManager.removeItem(at: photoURL)
            }
            photos.removeAll()
        } catch {
            print("Error deleting photos: \(error.localizedDescription)")
        }
    }
    
    func applyFilter(to image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        let context = CIContext()
        let filter: CIFilter?
        
        // Create the filter based on the selected filter type
        switch filterType {
        case .noir:
            let noirFilter = CIFilter.photoEffectNoir()
            noirFilter.inputImage = ciImage
            filter = noirFilter
        case .bayDays:
            // Step 1: Color controls for general mood adjustment
            let bayDays = CIFilter.colorControls()
            bayDays.inputImage = ciImage
            bayDays.brightness = -0.2  // Lower brightness for a moody feel
            bayDays.contrast = 1.8     // Increase contrast to make shadows deeper and highlights more defined
            bayDays.saturation = 0.8   // Reduce saturation for subdued colors

            // Step 2: Add a blue tint for a cool, dramatic feel
            let blueTint = CIFilter.colorMonochrome()
            blueTint.inputImage = bayDays.outputImage
            blueTint.color = CIColor(red: 0.0, green: 0.0, blue: 1.0) // Apply a blue tint
            blueTint.intensity = 0.3  // Adjust intensity of the blue tint to keep it subtle

            // Set the final filter output
            filter = blueTint

        case .summerSky:
            // Step 1: Basic color controls for vibrant and bright summer feel
            let summerSky = CIFilter.colorControls()
            summerSky.inputImage = ciImage
            summerSky.brightness = 0.2   // Slightly increase brightness for a sunny look
            summerSky.contrast = 1.4     // Moderate contrast to keep the image lively
            summerSky.saturation = 1.8   // Significantly increase saturation for vibrant colors

            // Step 2: Apply a warm tone to mimic a summer glow
            let warmTone = CIFilter.temperatureAndTint()
            warmTone.inputImage = summerSky.outputImage
            warmTone.neutral = CIVector(x: 6500, y: 0)  // Adjust the white balance towards warmth
            warmTone.targetNeutral = CIVector(x: 8000, y: 0)  // Make the image feel like it's bathed in warm sunlight

            // Set the final filter output
            filter = warmTone

        case .suburbia:
            // Step 1: Color controls to adjust brightness, contrast, and saturation
            let suburbia = CIFilter.colorControls()
            suburbia.inputImage = ciImage
            suburbia.brightness = -0.1  // Slightly reduce brightness to make shadows richer
            suburbia.contrast = 1.6     // Increase contrast to deepen shadows but retain detail
            suburbia.saturation = 1.4   // Boost saturation to enhance the warm tones without oversaturation

            // Step 2: Add a pinkish-red tint for the sunset glow
            let pinkTint = CIFilter.colorMonochrome()
            pinkTint.inputImage = suburbia.outputImage
            pinkTint.color = CIColor(red: 1.0, green: 0.2, blue: 0.3)  // A soft pinkish-red color for sunset hues
            pinkTint.intensity = 0.4  // Moderate intensity for subtle warmth

            // Step 3: Apply a vignette to darken the edges for a moody sunset effect
            let vignette = CIFilter.vignette()
            vignette.inputImage = pinkTint.outputImage
            vignette.intensity = 0.6   // Adjust vignette intensity to darken the edges slightly
            vignette.radius = 2.0      // Control the size of the vignette to avoid overly dark shadows

            // Set the final filter output
            filter = vignette

            
        case .none:
            return image
        }

        // Apply the filter and get the output image
        guard let outputImage = filter?.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        // Create a UIImage from the CGImage
        let filteredImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        
        return filteredImage
    }

}



#Preview {
    GalleryView()
}
