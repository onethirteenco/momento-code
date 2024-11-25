//
//  CameraView.swift
//  Momento
//
//  Created by Nicholas Dapolito on 8/19/24.
//

import SwiftUI
import AVFoundation // Step 1: Import AVFoundation

struct CameraView: View {
    @StateObject var camera = CameraModel()
    @State private var showingSettings: Bool = false
    @State private var showingGallery: Bool = false
    @State private var isAnimating = false

    // Step 2: Create an AVAudioPlayer instance
    @State private var audioPlayer: AVAudioPlayer?

    var body: some View {
        NavigationStack {
            ZStack {
                // Blurred Background
                BlurView(style: .dark)
                    .edgesIgnoringSafeArea(.all)

                // Camera preview
                CameraViewController(camera: camera)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .circular))
                    .edgesIgnoringSafeArea(.bottom)
                    .padding(.top, 15)

                VStack {
                    Spacer()

                    HStack(alignment: .center) {
                        Spacer()

                        // Shutter button
                        Button(action: {
                            takePhoto()
                        }) {
                            Image(systemName: "circle")
                                .font(.system(size: 72))
                                .foregroundColor(.white)
                        }

                        Spacer()
                    }
                    .padding()
                }

                // Shutter Animation Overlay
                Color.white
                    .opacity(isAnimating ? 1.0 : 0.0) // Change opacity for animation
                    .animation(.easeOut(duration: 0.1), value: isAnimating) // Animate the change
                    .edgesIgnoringSafeArea(.all)
            }
            .navigationTitle("Momento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                //MARK: FLASH BUTTON
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        camera.toggleFlashMode()
                    }) {
                        Image(systemName: flashIconName(for: camera.flashMode))
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                }
                //MARK: SETTINGS BUTTON
                ToolbarItem(placement: .principal) {
                    Button(action: {
                        showingSettings = true
                    }, label: {
                        Text("Momento")
                            .font(.title)
                            .fontDesign(.monospaced)
                            .fontWeight(.bold)
                            .tint(.primary)
                    })
                    .sheet(isPresented: $showingSettings, content: {
                        SettingsView()
                            .presentationDetents([.fraction((0.5))])
                    })
                }
                //MARK: GALLERY BUTTON
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingGallery = true
                    }, label: {
                        Image(systemName: "clock")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    })
                    .fullScreenCover(isPresented: $showingGallery, content: {
                        GalleryView()
                    })
                }
            }
            .alert(isPresented: $camera.alert) {
                Alert(title: Text("Camera Access Denied"), message: Text("Please enable camera access in settings."), dismissButton: .default(Text("OK")))
            }
        }
        .onAppear {
            // Step 3: Prepare the sound file
            prepareSound()
        }
    }

    func takePhoto() {
        // Trigger the shutter animation
        isAnimating = true
        playSound() // Step 4: Play the sound
        camera.takePhoto()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isAnimating = false
        }
    }

    func prepareSound() {
        // Step 3: Load the sound file
        if let soundURL = Bundle.main.url(forResource: "shutter", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
            } catch {
                print("Error loading sound: \(error.localizedDescription)")
            }
        }
    }

    func playSound() {
        // Step 4: Play the sound
        audioPlayer?.play()
    }

    func flashIconName(for mode: CameraModel.FlashMode) -> String {
        switch mode {
        case .on:
            return "bolt.fill"
        case .off:
            return "bolt.slash.fill"
        case .auto:
            return "bolt.badge.a"
        }
    }
}



#Preview {
    CameraView()
}
