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
    @AppStorage("selectedTimeFilter") private var selectedTimeFilter: TimeFilter = .last30Days
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
        NavigationView {
            List {
                Section("Inspector") {
                    Picker("Select Inspector", selection: $viewModel.selectedInspector) {
                        Text("Any").tag(Optional<String>.none)
                        ForEach(viewModel.availableInspectors, id: \.self) { inspector in
                            Text(inspector).tag(Optional(inspector))
                        }
                    }
                }
                
                Section("Local Authority") {
                    Picker("Select Authority", selection: $viewModel.selectedAuthority) {
                        Text("Any").tag(Optional<String>.none)
                        ForEach(viewModel.availableAuthorities, id: \.self) { authority in
                            Text(authority).tag(Optional(authority))
                        }
                    }
                }
                
                Section("Provision Type") {
                    Picker("Select Type", selection: $viewModel.selectedProvisionType) {
                        Text("Any").tag(Optional<String>.none)
                        ForEach(viewModel.availableProvisionTypes, id: \.self) { type in
                            Text(type).tag(Optional(type))
                        }
                    }
                }
                
                Section("Grade/Outcome") {
                    Picker("Select Grade/Outcome", selection: Binding(
                        get: {
                            viewModel.selectedRating ?? viewModel.selectedOutcome
                        },
                        set: { newValue in
                            // Clear both first
                            viewModel.selectedRating = nil
                            viewModel.selectedOutcome = nil
                            
                            // Then set the appropriate one
                            if let value = newValue {
                                if ["Met", "Not met"].contains(value) {
                                    viewModel.selectedOutcome = value
                                } else {
                                    viewModel.selectedRating = value
                                }
                            }
                        }
                    )) {
                        Text("Any").tag(Optional<String>.none)
                        ForEach(viewModel.uniqueGradesAndOutcomes, id: \.0) { grade, color in
                            Text(grade)
                                .foregroundColor(color)
                                .tag(Optional(grade))
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All") {
                        viewModel.clearFilters()
                    }
                    .disabled(!viewModel.hasActiveFilters)
                }
            }
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
