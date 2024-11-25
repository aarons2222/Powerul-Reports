//
//  AllReportsView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 24/11/2024.
//

import SwiftUI

struct MoreReportsView: View {
    let reports: [Report]
    let name: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
         
            
            CustomHeaderVIew(title: "All reports for \(name)")
            
            List{
            ForEach(Array(reports)) { report in
                
                
                    
                    NavigationLink {
                        ReportView(report: report)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(report.referenceNumber)
                                .font(.headline)
                            Text(report.date)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text(report.overallRating ?? report.outcome)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    
                }
            }
            .scrollIndicators(.hidden)
            
        }
      
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}

