//
//  ShutterOverlay.swift
//  Momento
//
//  Created by Nicholas Dapolito on 8/19/24.
//

import Foundation
import SwiftUI

struct ShutterOverlay: View {
    @Binding var isAnimating: Bool

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.black.opacity(0.7))
                .frame(width: geometry.size.width, height: geometry.size.height)
                .offset(x: isAnimating ? -geometry.size.width / 2 : 0, y: isAnimating ? -geometry.size.height / 2 : 0)
                .animation(.easeInOut(duration: 0.2), value: isAnimating)
        }
        .edgesIgnoringSafeArea(.all)
    }
}


struct ShutterShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        return path
    }
}
