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
    
    private var themeFrequencies: [String: Int] {
       var frequencies: [String: Int] = [:]
       let inspectorReports = reports.filter { $0.inspector == profile.name }
       
       for report in inspectorReports {
           for theme in report.themes {
               frequencies[theme.topic, default: 0] += theme.frequency
           }
       }
       return frequencies.sorted { $0.value > $1.value }
           .prefix(5)
           .reduce(into: [:]) { dict, pair in
               dict[pair.key] = pair.value
           }
    }
    
    var body: some View {
        List {
            Section(header: Text("Overview")) {
                LabeledContent("Total Inspections", value: "\(profile.totalInspections)")
            }
            
            Section(header: Text("Details")) {
                ForEach(recentReports) { report in
                    
                    
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
            
            Section(header: Text("Areas Covered")) {
                ForEach(Array(profile.areas.keys.sorted()), id: \.self) { area in
                    LabeledContent(area, value: "\(profile.areas[area] ?? 0)")
                }
            }
            
            
            Section(header: Text("Common Themes")) {
                ForEach(Array(themeFrequencies.sorted { $0.value > $1.value }), id: \.key) { theme, count in
                    HStack {
                        Text(theme)
                        Spacer()
                        Text("\(count)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            
            
            
            
            
            
            
        
            Section(header: Text("Grades")) {
                let gradeColors: [String: Color] = [
                    "Outstanding": .green,
                    "Good": .blue,
                    "Requires Improvement": .orange,
                    "Inadequate": .red
                ]
                
                Chart {
                    ForEach(Array(profile.grades.keys.sorted()), id: \.self) { grade in
                        SectorMark(
                            angle: .value("Count", profile.grades[grade] ?? 0)
                        )
                        .foregroundStyle(gradeColors[grade, default: .gray])
                        
                    }
                }
                .frame(height: 200)
                .padding()
                
                ForEach(Array(profile.grades.keys.sorted()), id: \.self) { grade in
                    LabeledContent(grade, value: "\(profile.grades[grade] ?? 0)")
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
   
        .toolbar {
            ToolbarTitleView(
                icon: "person.text.rectangle",
                title: profile.name,
                iconColor: .blue
            )
        }
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
