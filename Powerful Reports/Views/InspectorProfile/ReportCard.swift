//
//  ReportCard.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 27/11/2024.
//

import SwiftUI

struct ReportCard: View {
    
    var report: Report
    var showInspector: Bool
    
    var body: some View {
        
        
        HStack{
            
            VStack(alignment: .leading, spacing: 4) {
                
                Text(report.referenceNumber)
                    .font(.headline)
                    .foregroundStyle(.color4)
                
                Text(report.date)
                    .font(.body)
                    .foregroundColor(.gray)
                
                if showInspector{
                    Text(report.inspector)
                        .font(.body)
                        .foregroundColor(.gray)
                    
                }
                
                
                HStack{
                    
                    Image(systemName: "largecircle.fill.circle")
                        .font(.body)
                        .foregroundColor(RatingValue(rawValue: report.overallRating ?? report.outcome)?.color ?? .secondary)
                    
                    
                    Text(report.overallRating ?? report.outcome)
                        .font(.body)
                        .foregroundColor(.color4)
                }
            }
            
            Spacer()
            Image(systemName: "chevron.right.circle")
                .font(.title2)
                .foregroundColor(.color1)
        }
        .padding()
        .cardBackground()

    }
}


//struct ReportCard: View {
//    var report: Report
//    
//    var body: some View {
//        HStack {
//            VStack(alignment: .leading, spacing: 4) {
//                Text(report.referenceNumber)
//                    .font(.headline)
//                    .foregroundStyle(.color4)
//                
//                Text(report.date)
//                    .font(.body)
//                    .foregroundColor(.gray)
//                
//                HStack {
//                    Image(systemName: "largecircle.fill.circle")
//                        .font(.body)
//                        .foregroundColor(RatingValue(rawValue: report.overallRating ?? report.outcome)?.color ?? .secondary)
//                    
//                    Text(report.overallRating ?? report.outcome)
//                        .font(.body)
//                        .foregroundColor(.color4)
//                }
//            }
//            
//            Spacer()
//            Image(systemName: "chevron.right.circle")
//                .font(.title2)
//                .foregroundColor(.color1)
//        }
//        .padding()
//        .cardBackground()
//    }
//}
