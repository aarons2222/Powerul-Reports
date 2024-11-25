//
//  InspectorProfileView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//

import SwiftUI
import Charts

struct InspectorProfileView: View {
    let profile: InspectorProfile
    let reports: [Report]  // Add reports parameter
    
    


    
    private var recentReports: [Report] {
       Array(reports
           .filter { $0.inspector == profile.name }
           .sorted { report1, report2 in
               let dateFormatter = DateFormatter()
               dateFormatter.dateFormat = "dd/MM/yyyy"
               
               let date1 = dateFormatter.date(from: report1.date) ?? Date.distantPast
               let date2 = dateFormatter.date(from: report2.date) ?? Date.distantPast
               
               return date1 > date2
           }
           .prefix(10))
    }
    

    
    
    
    init(profile: InspectorProfile, reports: [Report]){
        self.profile = profile
        self.reports = reports
        print("Logger: AllInspectors")

    }
    
    
    var body: some View {
        
        let statistics = ThemeAnalyzer.getInspectorThemeStatistics(from: reports, for: profile.name)
        
        VStack(alignment: .leading, spacing: 0) {
            
            CustomHeaderVIew(title: profile.name)
            
            List {
                
                Section(header: Text("Overview")) {
                    LabeledContent("Total Inspections", value: "\(profile.totalInspections)")
                }
                
                
                
                
                Section {
                             
                    
                    ForEach(Array(recentReports.prefix(5))) { report in
                        
                        
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
                       } header: {

                                  Text("Recent Reviews")
                            } footer: {

                                HStack{
                                    Spacer()
                                    if (recentReports.count > 5){
                                        NavigationLink {
                                            MoreReportsView(reports: recentReports, name: profile.name)
                                        } label: {
                                            Text("See all reports")
                                        }
                                    }
                                }
                        }
                
                
             
                
       
                Section(header: Text("Areas Covered")) {
                    ForEach(Array(profile.areas.keys.sorted()), id: \.self) { area in
                        LabeledContent(area, value: "\(profile.areas[area] ?? 0)")
                    }
                }
                
                
                ForEach(statistics.topThemes.prefix(10), id: \.topic) { themeFreq in
                       HStack {
                           Text(themeFreq.topic)
                           Spacer()
                           Text("\(themeFreq.count)")
                               .foregroundColor(.secondary)
                     
                       }
                   }
                
                
                
                
                
                
                /// totdo
                
                Section(header: Text("Grades")) {
                    Chart {
                        ForEach(Array(profile.grades), id: \.key) { grade, count in
                            SectorMark(
                                angle: .value("Count", count),
                                angularInset: 1
                            )
                            .cornerRadius(5)
                            .foregroundStyle(RatingValue(rawValue: grade)?.color ?? .gray)
                        }
                    }
                    .frame(height: 200)
                    .padding()
                    
                    ForEach(profile.grades.sorted(by: { $0.key < $1.key }), id: \.key) { grade, count in
                        if grade != "empty" {
                            HStack {
                                Image(systemName: "largecircle.fill.circle")
                                    .font(.body)
                                    .foregroundStyle(RatingValue(rawValue: grade)?.color ?? .gray)
                                Text(grade)
                                    .font(.body)
                                    .foregroundColor(.color4)
                                Spacer()
                                Text("\(calculatePercentage(count))%")
                                    .font(.body)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                
                
                
                Button(action: {
                    generatePDF()
                }) {
                    HStack {
                        Image(systemName: "doc.fill")
                        Text("Generate PDF Report")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                .padding()
                
                
            }
            
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        
        
       
    }
    
    func calculatePercentage(_ count: Int) -> Int {
         guard profile.totalInspections > 0 else { return 0 }
         return Int(round(Double(count) / Double(profile.totalInspections) * 100))
    }
    
    
    
    private func generatePDF() {
        let renderer = PDFRenderer(profile: profile, reports: reports)
        guard let url = renderer.renderPDF() else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}




import UIKit
import PDFKit

class PDFRenderer {
    let profile: InspectorProfile
    let reports: [Report]
    
    init(profile: InspectorProfile, reports: [Report]) {
        self.profile = profile
        self.reports = reports
    }
    
    func renderPDF() -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let outputFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(profile.name)_report.pdf")
        
        do {
            try renderer.writePDF(to: outputFileURL) { context in
                context.beginPage()
                
                // Load and draw image from assets
                if let logoImage = UIImage(named: "logos", in: .main, with: nil) {
                    let imageSize = logoImage.size
                    let scaledWidth: CGFloat = 100
                    let scaledHeight = (imageSize.height * scaledWidth) / imageSize.width
                    let imageRect = CGRect(x: pageRect.width - 150, y: 50, width: scaledWidth, height: scaledHeight)
                    
                    // Draw image maintaining aspect ratio
                    logoImage.draw(in: imageRect)
                    
                    // Start content below the logo height
                    let contentStartY = imageRect.maxY + 20
                    
                    let titleAttributes = [
                        NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)
                    ]
                    
                    let text = "Inspector Profile: \(profile.name)"
                    text.draw(at: CGPoint(x: 50, y: contentStartY), withAttributes: titleAttributes)
                    
                    let totalInspections = "Total Inspections: \(profile.totalInspections)"
                    totalInspections.draw(at: CGPoint(x: 50, y: contentStartY + 40), withAttributes: [
                        .font: UIFont.systemFont(ofSize: 14)
                    ])
                }
            }
            return outputFileURL
        } catch {
            print("Failed to create PDF: \(error)")
            return nil
        }
    }
}

