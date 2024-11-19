import SwiftUI
import Firebase

class InspectionReportsViewModel: ObservableObject {
    
    
    @Published var reports: [Report] = []
    
    

    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    @AppStorage("reportCount") var reportsCount: Int = 0
    
    private let reportsCacheKey = "cachedInspectionReports"
    
    init() {
        loadCachedReports()
        fetchReports()
    }
    
    // Load cached reports data from UserDefaults
    private func loadCachedReports() {
        if let savedData = UserDefaults.standard.data(forKey: reportsCacheKey) {
            let decoder = JSONDecoder()
            if let decodedReports = try? decoder.decode([Report].self, from: savedData) {
                self.reports = decodedReports
            }
        }
    }
    
    // Save reports data to UserDefaults
    private func cacheReports() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(reports) {
            UserDefaults.standard.set(encoded, forKey: reportsCacheKey)
        }
    }
    
    func fetchReports() {
        print("Fetching Reports")

        // Attach a snapshot listener to the inspection reports collection
        listener = db.collection("reports").addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching documents: \(error)")
                return
            }

            guard let documents = querySnapshot?.documents else {
                print("No documents found.")
                return
            }

            // Map Firestore data to `Report` objects
            let newReports = documents.compactMap { document -> Report? in
                let data = document.data()
                print("Raw Firestore Data: \(data)") // Debug raw data
                
                // Parse ratings array
                let ratingsData = data["ratings"] as? [[String: Any]] ?? []
                let ratings = ratingsData.map { ratingData in
                    Rating(
                        category: ratingData["category"] as? String ?? "",
                        rating: ratingData["rating"] as? String ?? ""
                    )
                }
                
                // Parse themes array
                let themesData = data["themes"] as? [[String: Any]] ?? []
                let themes = themesData.map { themeData in
                    Theme(
                        frequency: themeData["frequency"] as? Int ?? 0,
                        topic: themeData["topic"] as? String ?? ""
                    )
                }
                
                // Parse timestamp
                let timestampData = data["timestamp"] as? [String: Any] ?? [:]
                let timestamp = Timestamp(
                    _seconds: timestampData["_seconds"] as? Int64 ?? 0,
                    _nanoseconds: timestampData["_nanoseconds"] as? Int64 ?? 0
                )
                
                // Return a `Report` object
                return Report(
                    id: document.documentID, // Use unique Firestore document ID
                    date: data["date"] as? String ?? "",
                    inspector: data["inspector"] as? String ?? "",
                    localAuthority: data["localAuthority"] as? String ?? "",
                    outcome: data["outcome"] as? String ?? "",
                    previousInspection: data["previousInspection"] as? String ?? "",
                    ratings: ratings,
                    referenceNumber: data["referenceNumber"] as? String ?? "",
                    themes: themes,
                    typeOfProvision: data["typeOfProvision"] as? String ?? "",
                    timestamp: timestamp
                )
            }

            // Compare the new data with the existing data using their unique IDs
            let newIds = Set(newReports.map { $0.id })
            let existingIds = Set(self.reports.map { $0.id })

            if newIds != existingIds {
                self.reports = newReports
                self.reportsCount = self.reports.count
                self.cacheReports()
                print("Reports updated. Total count: \(self.reports.count)")
            } else {
                print("No changes in reports.")
            }
        }
    }


    // Helper methods for data analysis
    func getTotalReportsCount() -> Int {
        return reports.count
    }
    
    func getReportsByRating(_ rating: String) -> [Report] {
        return reports.filter { report in
            report.ratings.contains { $0.rating == rating }
        }
    }
    
    func getMostCommonThemes(limit: Int = 10) -> [(String, Int)] {
        // Combine all themes and their frequencies
        let allThemes = reports.flatMap { $0.themes }
        
        // Group by topic and sum frequencies
        var themeCounts: [String: Int] = [:]
        allThemes.forEach { theme in
            themeCounts[theme.topic, default: 0] += theme.frequency
        }
        
        // Sort by frequency and return top themes
        return themeCounts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { ($0.key, $0.value) }
    }
    
    func getReportsByLocalAuthority(_ authority: String) -> [Report] {
        return reports.filter { $0.localAuthority == authority }
    }
    
    deinit {
        // Remove the listener when the view model is deallocated
        listener?.remove()
    }
}
