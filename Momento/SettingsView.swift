//
//  SettingsView.swift
//  Momento
//
//  Created by Nicholas Dapolito on 8/19/24.
//

import SwiftUI

struct SettingsView: View {
    @State private var postProcessing: Bool = UserDefaults.standard.bool(forKey: "postProcessing")
    @State private var darkMode: Bool = true
    @State private var showingAppInfo: Bool = false
    @State private var enableGridOverlay: Bool = UserDefaults.standard.bool(forKey: "gridOverlay")
    @State private var enableLocationTagging: Bool = UserDefaults.standard.bool(forKey: "locationTagging")
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Capture")) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Toggle("Post_processing", isOn: $postProcessing)
                            .onChange(of: postProcessing) { newValue in
                                UserDefaults.standard.set(newValue, forKey: "postProcessing")
                            }
                    }
                    HStack {
                        Image(systemName: "square.grid.3x3.fill")
                        Toggle("Grid Overlay", isOn: $enableGridOverlay)
                            .onChange(of: enableGridOverlay) { newValue in
                                UserDefaults.standard.set(newValue, forKey: "gridOverlay")
                            }
                    }
                    HStack {
                        Image(systemName: "location.fill")
                        Toggle("Location Tagging", isOn: $enableLocationTagging)
                            .onChange(of: enableLocationTagging) { newValue in
                                UserDefaults.standard.set(newValue, forKey: "locationTagging")
                            }
                    }
                    HStack {
                        Image(systemName: "sdcard.fill")
                        Text("Format_options")
                    }
                }
                Section(header: Text("Visual")) {
                    HStack {
                        Image(systemName: "circle.lefthalf.filled.inverse")
                        Toggle(isOn: $darkMode, label: {
                            Text("Dark_mode")
                        })
                    }
                    HStack {
                        Image(systemName: "app.dashed")
                        Text("App_icon")
                    }
                }
                Section(header: Text("Other")) {
                    Button(action: {
                        showingAppInfo = true
                    }, label: {
                        HStack {
                            Image(systemName: "info.square.fill")
                            Text("App_information")
                        }
                        .tint(Color.primary)
                    })
                    .sheet(isPresented: $showingAppInfo) {
                        AppInfoView()
                            .presentationDetents([.fraction(0.2)])
                    }
                }
            }
            .navigationTitle("Settings").fontDesign(.monospaced)
        }
    }
}

#Preview {
    ContentView()
}
