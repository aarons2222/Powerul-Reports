//
//  RatingValues.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 18/12/2024.
//

import SwiftUI

enum RatingValue: String, CaseIterable {
    case outstanding = "Outstanding"
    case good = "Good"
    case met = "Met"
    case inadequate = "Inadequate"
    case requiresImprovement = "Requires improvement"
    case notmet = "Not Met"
    case none = ""
    
    var color: Color {
        switch self {
        case .outstanding: return .color7
        case .good: return .color1
        case .met: return .color2
        case .inadequate: return .color8
        case .requiresImprovement: return .color5
        case .notmet: return .color6
        case .none: return .gray
        }
    }
}

