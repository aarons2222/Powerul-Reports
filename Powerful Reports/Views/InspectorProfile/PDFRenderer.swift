import UIKit
import PDFKit

class PDFRenderer {
    let profile: InspectorProfile
    let reports: [Report]
    
    init(profile: InspectorProfile, reports: [Report]) {
        self.profile = profile
        self.reports = reports
    }
    
    func renderPDF() -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let outputFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(profile.name)_report.pdf")
        
        do {
            try renderer.writePDF(to: outputFileURL) { context in
                context.beginPage()
                
                // Load and draw image from assets
                if let logoImage = UIImage(named: "logos", in: .main, with: nil) {
                    let imageSize = logoImage.size
                    let scaledWidth: CGFloat = 100
                    let scaledHeight = (imageSize.height * scaledWidth) / imageSize.width
                    let imageRect = CGRect(x: pageRect.width - 150, y: 50, width: scaledWidth, height: scaledHeight)
                    
                    // Draw image maintaining aspect ratio
                    logoImage.draw(in: imageRect)
                    
                    // Start content below the logo height
                    let contentStartY = imageRect.maxY + 20
                    
                    let titleAttributes = [
                        NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)
                    ]
                    
                    let text = "Inspector Profile: \(profile.name)"
                    text.draw(at: CGPoint(x: 50, y: contentStartY), withAttributes: titleAttributes)
                    
                    let totalInspections = "Total Inspections: \(profile.totalInspections)"
                    totalInspections.draw(at: CGPoint(x: 50, y: contentStartY + 40), withAttributes: [
                        .font: UIFont.systemFont(ofSize: 14)
                    ])
                }
            }
            return outputFileURL
        } catch {
            print("Failed to create PDF: \(error)")
            return nil
        }
    }
}
