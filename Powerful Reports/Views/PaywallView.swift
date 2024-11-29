import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    
    let features = [
        ("Unlimited Reports", "chart.bar.fill"),
        ("Advanced Filtering", "line.3.horizontal.decrease.circle.fill"),
        ("Export Data", "square.and.arrow.up.fill"),
        ("Priority Support", "star.fill")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            CustomHeaderVIew(title: "Premium")
            
            ScrollView {
                VStack(spacing: 30) {
                    // Hero Image
                    Image(systemName: "crown.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.color1)
                        .padding(.top, 40)
                    
                    // Title
                    Text("Unlock Full Access")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // Features
                    VStack(spacing: 20) {
                        ForEach(features, id: \.0) { feature in
                            HStack(spacing: 15) {
                                Image(systemName: feature.1)
                                    .font(.title2)
                                    .foregroundColor(.color1)
                                    .frame(width: 30)
                                
                                Text(feature.0)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.color1)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    
                    // Pricing Cards
                    VStack(spacing: 15) {
                        // Monthly Plan
                        Button(action: {
                            // Handle monthly subscription
                        }) {
                            VStack(spacing: 8) {
                                Text("Monthly")
                                    .font(.headline)
                                Text("£9.99/month")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.color0.opacity(0.3))
                            .cornerRadius(12)
                        }
                        
                        // Annual Plan
                        Button(action: {
                            // Handle annual subscription
                        }) {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Annual")
                                        .font(.headline)
                                    Text("SAVE 20%")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.color1)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                Text("£95.99/year")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.color0.opacity(0.3))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Terms and Restore
                    VStack(spacing: 10) {
                        Button("Restore Purchases") {
                            // Handle restore
                        }
                        .font(.footnote)
                        .foregroundColor(.color1)
                        
                        Text("Payment will be charged to your Apple ID account at the confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                }
                .padding(.bottom, 30)
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
    }
}

#Preview {
    PaywallView()
}
