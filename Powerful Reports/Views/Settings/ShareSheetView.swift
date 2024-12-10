//
//  ShareSheetView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 10/12/2024.
//

import SwiftUI
import MessageUI


struct ShareSheetView: View {
    let appStoreUrl = URL(string: "https://apps.apple.com/your-app-url")!
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var showingMessageCompose = false
    @State private var messageResult: MessageComposeResult?
    
    var body: some View {
        VStack(spacing: 12) {
            // Close Button
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.gray)
                }
                .padding()
            }
            
            
          
            VStack{
                
                Image("logo_clear")
                    .resizable()
                    .frame(width: 120, height: 120
                    )
                
                
             Text("Share Powerful Reports")
                    .font(.title)
                    .fontWeight(.regular)
                    .foregroundStyle(.white)
            }
            Spacer()
                
            
            VStack(spacing: 30){
                
                
                
                if MFMessageComposeViewController.canSendText() {
                    ShareButton(icon: "message.fill", text: "Messages", color: .color2) {
                        showingMessageCompose = true
                    }
                }
                
                ShareButton(icon: "bubble.left.fill", text: "Messenger", color: .color2.opacity(0.8)) {
                    openURL("fb-messenger://")
                }
                
                ShareButton(icon: "camera.fill", text: "Instagram", color: .color2.opacity(0.6)) {
                    openURL("instagram://")
                }
                
                ShareButton(icon: "f.square.fill", text: "Facebook", color: .color2.opacity(0.4)) {
                    openURL("fb://")
                }
                
                ShareButton(icon: "square.and.arrow.up", text: "More", color: .color2.opacity(0.2)) {
                    showingShareSheet = true
                }
                
            
            }
            .padding()
            Spacer()
        }
        .background {
            ZStack {
                LinearGradient(
                    colors: [.color2.opacity(0.1), .color3.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                Circle()
                    .fill(.color2.opacity(0.1))
                    .blur(radius: 50)
                    .offset(x: -100, y: -100)
                
                Circle()
                    .fill(.color3.opacity(0.1))
                    .blur(radius: 50)
                    .offset(x: 100, y: 100)
            }
            .ignoresSafeArea()
        }

        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [appStoreUrl])
        }
        .sheet(isPresented: $showingMessageCompose) {
            MessageComposeView(
                appStoreUrl: appStoreUrl.absoluteString,
                completion: { result in
                    messageResult = result
                    showingMessageCompose = false
                }
            )
        }
    }
    
    private func openURL(_ urlScheme: String) {
        guard let url = URL(string: urlScheme) else { return }
        UIApplication.shared.open(url)
    }
}

struct ShareButton: View {
    let icon: String
    let text: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.white)
                Text(text)
                    .fontWeight(.regular)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .cornerRadius(30)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}


// Add this MessageComposeViewController wrapper
struct MessageComposeView: UIViewControllerRepresentable {
    let appStoreUrl: String
    let completion: (MessageComposeResult) -> Void
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        
        // Customize the message
        controller.body = "Check out Powerful Reports by Powerful Pracititioners! \(appStoreUrl)"
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let completion: (MessageComposeResult) -> Void
        
        init(completion: @escaping (MessageComposeResult) -> Void) {
            self.completion = completion
        }
        
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
            completion(result)
        }
    }
}
