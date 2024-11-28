////
////  AllReportsView.swift
////  Powerful Reports
////
////  Created by Aaron Strickland on 19/11/2024.
////
///
///
///

import SwiftUI


struct AllReportsView: View {
    @StateObject var viewModel: InspectionReportsViewModel
    @AppStorage("selectedTimeFilter") private var selectedTimeFilter: TimeFilter = .last30Days
    @Binding var path: [NavigationPath]
    
    // Track scroll position
    @State private var scrollPosition: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CustomHeaderVIew(title: "All Reports")
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                        ForEach(viewModel.sortedDates, id: \.self) { date in
                            Section {
                                let reports = viewModel.groupedReports[date] ?? []
                                LazyVStack(spacing: 8) {
                                    ForEach(reports) { report in
                                        ReportCardView(report: report, path: $path)
                                            .id("\(date)-\(report.id)")
                                            .onAppear {
                                                if reports.last?.id == report.id {
                                                    viewModel.loadMoreContentIfNeeded(currentDate: date)
                                                }
                                            }
                                    }
                                }
                            } header: {
                                DateHeaderView(date: date)
                                    .id(date)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .scrollDismissesKeyboard(.immediately)
                .onChange(of: scrollPosition) { newPosition in
                    if let position = newPosition {
                        withAnimation {
                            proxy.scrollTo(position, anchor: .top)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onChange(of: selectedTimeFilter) { newFilter in
            viewModel.resetAndReload(timeFilter: newFilter)
        }
    }
}

// Extracted subviews for better organization and reusability
struct ReportCardView: View {
    let report: Report
    @Binding var path: [NavigationPath]
    
    var body: some View {
        Button {
            path.append(.reportView(report))
        } label: {
            CardView("Report: \(report.referenceNumber)") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Inspector: \(report.inspector)")
                        .lineLimit(1)
                    Text("Area: \(report.localAuthority)")
                        .lineLimit(1)
                    if let overallRating = report.overallRating {
                        Text("Rating: \(overallRating)")
                            .foregroundColor(RatingValue(rawValue: overallRating)?.color ?? .gray)
                            .lineLimit(1)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DateHeaderView: View {
    let date: String
    
    var body: some View {
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

extension DateFormatter {
    static let reportDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
