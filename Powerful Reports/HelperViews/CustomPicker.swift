//
//  CustomPicker.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 02/12/2024.
//

import SwiftUI


struct CustomPicker<SelectionValue>: View where SelectionValue == String? {
    @Binding var selection: SelectionValue
    let items: [String]
    
    @State var isPicking = false
    @State var hoveredItem: String?
    @Environment(\.isEnabled) var isEnabled
    
    let buttonHeight: CGFloat = 44
    let arrowSize: CGFloat = 16
    let cornerRadius: CGFloat = 20
    
    var body: some View {
        // Select Button - Selected item
        HStack {
            Text(selection ?? "Any")
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
            Text(">")
                .rotationEffect(isPicking ? Angle(degrees: 90) : Angle(degrees: -90))
        }
        .padding(.horizontal, 15)
        .frame(maxWidth: .infinity)
        .frame(height: buttonHeight)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.color0)
                .stroke(.color2, lineWidth: 2.2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            isPicking.toggle()
        }
        // Picker
        .overlay(alignment: .topLeading) {
            VStack {
                if isPicking {
                    Spacer(minLength: buttonHeight + 10)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // Add "Any" option
                            Divider()
                            Button {
                                selection = nil
                                isPicking.toggle()
                            } label: {
                                pickerItemView(text: "Any", isHovered: hoveredItem == "Any")
                            }
                            .buttonStyle(.plain)
                            Divider()
                            
                            // Add all other items
                            ForEach(items, id: \.self) { item in
                                Divider()
                                Button {
                                    selection = item
                                    isPicking.toggle()
                                } label: {
                                    pickerItemView(text: item, isHovered: hoveredItem == item)
                                }
                                .buttonStyle(.plain)
                                Divider()
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .scrollIndicators(.never)
                    .frame(height: 400)
                    .background(.color0)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(.color2, lineWidth: 2.2)
                    )
                    .transition(.scale(scale: 0.8, anchor: .top).combined(with: .opacity).combined(with: .offset(y: -10)))
                    .zIndex(100) // Ensure dropdown is above everything
                }
            }
        }
        .padding(.horizontal, 12)
        .opacity(isEnabled ? 1.0 : 0.6)
        .font(.body)
        .animation(.easeInOut(duration: 0.12), value: isPicking)
        .sensoryFeedback(.selection, trigger: selection)
        .zIndex(isPicking ? 100 : 0) // Raise z-index of entire picker when open
    }
    
    private func pickerItemView(text: String, isHovered: Bool) -> some View {
        Text(text)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(height: buttonHeight)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 10)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isHovered ? Color.accentColor.opacity(0.8) : Color.clear)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 10)
                    .offset(y: 5)
            }
            .onHover { isHovered in
                if isHovered {
                    hoveredItem = text
                }
            }
    }
}
