//
//  FilterView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 04/12/2024.
//

import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var viewModel: AllReportsViewModel
    
    init(viewModel: AllReportsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    FilterSection(title: "Filter by Inspector") {
                        CustomPicker(selection: $viewModel.selectedInspector,
                                     items: viewModel.availableInspectors, placeHolder: "Inspectors")
                            .transition(.opacity)
                    }
                    
                    FilterSection(title: "Filter by Authority") {
                        CustomPicker(selection: $viewModel.selectedAuthority,
                                   items: viewModel.availableAuthorities,  placeHolder: "Local Authorities")
                            .transition(.opacity)
                    }
                    
                    FilterSection(title: "Filter by Provision Type") {
                        CustomPicker(selection: $viewModel.selectedProvisionType,
                                   items: viewModel.availableProvisionTypes, placeHolder: "Provision Types")
                            .transition(.opacity)
                    }
                    
                    FilterSection(title: "Grade/Outcome") {
                        RatingGrid(selectedRating: createRatingBinding())
                            .transition(.opacity)
                    }
                    
                    Spacer()
                    
                    GlobalButton(title: "\(viewModel.totalReportsCount > 0 ? "Show \(viewModel.totalReportsCount)" : "0") Reports") {
                        dismiss()
                    }
                
                    .padding(.top)
                }
               
            }
            .padding()
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        viewModel.selectedInspector = nil
                        viewModel.selectedAuthority = nil
                        viewModel.selectedProvisionType = nil
                        viewModel.selectedRating = nil
                        viewModel.selectedOutcome = nil
                    }
                }
            }
        }
    }
    
    private func createRatingBinding() -> Binding<RatingValue> {
        Binding(
            get: {
                if let rating = viewModel.selectedRating {
                    return RatingValue(rawValue: rating) ?? .none
                } else if let outcome = viewModel.selectedOutcome {
                    return RatingValue(rawValue: outcome) ?? .none
                }
                return .none
            },
            set: { newValue in
                viewModel.selectedRating = nil
                viewModel.selectedOutcome = nil
                
                let value = newValue.rawValue
                if ["Met", "Not met"].map({ $0.lowercased() }).contains(value.lowercased()) {
                    viewModel.selectedOutcome = value
                } else {
                    viewModel.selectedRating = value
                }
            }
        )
    }
}

struct FilterSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            content
                .padding(.vertical)
        
        }
    }
}
