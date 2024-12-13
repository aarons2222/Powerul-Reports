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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CustomHeaderVIew(title: viewModel.profile.name)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    Color.clear.frame(height: 20)
                    
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
                        ForEach(Array(viewModel.recentReports.prefix(5))) { report in
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
                        ForEach(viewModel.areas, id: \.self) { area in
                            LabeledContent(area, value: "\(viewModel.areaCount(area))")
                        }
                    }
                    .padding(.bottom)
                    
                    CustomCardView("Popular themes") {
                        ForEach(viewModel.themeStatistics.topThemes.prefix(10), id: \.topic) { themeFreq in
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
                        .padding()
                        .monitorVisibility(chartThreeObserver)
                        
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
                    
                    GlobalButton(title: "Generate PDF Report", action: {
                        Task {
                            if let url = viewModel.generatePDF() {
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
                    })
                }
                .scrollIndicators(.hidden)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .onChange(of: chartThreeObserver.isVisible) { _, isVisible in
            if isVisible {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animationAmount = 1.0
                }
            } else {
                animationAmount = 0
            }
        }
    }
}
