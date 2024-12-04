//
//  CustomPicker.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 02/12/2024.
//

import SwiftUI


struct CustomPicker<SelectionValue>: View where SelectionValue: ExpressibleByNilLiteral {
    @Binding var selection: SelectionValue
    let items: [String]
    
    @State var isPicking = false
    @State var hoveredItem: String?
    @State var placeHolder: String
    @Environment(\.isEnabled) var isEnabled
    
    var body: some View {
        ZStack {
            // Select Button
            HStack {
                Text(selection as? String ?? placeHolder)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 15)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.color0)
                    .stroke(.color2, lineWidth: 2.2)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                isPicking.toggle()
            }
        }
        .padding(.horizontal, 12)
        .opacity(isEnabled ? 1.0 : 0.6)
        .font(.body)
        .fullScreenCover(isPresented: $isPicking) {
            PickerDropdown(selection: $selection,
                          items: items,
                          isPicking: $isPicking,
                           hoveredItem: $hoveredItem, placeHolder: placeHolder)
                .background(TransparentBackground())
        }
    }
}

struct PickerDropdown<SelectionValue>: View where SelectionValue: ExpressibleByNilLiteral {
    @Binding var selection: SelectionValue
    let items: [String]
    @Binding var isPicking: Bool
    @Binding var hoveredItem: String?
    @State var placeHolder: String
    
    var body: some View {
        VStack {
         
            


         
            ZStack {
                // Center the Text inside the ZStack
                Text(placeHolder)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack {
                    Spacer()
                    Button {
                        isPicking = false
                    } label: {
                        Image(systemName: "multiply.circle")
                            .font(.title2)
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
            .background(.color1)

            
            ScrollView {
                VStack(spacing: 0) {
                  //  pickerOptionView(text: placeHolder, value: nil)
                    
                    ForEach(items, id: \.self) { item in
                        Divider()
                        pickerOptionView(text: item, value: item as? SelectionValue)
                    }
                }
            }
            .scrollIndicators(.never)
            .frame(height: 400)
            
        }
        .background(.color0)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.color2, lineWidth: 2.2)
        )
        .padding(.horizontal)
        .transition(.scale(scale: 0.8, anchor: .top)
            .combined(with: .opacity)
            .combined(with: .offset(y: -10)))
    }
    
    private func pickerOptionView(text: String, value: SelectionValue?) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                hoveredItem = text
            }
            // Delay the dismissal slightly to show the selection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                selection = value ?? nil
                withAnimation {
                    isPicking = false
                }
            }
        } label: {
    
        Text(text)
            .font(.title3)
            .foregroundStyle(hoveredItem == text ? .white : .color4)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(height: 44)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 10)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(hoveredItem == text ? Color.color1.opacity(0.6) : Color.clear)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 10)
                    .offset(y: 5)
            }
            .foregroundColor(hoveredItem == text ? .color1 : .primary)
        }
        .contentShape(Rectangle())
        .onHover { isHovered in
            withAnimation(.easeOut(duration: 0.4)) {
                hoveredItem = isHovered ? text : nil
            }
        }
    }
}

struct TransparentBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
