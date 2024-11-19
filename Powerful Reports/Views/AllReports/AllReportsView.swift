//
//  AllReportsView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//
import SwiftUI

struct AllReportsView: View {
    var reports: [Report]
    
    
    @AppStorage("selectedTimeFilter") private var selectedTimeFilter: TimeFilter = .last30Days

    

    var filteredReports: [Report] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        return reports.filter { report in
            guard let reportDate = dateFormatter.date(from: report.date) else { return false }
            return reportDate >= selectedTimeFilter.date
        }
    }
    
    private var groupedReports: [String: [Report]] {
        let sortedReports = filteredReports.sorted { (report1: Report, report2: Report) in
            report1.date > report2.date
        }
        return Dictionary(grouping: sortedReports) { report in
            report.date
        }
    }
    
    private var sortedDates: [String] {
        groupedReports.keys.sorted { date1, date2 in
            guard let date1 = DateFormatter.reportDate.date(from: date1),
                  let date2 = DateFormatter.reportDate.date(from: date2) else {
                return false
            }
            return date1 > date2
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                ForEach(sortedDates, id: \.self) { date in
                    Section {
                        ForEach(groupedReports[date] ?? []) { report in
                            NavigationLink(destination: ReportView(report: report)) {
                                CardView("Report: \(report.referenceNumber)") {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Inspector: \(report.inspector)")
                                        Text("Area: \(report.localAuthority)")
                                        if let overallRating = report.overallRating {
                                            Text("Rating: \(overallRating)")
                                                .foregroundColor(RatingValue(rawValue: overallRating)?.color ?? .gray)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    } header: {
                        Text(date)
                           .font(.callout)
                           .padding(.horizontal, 12)
                           .padding(.vertical, 6)
                           .background(
                               Capsule()
                                   .fill(Color.blue.opacity(0.1))
                           )
                           .frame(maxWidth: .infinity, alignment: .leading)
                           .padding(.vertical)
                    
                    }
                }
            }
            .padding(.horizontal)
        }
        .toolbar {
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Time Filter", selection: $selectedTimeFilter) {
                        Text("This Month").tag(TimeFilter.last30Days)
                        Text("Last 3 Months").tag(TimeFilter.last3Months)
                        Text("Last 6 Months").tag(TimeFilter.last6Months)
                        Text("Last 12 Months").tag(TimeFilter.last12Months)
                    }
                   
                } label: {
                    Label("Time Filter", systemImage: "calendar")
                }
            }
            
            
            ToolbarTitleView(
                icon: "text.page",
                title: "All Reports",
                iconColor: .blue
            )
        }
    }
}

extension DateFormatter {
    static let reportDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
