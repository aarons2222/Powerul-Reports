//
//  OutcomeData.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 11/12/2024.
//

import SwiftUI

struct OutcomeData: Identifiable, Equatable {
    let id = UUID()
    let outcome: String
    let count: Int
    let color: Color
    var isAnimated: Bool = false
    
    static func == (lhs: OutcomeData, rhs: OutcomeData) -> Bool {
        return lhs.outcome == rhs.outcome &&
               lhs.count == rhs.count
    }
}
