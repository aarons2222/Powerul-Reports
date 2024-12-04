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
            CustomHeaderVIew(
                title: "All Reports",
                showFilterButton: true,
                showFilters: Binding(
                    get: { showFilters },
                    set: { showFilters = $0 }
                )
            )
            
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                    Text("Loading Reports...")
                        .foregroundColor(.secondary)
                        .padding(.top)
                    Spacer()
                }
            } else {
                HStack(spacing: 0) {
                    SearchBar(searchText: $mainViewModel.searchText,
                             placeHolder: "Search \(viewModel.totalReportsCount) Reports...")
                }
                
                // Active Filters View
                if viewModel.hasActiveFilters {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 8) {
                            ForEach(viewModel.activeFilters, id: \.self) { filter in
                                FilterChip(text: filter.text) {
                                    withAnimation(.smooth) {
                                        viewModel.clearFilter(filter.type)
                                    }
                                }
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                                    removal: .scale(scale: 0.8).combined(with: .opacity)
                                ))
                            }
                            
                            Button {
                                withAnimation(.smooth) {
                                    viewModel.clearFilters()
                                }
                            } label: {
                                Text("Clear All")
                                    .font(.subheadline)
                                    .foregroundStyle(.red)
                            }
                            .padding(.leading, 4)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                    .frame(height: 36)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
                
                if !mainViewModel.searchText.isEmpty {
                    SearchResultsView(results: mainViewModel.searchResults.values.flatMap { $0 }, path: $path)
                } else {
                    ReportsListView(viewModel: viewModel, path: $path)
                }
            }
        }
        .keyboardAdaptive()
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onChange(of: selectedTimeFilter) {
            Task {
                viewModel.resetAndReload(timeFilter: selectedTimeFilter)
            }
        }
        .sheet(isPresented: $showFilters) {
            FilterView(viewModel: viewModel)
        }
    }
}

// MARK: - Subviews
private struct ActiveFiltersView: View {
    @ObservedObject var viewModel: AllReportsViewModel
    
    var body: some View {
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
}

private struct ReportsListView: View {
    @ObservedObject var viewModel: AllReportsViewModel
    @Binding var path: [NavigationPath]
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(viewModel.sortedDates, id: \.self) { date in
                        Section(header: DateHeaderView(date: date)) {
                            if let reports = viewModel.groupedReports[date] {
                                ForEach(reports, id: \.id) { report in
                                    ReportCardButton(report: report, path: $path)
                                        .padding(.bottom, 10)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
            .padding(.bottom)
            .background(.clear)
        }
    }
}

private struct ReportCardButton: View {
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
    
    private var ratingColor: Color {
        if let ratingValue = RatingValue(rawValue: text) {
            return ratingValue.color
        }
        return .color3
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.subheadline)
                .foregroundColor(ratingColor)
            
            Button {
                withAnimation(.smooth) {
                    onRemove()
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(ratingColor)
                    .contentTransition(.symbolEffect(.replace))
                    
                
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(ratingColor.opacity(0.1))
                .overlay(
                    Capsule()
                        .strokeBorder(ratingColor.opacity(0.2), lineWidth: 1)
                )
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
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.color4)
                Spacer()
            }
            .frame(height: 30)
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

struct AuthorityItem: Identifiable, Equatable {
    let id: String
}
