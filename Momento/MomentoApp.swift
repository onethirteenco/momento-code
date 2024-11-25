//
//  MomentoApp.swift
//  Momento
//
//  Created by Nicholas Dapolito on 8/19/24.
//

import SwiftUI

@main
struct MomentoApp: App {
    init() {
        let largeTitle = UIFont.monospacedSystemFont(ofSize: 25, weight: .bold)
        let title = UIFont.monospacedSystemFont(ofSize: 20, weight: .bold)
        
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: largeTitle
        ]
        UINavigationBar.appearance().titleTextAttributes = [
            .font: title
        ]
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
