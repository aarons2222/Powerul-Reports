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
    @State private var navigateToOfsted: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    init(report: Report) {
        self.report = report
        print("ReportView \(report.referenceNumber)")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CustomHeaderVIew(title: report.referenceNumber)
                .padding(0)
            
            ScrollView {
                Color.clear.frame(height: 20)
                VStack(spacing: 20) {
                    // Report Information Card
                    CustomCardView("Report Information") {
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
                    CustomCardView("Grade") {
                        VStack(alignment: .leading, spacing: 12) {
                            if (!report.outcome.isEmpty) {
                                HStack {
                                    Text("Outcome")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(report.outcome)
                                        .fontWeight(.medium)
                                        .foregroundStyle(RatingValue(rawValue: report.outcome)?.color ?? .gray)
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
                    CustomCardView("Themes") {
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
   
                
                GlobalButton(title: "View Full Report") {
                    navigateToOfsted = true
                }
                .padding(.bottom, 50)
          
            }
            .scrollIndicators(.hidden)
            .padding()
            
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToOfsted) {
            OfstedView(URN: report.referenceNumber)
        }
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







struct OfstedView: View {
    @State private var isLoading = false
    @State private var showingDetail = false
    @State private var selectedURL: URL?
    
    var URN: String
    var body: some View {
        VStack(spacing: 0) {
            CustomHeaderVIew(title: URN)
        ZStack {
            
       
                OfstedWebView(
                    searchText:URN,
                    isLoading: $isLoading
                )
        
            
         
            if isLoading {
                OffestedLoadingView()
            }
        }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}


struct OffestedLoadingView: View {
    @State private var magnifyingGlassPosition = CGSize.zero
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.color0, .color1, .color2]),
                          startPoint: .top,
                          endPoint: .bottom)
            
            VStack(spacing: 20) {
                ZStack {
                    // Static clipboard
                    Image(systemName: "chart.line.text.clipboard")
                        .font(.system(size: 100))
                        .foregroundColor(.white)
                        .opacity(0.8)
                    
                    // Moving magnifying glass
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.color2)
                        .offset(x: magnifyingGlassPosition.width, y: magnifyingGlassPosition.height)
                }
                .frame(width: 120, height: 120)
                
                Text("Loading Ofsted website")
                    .foregroundColor(.white)
                    .opacity(isPulsing ? 0.6 : 1)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Animate magnifying glass movement
            withAnimation(
                .easeInOut(duration: 2)
                .repeatForever(autoreverses: true)
            ) {
                // Move in a scanning pattern
                magnifyingGlassPosition = CGSize(width: 30, height: 20)
            }
            
            // Pulse the loading text
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }
}
