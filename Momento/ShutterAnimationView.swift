//
//  ShutterAnimationView.swift
//  Momento
//
//  Created by Nicholas Dapolito on 8/19/24.
//

import Foundation
import SwiftUI

struct ShutterAnimationView: View {
    @Binding var isAnimating: Bool

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.black.opacity(0.6))
                .frame(width: isAnimating ? geometry.size.width : 0, height: geometry.size.height)
                .offset(x: isAnimating ? -geometry.size.width : 0)
                .animation(.easeInOut(duration: 0.2), value: isAnimating)
        }
        .edgesIgnoringSafeArea(.all)
    }
}

