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
import Combine

struct AllReportsView: View {
    @StateObject private var viewModel: AllReportsViewModel
    @ObservedObject var mainViewModel: InspectionReportsViewModel
    @AppStorage("selectedTimeFilter") private var selectedTimeFilter: TimeFilter = .last3Months
    @Binding var path: [NavigationPath]
    @State private var showFilters = false
    
    init(mainViewModel: InspectionReportsViewModel, path: Binding<[NavigationPath]>) {
        self.mainViewModel = mainViewModel
        self._path = path
        self._viewModel = StateObject(wrappedValue: AllReportsViewModel(mainViewModel: mainViewModel))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CustomHeaderVIew(title: "All Reports")
            
            ZStack {
                SearchBar(searchText: $mainViewModel.searchText,
                         placeHolder: "Search \(Set(mainViewModel.reports.map { $0.referenceNumber }).count) Reports...")
                
                HStack {
                    Spacer()
                    Button {
                        showFilters.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.color2)
                            .font(.title2)
                    }
                    .padding(.trailing, 8)
                }
            }
            
            // Active Filters View
            if viewModel.hasActiveFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if let inspector = viewModel.selectedInspector {
                            FilterChip(text: inspector) {
                                viewModel.selectedInspector = nil
                                viewModel.updateFilters()
                            }
                        }
                        
                        if let authority = viewModel.selectedAuthority {
                            FilterChip(text: authority) {
                                viewModel.selectedAuthority = nil
                                viewModel.updateFilters()
                            }
                        }
                        
                        if let type = viewModel.selectedProvisionType {
                            FilterChip(text: type) {
                                viewModel.selectedProvisionType = nil
                                viewModel.updateFilters()
                            }
                        }
                        
                        if let rating = viewModel.selectedRating {
                            FilterChip(text: rating) {
                                viewModel.selectedRating = nil
                                viewModel.updateFilters()
                            }
                        }
                        
                        if let outcome = viewModel.selectedOutcome {
                            FilterChip(text: outcome) {
                                viewModel.selectedOutcome = nil
                                viewModel.updateFilters()
                            }
                        }
                        
                        Button("Clear All") {
                            viewModel.clearFilters()
                        }
                        .foregroundColor(.red)
                        .padding(.leading, 8)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
            
            if !mainViewModel.searchText.isEmpty {
                SearchResultsView(results: mainViewModel.searchResults.values.flatMap { $0 }, path: $path)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                            ForEach(viewModel.sortedDates, id: \.self) { date in
                                Section(header: DateHeaderView(date: date)) {
                                    ForEach(viewModel.groupedReports[date] ?? [], id: \.id) { report in
                                        Button {
                                            path.append(.reportView(report))
                                        } label: {
                                            ReportCard(report: report, showInspector: true)

                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onChange(of: selectedTimeFilter) {
            mainViewModel.resetAndReload(timeFilter: selectedTimeFilter)
        }
        .sheet(isPresented: $showFilters) {
            FilterView(viewModel: viewModel)
        }
    }
}

struct FilterView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: AllReportsViewModel
    
    var body: some View {
     
        ScrollView {
            CardView("Grade/Outcome") {
                    Picker("Select Inspector", selection: $viewModel.selectedInspector) {
                        Text("Any").tag(Optional<String>.none)
                        ForEach(viewModel.availableInspectors, id: \.self) { inspector in
                            Text(inspector).tag(Optional(inspector))
                        }
                    }
                }
            .padding(.bottom)
                
            CardView("Grade/Outcome") {
                    Picker("Select Authority", selection: $viewModel.selectedAuthority) {
                        Text("Any").tag(Optional<String>.none)
                        ForEach(viewModel.availableAuthorities, id: \.self) { authority in
                            Text(authority).tag(Optional(authority))
                        }
                    }
                }
            .padding(.bottom)
                
           
           CardView("Provision Type") {
                    Picker("Select Type", selection: $viewModel.selectedProvisionType) {
                        Text("Any").tag(Optional<String>.none)
                        ForEach(viewModel.availableProvisionTypes, id: \.self) { type in
                            Text(type).tag(Optional(type))
                        }
                    }
                }
                .padding(.bottom)
                
            CardView("Grade/Outcome") {
                    RatingGrid(selectedRating: Binding(
                        get: {
                            if let rating = viewModel.selectedRating {
                                return RatingValue(rawValue: rating) ?? .none
                            } else if let outcome = viewModel.selectedOutcome {
                                return RatingValue(rawValue: outcome) ?? .none
                            }
                            return .none
                        },
                        set: { newValue in
                            // Clear both first
                            viewModel.selectedRating = nil
                            viewModel.selectedOutcome = nil
                            
                            // Then set the appropriate one based on the rating value
                            let value = newValue.rawValue
                            if ["Met", "Not met"].contains(value) {
                                viewModel.selectedOutcome = value
                            } else {
                                viewModel.selectedRating = value
                            }
                        }
                    ))
                }
            
            
            
            GlobalButton(title: "See Reports"){
                
            }
            }
            .padding()
           
        }
    }

// An enum for possible rating values
enum RatingValue: String, CaseIterable {
    case outstanding = "Outstanding"
    case good = "Good"
    case met = "Met"
    case inadequate = "Inadequate"
    case requiresImprovement = "Requires improvement"
    case notmet = "Not Met"
    case none = ""
    
    var color: Color {
        switch self {
        case .outstanding: return .color7
        case .good: return .color1
        case .met: return .color2
        case .inadequate: return .color8
        case .requiresImprovement: return .color5
        case .notmet: return .color6
        case .none: return .gray
        }
    }
}



struct FilterChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Text(text)
                .font(.subheadline)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.gray.opacity(0.1))
        )
    }
}

struct SearchResultsView: View {
    let results: [Report]
    @Binding var path: [NavigationPath]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(results) { report in
                    ReportCardView(report: report, path: $path)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ReportCardView: View {
    let report: Report
    @Binding var path: [NavigationPath]
    
    var body: some View {
        Button {
            path.append(.reportView(report))
        } label: {
            ReportCard(report: report, showInspector: true)
        }
        .buttonStyle(.plain)
    }
}



struct DateHeaderView: View {
    let date: String
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                Text("\(date)")
                    .font(.title3)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.color4)
                Spacer()
            }
            .frame(height: 40)
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




#Preview{
    FilterView(viewModel: AllReportsViewModel(mainViewModel: InspectionReportsViewModel()))
}



struct RatingGrid: View {
    @Binding var selectedRating: RatingValue
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) { // Reduce vertical spacing
            ForEach(Array(RatingValue.allCases.filter { $0 != .none }), id: \.self) { rating in
                VStack(spacing: 4) { // Reduce spacing between circle and text
                    CircleButton(color: rating.color,
                               isSelected: selectedRating == rating,
                               size: 50) // Reduce circle size
                        .onTapGesture {
                            selectedRating = rating
                        }
                    
                    Text(rating.rawValue.capitalized)
                        .foregroundStyle(rating.color)
                        .font(.caption2) // Use smaller font
                        .minimumScaleFactor(0.8) // Allow text to scale down if needed
                        .lineLimit(1) // Ensure single line
                }
            }
        }

    }
}
struct CircleButton: View {
    var color: Color
    var isSelected: Bool
    var size: CGFloat
    
    private var innerCircleSize: CGFloat { size * 0.75 }  // Inner circle is 75% of outer
    private var strokeWidth: CGFloat { size * 0.1 }       // Stroke is 10% of size
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color, lineWidth: isSelected ? strokeWidth : 0)
                .frame(width: size, height: size)
            Circle()
                .foregroundStyle(color)
                .frame(width: innerCircleSize, height: innerCircleSize)
        }
    }
}

