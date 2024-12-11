//
//  Theme.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 11/12/2024.
//


// Model for themes identified in the inspection
struct Theme: Codable, Hashable {
    let frequency: Int
    let topic: String
}
