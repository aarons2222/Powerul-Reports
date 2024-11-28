import SwiftUI
import Firebase



class InspectionReportsViewModel: ObservableObject {
    @Published var reports: [Report] = []
    @Published private(set) var filteredReports: [Report] = []
    @Published private(set) var provisionTypeDistribution: [OutcomeData] = []
    @Published private(set) var groupedReports: [String: [Report]] = [:]
    @Published private(set) var sortedDates: [String] = []
    
    // Caching structures
    private var reportsByInspector: [String: [Report]] = [:]
    private var reportsByAuthority: [String: [Report]] = [:]
    private var reportsByDate: [String: [Report]] = [:]

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        formatter.calendar = Calendar.current
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    private(set) var reportsCount: Int = 0
    private(set) var selectedTimeFilter: String = TimeFilter.last30Days.rawValue
    
    private let cacheDirectory: URL? = {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Reports")
        
        // Create directory if it doesn't exist
        if let directory = directory {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        
        return directory
    }()
    
    private var reportsCacheFile: URL? {
        cacheDirectory?.appendingPathComponent("reports_cache.json")
    }
    
    private var metadataCacheFile: URL? {
        cacheDirectory?.appendingPathComponent("metadata_cache.json")
    }
    
    private var currentPage = 0
    private let pageSize = 20
    private var hasMoreData = true
    @State var isTrial = false
    
    // Keep track of the current filter to know when to reset
    private var currentTimeFilter: TimeFilter = .last30Days
    
    init() {
        if isTrial {
            self.reports = DummyDataGenerator.generateDummyReports(count: 500)
            self.filteredReports = self.reports
            self.reportsCount = self.reports.count
            
            Task { @MainActor in
                await buildCaches()
                await updateProvisionTypeDistribution()
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
    
    // MARK: - Data Persistence
    
    private func loadCachedReports() {
        guard let reportsCacheFile = reportsCacheFile else { return }
        
        do {
            if FileManager.default.fileExists(atPath: reportsCacheFile.path) {
                let data = try Data(contentsOf: reportsCacheFile)
                let decoder = JSONDecoder()
                let cachedReports = try decoder.decode([Report].self, from: data)
                self.reports = cachedReports
                self.filteredReports = cachedReports
                self.reportsCount = cachedReports.count
                print("Loaded \(cachedReports.count) reports from cache")
                
                Task { @MainActor in
                    await buildCaches()
                    await updateProvisionTypeDistribution()
                }
            }
        } catch {
            print("Error loading cached reports: \(error)")
        }
    }
    
    private func saveToCacheFile() {
        guard let reportsCacheFile = reportsCacheFile else { return }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(reports)
            try data.write(to: reportsCacheFile)
            print("Saved \(reports.count) reports to cache")
            
            // Update metadata
            self.reportsCount = reports.count
        } catch {
            print("Error saving reports to cache: \(error)")
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
                self.saveToCacheFile()
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
        
        let filtered = reports.filter { report in
            let dateComponents = report.date.components(separatedBy: " - ")
            let dateString = dateComponents.count > 1 ? dateComponents[1] : report.date
            guard let reportDate = self.dateFormatter.date(from: dateString.trimmingCharacters(in: .whitespaces)) else {
                return false
            }
            return reportDate >= filterDate
        }
        
        await MainActor.run {
            self.filteredReports = filtered
            Task {
                await self.updateProvisionTypeDistribution()
            }
        }
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
    
    func getFilteredTotalCount(for data: [OutcomeData]) -> Int {
        // Use the data passed to the view which is already filtered
        return data.reduce(0) { $0 + $1.count }
    }
    
    func getTotalReportsCount() -> Int {
        return reports.count
    }
    
    func getInspectorCount() -> Int {
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
        
        // Performance: Process in background with chunks
        DispatchQueue.global(qos: .userInitiated).async {
            let filteredNewReports = newReports.filter { report in
                guard let reportDate = dateFormatter.date(from: report.date) else { return false }
                return reportDate >= self.currentTimeFilter.date
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
                
                // Performance: Cache sorted dates result
                self.sortedDates = self.groupedReports.keys.sorted { date1, date2 in
                    guard let date1 = DateFormatter.reportDate.date(from: date1),
                          let date2 = DateFormatter.reportDate.date(from: date2) else {
                        return false
                    }
                    return date1 > date2
                }
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
    
    func calculatePercentage(_ count: Int) -> Double {
        guard filteredReports.count > 0 else { return 0.0 }
        
        let percentage = (Double(count) / Double(filteredReports.count)) * 100
        return floor(percentage * 10) / 10
    }
    
    func calculateProvisionPercentage(_ count: Int, in data: [OutcomeData]) -> Double {
        let totalCount = getFilteredTotalCount(for: data)
        guard totalCount > 0 else { return 0.0 }
        
        let percentage = (Double(count) / Double(totalCount)) * 100
        return floor(percentage * 10) / 10
    }
    
    func getReportsByDate(_ date: String) -> [Report] {
        return reportsByDate[date] ?? []
    }
    
    func getReportsByInspector(_ inspector: String) -> [Report] {
        return reportsByInspector[inspector] ?? []
    }
    
    func getUniqueInspectors() -> [String] {
        return Array(Set(reports.map { $0.inspector })).sorted()
    }
    
    func getUniqueAuthorities() -> [String] {
        return Array(Set(reports.map { $0.localAuthority })).sorted()
    }
    
    func getInspectorWorkload() -> [(String, Int)] {
        let workloads = Dictionary(grouping: reports) { $0.inspector }
            .mapValues { $0.count }
        return workloads.sorted { $0.value > $1.value }
    }
    
    func getAuthorityDistribution() -> [(String, Int)] {
        let distribution = Dictionary(grouping: reports) { $0.localAuthority }
            .mapValues { $0.count }
        return distribution.sorted { $0.value > $1.value }
    }
    
    func getRatingDistribution() -> [String: Int] {
        var distribution: [String: Int] = [:]
        reports.forEach { report in
            if let overallRating = report.ratings.first(where: { $0.category == RatingCategory.overallEffectiveness.rawValue }) {
                distribution[overallRating.rating, default: 0] += 1
            }
        }
        return distribution
    }
    
    func getThemeAnalysis() -> [(String, Double)] {
        let themes = reports.flatMap { $0.themes }
        let totalThemes = Double(themes.count)
        let distribution = Dictionary(grouping: themes) { $0.topic }
            .mapValues { themes in
                let totalFrequency = Double(themes.reduce(0) { $0 + $1.frequency })
                return (totalFrequency / totalThemes) * 100
            }
        return distribution.sorted { $0.value > $1.value }
    }
    
    func searchReports(query: String) -> [Report] {
        guard !query.isEmpty else { return [] }
        let lowercasedQuery = query.lowercased()
        return reports.filter { report in
            report.inspector.lowercased().contains(lowercasedQuery) ||
            report.localAuthority.lowercased().contains(lowercasedQuery) ||
            report.typeOfProvision.lowercased().contains(lowercasedQuery) ||
            report.themes.contains { $0.topic.lowercased().contains(lowercasedQuery) }
        }
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
