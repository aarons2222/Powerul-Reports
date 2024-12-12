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
    let reports: [Report]
    @Binding var path: [NavigationPath]
    
    private var recentReports: [Report] {
       Array(reports
           .filter { $0.inspector == profile.name }
           .sorted { report1, report2 in
               let dateFormatter = DateFormatter()
               dateFormatter.dateFormat = "dd/MM/yyyy"
               
               let date1 = dateFormatter.date(from: report1.date) ?? Date.distantPast
               let date2 = dateFormatter.date(from: report2.date) ?? Date.distantPast
               
               return date1 > date2
           })
    }
    
    init(profile: InspectorProfile, reports: [Report], path: Binding<[NavigationPath]>) {
        self.profile = profile
        self.reports = reports
        self._path = path
        print("Logger: InspectorProfileView")
    }
    
    var body: some View {
        let statistics = ThemeAnalyzer.getInspectorThemeStatistics(from: reports, for: profile.name)
        
        VStack(alignment: .leading, spacing: 0) {
            CustomHeaderVIew(title: profile.name)
            
            ScrollView {
                Color.clear.frame(height: 20)
                
                CustomCardView("Recent Reports",
                         navigationLink: recentReports.count > 5 ?
                         AnyView(
                            Button(action: {
                                path.append(.moreReports(recentReports, profile.name))
                            }) {
                                Image(systemName: "plus.circle")
                                    .font(.title2)
                                    .foregroundColor(.color1)
                            }
                         ) : nil) {
                    ForEach(Array(recentReports.prefix(5))) { report in
                        Button {
                            path.append(.reportView(report))
                        } label: {
                            ReportCard(report: report, showInspector: false)
                        }
                        .padding(.vertical, 4)
                        
                    }
                }
                .padding(.bottom)
                
                CustomCardView("Local Authorities Inspected") {
                    ForEach(Array(profile.areas.keys.sorted()), id: \.self) { area in
                        LabeledContent(area, value: "\(profile.areas[area] ?? 0)")
                    }
                }
                .padding(.bottom)
                
                CustomCardView("Popular themes") {
                    ForEach(statistics.topThemes.prefix(10), id: \.topic) { themeFreq in
                        HStack {
                            Text(themeFreq.topic)
                            Spacer()
                            Text("\(themeFreq.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.bottom)
                
                CustomCardView("Outcomes") {
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
                    
                    ForEach(profile.grades.sorted(by: { $0.value > $1.value }), id: \.key) { grade, count in
                        if grade != "empty" {
                            HStack {
                                Image(systemName: "largecircle.fill.circle")
                                    .font(.body)
                                    .foregroundStyle(RatingValue(rawValue: grade)?.color ?? .gray)
                                Text(grade.capitalized)
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
                
                GlobalButton(title: "Generate PDF Report", action: {
                    Task {
                        generatePDF()
                    }
                })
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal)
            .padding(.bottom)
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
