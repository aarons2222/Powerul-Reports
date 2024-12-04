//
//  PolicyView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 04/12/2024.
//

import SwiftUI
import PDFKit


struct PolicyView: View {
    
    var policy: PolicyType
        
    var body: some View {
        
        VStack(spacing: 0){
            CustomHeaderVIew(title: policy == .privacy ? "Privacy Policy" : "Terms of Service")
            
            PDFViewer(pdfName: policy == .privacy ? "privacy" : "terms")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
          
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}


struct PDFViewer: UIViewRepresentable {
    var pdfName: String
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        if let url = Bundle.main.url(forResource: pdfName, withExtension: "pdf") {
            pdfView.document = PDFDocument(url: url)
        }
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
    }
}

enum PolicyType{
    case terms
    case privacy
}
