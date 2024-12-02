//
//  ReportView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//

import SwiftUI

struct ReportView: View {
    var report: Report
    @State private var selectedTheme: String?
    @Environment(\.colorScheme) var colorScheme
    
    init(report: Report) {
        self.report = report
        print("ReportView \(report.referenceNumber)")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CustomHeaderVIew(title: report.referenceNumber)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Report Information Card
                    CardView("Report Information") {
                        VStack(alignment: .leading, spacing: 16) {
                            InfoRow(icon: "number.circle.fill", title: "Reference", value: report.referenceNumber)
                            InfoRow(icon: "person.fill", title: "Inspector", value: report.inspector)
                            InfoRow(icon: "calendar", title: "Date", value: report.formattedDate)
                            InfoRow(icon: "building.2.fill", title: "Local Authority", value: report.localAuthority)
                            InfoRow(icon: "house.fill", title: "Type", value: report.typeOfProvision)
                            
                            if (!report.previousInspection.contains("Not applicable")) {
                                InfoRow(icon: "clock.fill", title: "Previous Inspection", value: report.previousInspection.replacingOccurrences(of: "inspection ", with: "" ))
                                   
                            }
                        }
                    }
                    
                    // Grade Card
                    CardView("Grade") {
                        VStack(alignment: .leading, spacing: 12) {
                            if (!report.outcome.isEmpty) {
                                HStack {
                                    Text("Outcome")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(report.outcome)
                                        .fontWeight(.medium)
                                }
                            } else {
                                ForEach(report.ratings, id: \.category) { rating in
                                    HStack {
                                        Text(rating.category)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(rating.rating)
                                            .fontWeight(.medium)
                                            .foregroundStyle(RatingValue(rawValue: rating.rating)?.color ?? .gray)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Themes Card
                    CardView("Themes") {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 150), spacing: 12)
                        ], spacing: 12) {
                            ForEach(report.sortedThemes, id: \.topic) { theme in
                                Button {
                                    withAnimation(.spring()) {
                                        selectedTheme = selectedTheme == theme.topic ? nil : theme.topic
                                    }
                                } label: {
                                    Text(theme.topic)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(selectedTheme == theme.topic ? .white : .color1)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedTheme == theme.topic ? Color.color1 : Color.color1.opacity(0.1))
                                        }
                                        .contentShape(Rectangle())
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
        }
    }
}
