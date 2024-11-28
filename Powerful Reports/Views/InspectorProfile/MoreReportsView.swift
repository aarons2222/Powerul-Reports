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
            
            ScrollView{
                
            ForEach(Array(reports)) { report in
                
                
                    
                    NavigationLink {
                        ReportView(report: report)
                        
                   
                    } label: {
                        
                        ReportCard(report: report)
                    
                    }
                    .padding(.vertical, 4)
                    
                if report != reports.last {
                    Divider()
                }
            }
                
            }
            .scrollIndicators(.hidden)
            
        }
      
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}

