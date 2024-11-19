//
//  ReportView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//

import SwiftUI

struct ReportView: View {
    var report: Report
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                CardView("Report Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        
                        Text("Reference: \(report.referenceNumber)")
                        Text("Inspector: \(report.inspector)")
                        Text("Date: \(report.formattedDate)")
                        Text("Local Authority: \(report.localAuthority)")
                        Text("Type: \(report.typeOfProvision)")
                        
                        if (!report.previousInspection.contains("Not applicable")){
                            Text("Previous: \(report.previousInspection)")
                        }
                    }
                }
                
                CardView("Grade") {
                    if (!report.outcome.isEmpty) {
                        Text("Outcome: \(report.outcome)")
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(report.ratings, id: \.category) { rating in
                                HStack {
                                    Text(rating.category)
                                    Spacer()
                                    Text(rating.rating)
                                        .foregroundColor(RatingValue(rawValue: rating.rating)?.color ?? .gray)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                
                CardView("Themes") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(report.sortedThemes, id: \.topic) { theme in
                            Text(theme.topic)
                                .padding(.vertical, 2)
                        }
                    }
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarTitleView(
                icon: "text.page",
                title: "Report Information",
                iconColor: .blue
            )
        }
    }
}

struct CardView<Content: View>: View {
    let title: String
    let content: Content
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 5)
            
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
