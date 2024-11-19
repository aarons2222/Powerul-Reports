import SwiftUI
import Firebase

class InspectionReportsViewModel: ObservableObject {
    @Published var reports: [Report] = []
    @State var isTrial = false // Set to true for testing
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    @AppStorage("reportCount") var reportsCount: Int = 0
    private let reportsCacheKey = "cachedInspectionReports"
    
    init() {
        if isTrial {
            // Use dummy data for trial mode
            self.reports = InspectionReportsViewModel.dummyReports
            self.reportsCount = self.reports.count
        } else {
            // Use real data for non-trial mode
            loadCachedReports()
            fetchReports()
        }
    }
    
    // Load cached reports data from UserDefaults
    private func loadCachedReports() {
        if isTrial {
            return // Don't load cache in trial mode
        }
        
        if let savedData = UserDefaults.standard.data(forKey: reportsCacheKey) {
            let decoder = JSONDecoder() 
            if let decodedReports = try? decoder.decode([Report].self, from: savedData) {
                self.reports = decodedReports
            }
        }
    }
    
    // Save reports data to UserDefaults
    private func cacheReports() {
        if isTrial {
            return // Don't cache in trial mode
        }
        
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(reports) {
            UserDefaults.standard.set(encoded, forKey: reportsCacheKey)
        }
    }
    
    func fetchReports() {
        if isTrial {
            return // Don't fetch from Firebase in trial mode
        }
        
        print("Fetching Reports")
        
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
            
            let newReports = documents.compactMap { document -> Report? in
                let data = document.data()
                print("Raw Firestore Data: \(data)")
                
                let ratingsData = data["ratings"] as? [[String: Any]] ?? []
                let ratings = ratingsData.map { ratingData in
                    Rating(
                        category: ratingData["category"] as? String ?? "",
                        rating: ratingData["rating"] as? String ?? ""
                    )
                }
                
                let themesData = data["themes"] as? [[String: Any]] ?? []
                let themes = themesData.map { themeData in
                    Theme(
                        frequency: themeData["frequency"] as? Int ?? 0,
                        topic: themeData["topic"] as? String ?? ""
                    )
                }
                
                let timestampData = data["timestamp"] as? [String: Any] ?? [:]
                let timestamp = Timestamp(
                    _seconds: timestampData["_seconds"] as? Int64 ?? 0,
                    _nanoseconds: timestampData["_nanoseconds"] as? Int64 ?? 0
                )
                
                return Report(
                    id: document.documentID,
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
    
    // Helper methods remain unchanged as they work with both real and dummy data
    func getTotalReportsCount() -> Int {
        return reports.count
    }
    
    func getReportsByRating(_ rating: String) -> [Report] {
        return reports.filter { report in
            report.ratings.contains { $0.rating == rating }
        }
    }
    
    func getMostCommonThemes(limit: Int = 10) -> [(String, Int)] {
        let allThemes = reports.flatMap { $0.themes }
        var themeCounts: [String: Int] = [:]
        allThemes.forEach { theme in
            themeCounts[theme.topic, default: 0] += theme.frequency
        }
        return themeCounts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { ($0.key, $0.value) }
    }
    
    func getReportsByLocalAuthority(_ authority: String) -> [Report] {
        return reports.filter { $0.localAuthority == authority }
    }
    
    deinit {
        listener?.remove()
    }
    
    
    
    static let dummyReports: [Report] = [
        Report(
            id: "1",
            date: "19 November 2024",
            inspector: "Sarah Johnson",
            localAuthority: "Kent",
            outcome: "",
            previousInspection: "Good",
            ratings: [
                Rating(category: "Overall effectiveness", rating: "Good"),
                Rating(category: "The quality of education", rating: "Good"),
                Rating(category: "Behaviour and attitudes", rating: "Outstanding"),
                Rating(category: "Personal development", rating: "Good"),
                Rating(category: "Leadership and management", rating: "Good")
            ],
            referenceNumber: "EY123456",
            themes: [
                Theme(frequency: 8, topic: "Children's Behaviour"),
                Theme(frequency: 7, topic: "Personal Development"),
                Theme(frequency: 6, topic: "Parent Partnerships"),
                Theme(frequency: 5, topic: "Mathematical Development"),
                Theme(frequency: 4, topic: "Physical Development")
            ],
            typeOfProvision: "Childcare on non-domestic premises",
            timestamp: Timestamp(_seconds: 1732028878, _nanoseconds: 686000000)
        ),
        Report(
            id: "2",
            date: "18 November 2024",
            inspector: "Mark Wilson",
            localAuthority: "Surrey",
            outcome: "Met",
            previousInspection: "Met",
            ratings: [],
            referenceNumber: "EY789012",
            themes: [
                Theme(frequency: 9, topic: "Safeguarding"),
                Theme(frequency: 8, topic: "Staff Training"),
                Theme(frequency: 7, topic: "Health and Safety"),
                Theme(frequency: 6, topic: "Record Keeping"),
                Theme(frequency: 5, topic: "Risk Assessment")
            ],
            typeOfProvision: "Childminder",
            timestamp: Timestamp(_seconds: 1731942478, _nanoseconds: 686000000)
        ),
        Report(
            id: "3",
            date: "17 November 2024",
            inspector: "Emma Thompson",
            localAuthority: "Essex",
            outcome: "Not Met",
            previousInspection: "Met",
            ratings: [],
            referenceNumber: "EY345678",
            themes: [
                Theme(frequency: 8, topic: "Safeguarding Concerns"),
                Theme(frequency: 7, topic: "Staff Documentation"),
                Theme(frequency: 6, topic: "Policy Implementation"),
                Theme(frequency: 5, topic: "Safety Measures"),
                Theme(frequency: 4, topic: "Staff Qualifications")
            ],
            typeOfProvision: "Childcare on domestic premises",
            timestamp: Timestamp(_seconds: 1731856078, _nanoseconds: 686000000)
        ),
        Report(
            id: "4",
            date: "16 November 2024",
            inspector: "David Brown",
            localAuthority: "Hampshire",
            outcome: "",
            previousInspection: "Good",
            ratings: [
                Rating(category: "Overall effectiveness", rating: "Requires improvement"),
                Rating(category: "The quality of education", rating: "Requires improvement"),
                Rating(category: "Behaviour and attitudes", rating: "Good"),
                Rating(category: "Personal development", rating: "Good"),
                Rating(category: "Leadership and management", rating: "Requires improvement")
            ],
            referenceNumber: "EY901234",
            themes: [
                Theme(frequency: 7, topic: "Quality Improvement"),
                Theme(frequency: 6, topic: "Staff Development"),
                Theme(frequency: 5, topic: "Child Assessment"),
                Theme(frequency: 4, topic: "Learning Environment"),
                Theme(frequency: 3, topic: "Parent Communication")
            ],
            typeOfProvision: "Childminder",
            timestamp: Timestamp(_seconds: 1731769678, _nanoseconds: 686000000)
        ),
        Report(
            id: "5",
            date: "15 November 2024",
            inspector: "Lisa Chen",
            localAuthority: "Hertfordshire",
            outcome: "Met",
            previousInspection: "Not Met",
            ratings: [],
            referenceNumber: "EY567890",
            themes: [
                Theme(frequency: 9, topic: "Documentation Improvement"),
                Theme(frequency: 8, topic: "Staff Supervision"),
                Theme(frequency: 7, topic: "First Aid Requirements"),
                Theme(frequency: 6, topic: "Safety Procedures"),
                Theme(frequency: 5, topic: "Qualification Checks")
            ],
            typeOfProvision: "Childminder",
            timestamp: Timestamp(_seconds: 1731683278, _nanoseconds: 686000000)
        ),
        Report(
            id: "6",
            date: "14 November 2024",
            inspector: "James Miller",
            localAuthority: "Suffolk",
            outcome: "Not Met",
            previousInspection: "Met",
            ratings: [],
            referenceNumber: "EY234567",
            themes: [
                Theme(frequency: 8, topic: "Missing Documentation"),
                Theme(frequency: 7, topic: "Registration Requirements"),
                Theme(frequency: 6, topic: "Premises Safety"),
                Theme(frequency: 5, topic: "Staff Checks"),
                Theme(frequency: 4, topic: "Policy Updates")
            ],
            typeOfProvision: "Childcare on domestic premises",
            timestamp: Timestamp(_seconds: 1731596878, _nanoseconds: 686000000)
        )
    ]

}
