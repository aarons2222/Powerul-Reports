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
    @Binding var path: [NavigationPath]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CustomHeaderVIew(title: "All reports for \(name)")
            
            ScrollView {
                ForEach(Array(reports)) { report in
                    Button {
                        path.append(.reportView(report))
                    } label: {
                        ReportCard(report: report, showInspector: false)
                    }
                    .padding(.vertical, 4)
                    
                    if report != reports.last {
                        Divider()
                    }
                }
            }
            .scrollIndicators(.hidden)
            .padding()
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}
