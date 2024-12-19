//
//  InspectorProfileView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//

import SwiftUI
import Charts

struct InspectorProfileView: View {
    @StateObject private var viewModel: InspectorProfileViewModel
    @Binding var path: [NavigationPath]
    @StateObject private var chartThreeObserver = VisibilityObserver(id: "chart3")
    @State private var animationAmount: CGFloat = 0
    
    init(profile: InspectorProfile, reports: [Report], path: Binding<[NavigationPath]>) {
        self._viewModel = StateObject(wrappedValue: InspectorProfileViewModel(profile: profile, reports: reports))
        self._path = path
    }
    
    private var recentReportsSection: some View {
        CustomCardView("Recent Reports",
            navigationLink: viewModel.recentReports.count > 5 ?
            AnyView(
                Button(action: {
                    path.append(.moreReports(viewModel.recentReports, viewModel.profile.name))
                }) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundColor(.color1)
                }
            ) : nil) {
            LazyVStack(spacing: 4) {
                ForEach(Array(viewModel.recentReports.prefix(5))) { report in
                    Button {
                        path.append(.reportView(report))
                    } label: {
                        ReportCard(report: report, showInspector: false)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(.bottom)
    }
    
    private var themeAnalyticsSection: some View {
        Group {
            if viewModel.isLoadingThemes {
                CustomCardView("Themes") {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.bottom)
            } else if let analytics = viewModel.themeAnalytics {
                NavigationLink(destination:
                    InspectorThemeAnalyticsView(analytics: analytics, inspectorName: viewModel.profile.name)
                ) {
                    CustomCardView("Themes",
                        navigationLink: AnyView(
                            Image(systemName: "chevron.right.circle")
                                .font(.title2)
                                .foregroundColor(.color1)
                        )) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(Int(viewModel.recentReports.count))")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.color1)
                                    Text("View more details")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom)
            }
        }
    }
    
    private var localAuthoritiesSection: some View {
        CustomCardView("Local Authorities Inspected") {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.areas, id: \.self) { area in
                    LabeledContent(area, value: "\(viewModel.areaCount(area))")
                }
            }
        }
        .padding(.bottom)
    }
    
    private var outcomesSection: some View {
        CustomCardView("Outcomes") {
            if viewModel.sortedGrades.isEmpty {
                Text("No data available")
                    .font(.body)
                    .foregroundColor(.secondary)
            } else {
                Chart {
                    ForEach(viewModel.sortedGrades, id: \.key) { grade, count in
                        SectorMark(
                            angle: .value("Count", CGFloat(count) * animationAmount),
                            angularInset: 1
                        )
                        .cornerRadius(5)
                        .foregroundStyle(RatingValue(rawValue: grade)?.color ?? .gray)
                    }
                }
                .frame(height: 200)
                .chartLegend(position: .bottom, spacing: 20)
                .chartBackground { chartProxy in
                    GeometryReader { geometry in
                        if let plotFrame = chartProxy.plotFrame {
                            let frame = geometry[plotFrame]
                            VStack {
                                Text("\(viewModel.totalInspections)")
                                    .font(.title2)
                                    .bold()
                                Text("Total")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .position(x: frame.midX, y: frame.midY)
                        }
                    }
                }
                .monitorVisibility(chartThreeObserver)
                
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.sortedGrades, id: \.key) { grade, count in
                        if grade != "empty" {
                            HStack {
                                Image(systemName: "largecircle.fill.circle")
                                    .font(.body)
                                    .foregroundStyle(RatingValue(rawValue: grade)?.color ?? .gray)
                                Text(grade.capitalized)
                                    .font(.body)
                                    .foregroundColor(.color4)
                                Spacer()
                                Text("\(viewModel.calculatePercentage(count))%")
                                    .font(.body)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
        }
        .padding(.bottom)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CustomHeaderVIew(title: viewModel.profile.name)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    Color.clear.frame(height: 20)
                    
                    recentReportsSection
                    themeAnalyticsSection
                    localAuthoritiesSection
                    outcomesSection
                }
                .scrollIndicators(.hidden)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .task {
            await viewModel.loadThemeAnalytics()
        }
        .onChange(of: chartThreeObserver.isVisible) { _, isVisible in
            if isVisible {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animationAmount = 1.0
                }
            }
        }
    }
}
