//
//  HapticService.swift
//  Momento
//
//  Created by Nicholas Dapolito on 11/24/24.
//

import Foundation
import SwiftUI

class HapticService {
    static func trigger(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}
