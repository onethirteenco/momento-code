//
//  CameraState.swift
//  Momento
//
//  Created by Nicholas Dapolito on 11/24/24.
//

import Foundation

enum CameraState: Equatable {
    case setup
    case ready
    case capturing
    case processing
    case saving
    case error(String)
    
    // Implement Equatable for the error case
    static func == (lhs: CameraState, rhs: CameraState) -> Bool {
        switch (lhs, rhs) {
        case (.setup, .setup),
             (.ready, .ready),
             (.capturing, .capturing),
             (.processing, .processing),
             (.saving, .saving):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}
