//
//  OfstedWebView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 03/12/2024.
//


import SwiftUI
@preconcurrency import WebKit



struct OfstedWebView: UIViewRepresentable {
    let searchText: String
    @Binding var isLoading: Bool
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: OfstedWebView
        var currentStep = 0 // 0: Initial, 1: Search Results, 2: First Result
        
        init(_ parent: OfstedWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            // Only show loading for initial search
            if currentStep == 0 {
                parent.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            switch currentStep {
            case 0:
                performSearch(webView)
                currentStep = 1
                
            case 1:
                // Wait a bit longer for the results to fully load
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.clickFirstResult(webView)
                }
                // Set loading to false after search results are loaded
               
                
            case 2:
                DispatchQueue.main.async {
                    self.parent.isLoading = false
                }
                break
                
            default:
                break
            }
        }
        
        private func performSearch(_ webView: WKWebView) {
            let searchScript = """
                function performSearch() {
                    var labels = Array.from(document.getElementsByTagName('label'));
                    var searchLabel = labels.find(label =>
                        label.textContent.includes('Name, URN or keyword')
                    );
                    
                    if (searchLabel) {
                        var searchField = document.getElementById(searchLabel.getAttribute('for')) ||
                                        searchLabel.querySelector('input');
                                        
                        if (searchField) {
                            searchField.value = '\(parent.searchText)';
                            searchField.dispatchEvent(new Event('input', { bubbles: true }));
                            searchField.dispatchEvent(new Event('change', { bubbles: true }));
                            
                            var searchButton = document.querySelector('button[type="submit"]') ||
                                             document.querySelector('input[type="submit"]') ||
                                             Array.from(document.getElementsByTagName('button')).find(button =>
                                                 button.textContent.toLowerCase().includes('search')
                                             );
                            if (searchButton) {
                                searchButton.click();
                                return true;
                            }
                        }
                    }
                    return false;
                }
                performSearch();
            """
            
            webView.evaluateJavaScript(searchScript) { (result, error) in
                if let error = error {
                    print("Error executing search: \(error)")
                }
            }
        }
        
        private func clickFirstResult(_ webView: WKWebView) {
            let clickScript = """
                function clickFirstResult() {
                    console.log('Starting click attempt');
                    
                    const link = document.querySelector('ul.results-list.list-unstyled li.search-results h3.search-result__title a') ||
                               document.querySelector('a[href*="/provider/"]') ||
                               document.querySelector('.search-result__title a');
                    
                    if (link) {
                        console.log('Found link:', link.href);
                        link.click();
                        return true;
                    }
                    
                    console.log('No link found');
                    
                    const results = document.querySelector('.results-list');
                    if (results) {
                        console.log('Results HTML:', results.innerHTML);
                    }
                    
                    return false;
                }
                clickFirstResult();
            """
            
            webView.evaluateJavaScript(clickScript) { [weak self] (result, error) in
                if let error = error {
                    print("Error clicking result: \(error)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.clickFirstResult(webView)
                    }
                } else {
                    if let success = result as? Bool, success {
                        print("Successfully clicked link")
                        self?.currentStep = 2
                    } else {
                        print("Failed to find link, will retry")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self?.clickFirstResult(webView)
                        }
                    }
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            if currentStep == 0 {
                DispatchQueue.main.async {
                    self.parent.isLoading = false
                }
            }
        }
        
        func webView(_ webView: WKWebView,
                    createWebViewWith configuration: WKWebViewConfiguration,
                    for navigationAction: WKNavigationAction,
                    windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
        
        func webView(_ webView: WKWebView,
                    runJavaScriptAlertPanelWithMessage message: String,
                    initiatedByFrame frame: WKFrameInfo,
                    completionHandler: @escaping () -> Void) {
            print("JavaScript Alert: \(message)")
            completionHandler()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        if let url = URL(string: "https://reports.ofsted.gov.uk") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
    }
}
