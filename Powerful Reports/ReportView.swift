//
//  ReportView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//

import SwiftUI

struct ReportView: View {
    var report: Report
    
    init(report: Report) {
        self.report = report
        
        print("ReportView \(report.referenceNumber)")
    }
    var body: some View {
        

     
            
            VStack(spacing: 0) {
                
                
                CustomHeaderVIew(title: report.referenceNumber)
                
                ScrollView {
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
                    .padding(.bottom)
                    
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
                                    .padding(.bottom, 4)
                                }
                            }
                        }
                    }
                    .padding(.bottom)
                    
                    CardView("Themes") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(report.sortedThemes, id: \.topic) { theme in
                                Text(theme.topic)
                                    .padding(.vertical, 2)
                            }
                        }
                    }
                    .padding(.bottom)
                }
                .scrollIndicators(.hidden)
                .padding()
                
                
                
            }
        
            .ignoresSafeArea()
            .navigationBarHidden(true)
    }
}




struct CardView<Content: View>: View {
    let title: String
    let content: Content
    let navigationLink: AnyView?
    
    init(_ title: String,
         navigationLink: AnyView? = nil,
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
        self.navigationLink = navigationLink
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.regular)
                    .foregroundColor(.color4)
                Spacer()
                
                if let nav = navigationLink {
                    nav
                }
            }
            .padding(.bottom, 20)
            
            content
        }
        .padding()
        .cardBackground()
    }
}
