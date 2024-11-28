import SwiftUI
import Firebase



class InspectionReportsViewModel: ObservableObject {
    @Published var reports: [Report] = []
    @Published private(set) var filteredReports: [Report] = []
    @Published private(set) var provisionTypeDistribution: [OutcomeData] = []

    // Caching structures
    private var reportsByInspector: [String: [Report]] = [:]
    private var reportsByAuthority: [String: [Report]] = [:]
    private var reportsByDate: [String: [Report]] = [:]

    
    private let cacheQueue = DispatchQueue(label: "com.app.datecache")
    private var dateCache: [String: Date] = [:]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        return formatter
    }()
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    @AppStorage("reportCount") var reportsCount: Int = 0
    private let reportsCacheKey = "cachedInspectionReports"
    @State var isTrial = false

    
    init() {
        if isTrial {
            // MARK: - Usage Example
        self.reports = DummyDataGenerator.generateDummyReports(count: 500)
            self.filteredReports = self.reports
            self.reportsCount = self.reports.count
            
            Task { @MainActor in
                await buildCaches()
                self.filteredReports = self.reports
             
            }
        } else {
            loadCachedReports()
            fetchReports()
        }
    }
    
    // MARK: - Cache Management
    
    private func buildCaches() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                self.reportsByInspector = Dictionary(grouping: self.reports) { $0.inspector }
            }
            
            group.addTask {
                self.reportsByAuthority = Dictionary(grouping: self.reports) { $0.localAuthority }
            }
            
            group.addTask {
                self.reportsByDate = Dictionary(grouping: self.reports) { $0.date }
            }
        }
    }
    
    
    
    
    
    @Published private(set) var groupedReports: [String: [Report]] = [:]
    @Published private(set) var sortedDates: [String] = []
    private var currentPage = 0
    private let pageSize = 20
    private var hasMoreData = true
    
    // Keep track of the current filter to know when to reset
    private var currentTimeFilter: TimeFilter = .last30Days
    
    func loadMoreContentIfNeeded(currentDate: String?) {
        guard let currentDate = currentDate,
              let currentIndex = sortedDates.firstIndex(of: currentDate),
              currentIndex == sortedDates.count - 3, // Load more when near the end
              hasMoreData else {
            return
        }
        
        loadNextPage()
    }
    
    private func loadNextPage() {
        // Simulate pagination with existing data
        let start = currentPage * pageSize
        let end = min(start + pageSize, reports.count)
        
        guard start < reports.count else {
            hasMoreData = false
            return
        }
        
        let newReports = Array(reports[start..<end])
        processNewReports(newReports)
        currentPage += 1
    }
    
    private func processNewReports(_ newReports: [Report]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        let filteredNewReports = newReports.filter { report in
            guard let reportDate = dateFormatter.date(from: report.date) else { return false }
            return reportDate >= currentTimeFilter.date
        }
        
        let newGrouped = Dictionary(grouping: filteredNewReports) { $0.date }
        
        DispatchQueue.main.async {
            // Merge new reports with existing ones
            for (date, reports) in newGrouped {
                if var existing = self.groupedReports[date] {
                    existing.append(contentsOf: reports)
                    self.groupedReports[date] = existing
                } else {
                    self.groupedReports[date] = reports
                }
            }
            
            // Update sorted dates
            self.sortedDates = self.groupedReports.keys.sorted { date1, date2 in
                guard let date1 = DateFormatter.reportDate.date(from: date1),
                      let date2 = DateFormatter.reportDate.date(from: date2) else {
                    return false
                }
                return date1 > date2
            }
        }
    }
    
    func resetAndReload(timeFilter: TimeFilter) {
        currentTimeFilter = timeFilter
        groupedReports.removeAll()
        sortedDates.removeAll()
        currentPage = 0
        hasMoreData = true
        loadNextPage()
    }

    
    
    
    
    // MARK: - Data Persistence
    
    private func loadCachedReports() {
        if isTrial { return }
        
        if let savedData = UserDefaults.standard.data(forKey: reportsCacheKey) {
            let decoder = JSONDecoder()
            if let decodedReports = try? decoder.decode([Report].self, from: savedData) {
                self.reports = decodedReports
                Task { @MainActor in
                    await buildCaches()
                    self.filteredReports = self.reports
                    await updateProvisionTypeDistribution()
                }
            }
        }
    }
    
    private func cacheReports() {
        if isTrial { return }
        
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(reports) {
            UserDefaults.standard.set(encoded, forKey: reportsCacheKey)
        }
    }
    
    // MARK: - Firebase Integration
    
    func fetchReports() {
        if isTrial { return }
        
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
                
                Task { @MainActor in
                    await self.buildCaches()
                    self.filteredReports = self.reports
                    await self.updateProvisionTypeDistribution()
                }
            } else {
                print("No changes in reports.")
            }
        }
    }
    
 
    func filterReports(timeFilter: TimeFilter) async {
        let filterDate = timeFilter.date
        print("Total reports before filtering: \(reports.count)")
        print("Filter date: \(filterDate)")
        
        let filtered = await withTaskGroup(of: [Report].self, body: { group -> [Report] in
            let chunkSize = 1000
            let chunks = stride(from: 0, to: reports.count, by: chunkSize).map {
                Array(reports[$0..<min($0 + chunkSize, reports.count)])
            }
            
            for (index, chunk) in chunks.enumerated() {
                group.addTask {
                    let filteredChunk = chunk.filter { report in
                        self.cacheQueue.sync {
                            // Handle date ranges by taking the second date (end date)
                            let dateComponents = report.date.components(separatedBy: " - ")
                            let dateString = dateComponents.count > 1
                                ? dateComponents[1].trimmingCharacters(in: .whitespaces)
                                : report.date.trimmingCharacters(in: .whitespaces)
                            
                            guard let reportDate = self.dateFormatter.date(from: dateString) else {
                                print("Failed to parse date: \(report.date)")
                                return false
                            }
                            return reportDate >= filterDate
                        }
                    }
                    return filteredChunk
                }
            }
            
            var results: [Report] = []
            for await chunkResult in group {
                results.append(contentsOf: chunkResult)
            }
            
            return results.sorted { $0.date > $1.date }
        })
        
        await MainActor.run {
            self.filteredReports = filtered
            Task {
                await self.updateProvisionTypeDistribution()
            }
        }
    }
 
    
//    func filterReports(timeFilter: TimeFilter) async {
//        let filterDate = timeFilter.date
//        print("Filtering reports for \(timeFilter)")
//        
//        let filtered = await withTaskGroup(of: [Report].self) { group in
//            let chunkSize = 1000
//            let chunks = stride(from: 0, to: reports.count, by: chunkSize).map {
//                Array(reports[$0..<min($0 + chunkSize, reports.count)])
//            }
//            
//            for chunk in chunks {
//                group.addTask {
//                    return chunk.filter { report in
//                        // Get or create date from cache
//                        let reportDate: Date? = self.cacheQueue.sync {
//                            if let cached = self.dateCache[report.date] {
//                                return cached
//                            }
//                            
//                            if let date = self.dateFormatter.date(from: report.date) {
//                                self.dateCache[report.date] = date
//                                return date
//                            }
//                            
//                            return nil
//                        }
//                        
//                        guard let date = reportDate else { return false }
//                        return date >= filterDate
//                    }
//                }
//            }
//            
//            var results: [Report] = []
//            for await chunkResult in group {
//                results.append(contentsOf: chunkResult)
//            }
//            return results.sorted { $0.date > $1.date }
//        }
//        
//        await MainActor.run {
//            self.filteredReports = filtered
//            Task {
//                await self.updateProvisionTypeDistribution()
//            }
//        }
//    }
    

     
    // MARK: - Filtering and Data Access
    
 
    
    func getTotalReportsCount() -> Int {
        return reports.count
    }
    
    func getInstpectorCount() -> Int{
        let uniqueInspectors = Set(reports.map { $0.inspector })
        return uniqueInspectors.count
    }
    


    

    
    
    func getReportsByRating(_ rating: String) -> [Report] {
        return filteredReports.filter { report in
            report.ratings.contains { $0.rating == rating }
        }
    }
    
    func getMostCommonThemes(limit: Int = 10) -> [(String, Int)] {
        var themeCounts: [String: Int] = [:]
        
        // Process in chunks for better performance
        let chunkSize = 1000
        for i in stride(from: 0, to: filteredReports.count, by: chunkSize) {
            let endIndex = min(i + chunkSize, filteredReports.count)
            let chunk = filteredReports[i..<endIndex]
            
            chunk.forEach { report in
                report.themes.forEach { theme in
                    themeCounts[theme.topic, default: 0] += theme.frequency
                }
            }
        }
        
        return themeCounts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { ($0.key, $0.value) }
    }
    
    func getReportsByLocalAuthority(_ authority: String) -> [Report] {
        reportsByAuthority[authority] ?? []
    }
    
    private func updateProvisionTypeDistribution() async {
        let distribution = await withTaskGroup(of: [OutcomeData].self) { group in
            let types = filteredReports.map { $0.typeOfProvision }
            let counts = Dictionary(grouping: types) { $0 }
                .mapValues { $0.count }
            
            let result = counts.map { type, count in
                let displayType = type.isEmpty ? "Not Specified" : type
                let color: Color = if type.contains("Childminder") {
                    .color1
                } else if type.contains("non-") {
                    .color6
                } else if type.contains("childcare on domestic") {
                    .color5
                } else {
                    .color7
                }
                
                return OutcomeData(
                    outcome: displayType,
                    count: count,
                    color: color
                )
            }.sorted { $0.count > $1.count }
            
            return result
        }
        
        await MainActor.run {
            self.provisionTypeDistribution = distribution
        }
    }
    
    func getInspectorProfile(name: String) -> InspectorProfile {
        let inspectorReports = reportsByInspector[name] ?? []
        
        let areas = Dictionary(grouping: inspectorReports) { $0.localAuthority }
            .mapValues { $0.count }
        
        var allGrades: [String: Int] = [:]
        
        inspectorReports.forEach { report in
            if let overallRating = report.ratings.first(where: { $0.category == RatingCategory.overallEffectiveness.rawValue }) {
                allGrades[overallRating.rating, default: 0] += 1
            } else {
                if !report.outcome.isEmpty {
                    allGrades[report.outcome, default: 0] += 1
                }
            }
        }
        
        return InspectorProfile(
            name: name,
            totalInspections: inspectorReports.count,
            areas: areas,
            grades: allGrades
        )
    }

    
    
    private func getFilteredTotalCount(for data: [OutcomeData]) -> Int {
          // Use the data passed to the view which is already filtered
          return data.reduce(0) { $0 + $1.count }
      }

    
//    
//    func calculatePercentage(_ count: Int) -> Double {
//        guard filteredReports.count > 0 else { return 0.0 }
//        
//    
//        let percentage = (Double(count) / Double(filteredReports.count)) * 100
//        return floor(percentage * 10) / 10
//    }
//    
//    
//    
//    func calculateProvisionPercentage(_ count: Int, in data: [OutcomeData]) -> Double {
//        let totalCount = getFilteredTotalCount(for: data)
//        guard totalCount > 0 else { return 0.0 }
//        
//        let percentage = (Double(count) / Double(totalCount)) * 100
//        return floor(percentage * 10) / 10
//    }

    func calculatePercentage(count: Int, forProvisionData data: [OutcomeData]? = nil) -> Double {
        let totalCount: Int
        if let data = data {
            totalCount = getFilteredTotalCount(for: data)
        } else {
            totalCount = filteredReports.count
        }
        
        guard totalCount > 0 else { return 0.0 }
        
        let percentage = (Double(count) / Double(totalCount)) * 100
        return floor(percentage * 10) / 10
    }
    
    
    
    deinit {
        listener?.remove()
    }
    
    // Your existing dummy data
    static let dummyReports: [Report] = [
        // ... your existing dummy reports ...
    ]
}



 extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components)!
    }
    
    func endOfMonth(for date: Date) -> Date {
        let components = DateComponents(month: 1, day: -1)
        return self.date(byAdding: components, to: startOfMonth(for: date))!
    }
}

 extension Date {
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: self)
    }
}


