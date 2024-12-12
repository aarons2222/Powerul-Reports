import SwiftUI
import Firebase
import FirebaseFirestore
import Combine

class InspectionReportsViewModel: ObservableObject {
    @Published var reports: [Report] = []
    @Published var searchText: String = ""
    @Published private(set) var searchResults: [String: [Report]] = [:] // Grouped search results
    @Published private(set) var searchDates: [String] = [] // Sorted dates for search results
    @Published private(set) var provisionTypeDistribution: [OutcomeData] = []
    @Published private(set) var outcomesDistribution: [OutcomeData] = []
    @Published var filteredReports: [Report] = []
    @Published var reportsCount: Int = 0
    @Published var lastFirebaseUpdate: Date?
    @Published var isLoading: Bool = false
    @Published var showPaywall: Bool = false
    @Published var isPremium: Bool = false {
        didSet {
            handleSubscriptionChange()
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSubscriptionObserver()
        setupSearchObserver()
        isPremium = SubscriptionPersistence.shared.isPremium
    }
    
    private func setupSubscriptionObserver() {
        NotificationCenter.default.publisher(for: .subscriptionStatusDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isPremium = SubscriptionPersistence.shared.isPremium
            }
            .store(in: &cancellables)
    }
    
    
    
    private func setupSearchObserver() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query)
            }
            .store(in: &cancellables)
    }
    
    
    private func handleSubscriptionChange() {
        isLoading = true
        
        if isPremium {
            // Switch to Firebase data for premium users
            fetchReports()
        } else {
            // Switch to dummy data for non-premium users
            self.reports = DummyDataGenerator.generateDummyReports(count: 500)
            self.filteredReports = self.reports
            self.reportsCount = self.reports.count
            Task {
                await buildCaches()
                await updateProvisionTypeDistribution()
                await updateOutcomesDistribution(for: self.reports)
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    // Filter states
    @Published var selectedInspector: String?
    @Published var selectedAuthority: String?
    @Published var selectedProvisionType: String?
    @Published var selectedRating: String?
    @Published var selectedOutcome: String?
    @Published var selectedDateRange: ClosedRange<Date>?
    
    @Published var selectedTimeFilter: TimeFilter = .last12Months
    
    // Caching structures
    var groupedReports: [String: [Report]] = [:]
    var sortedDates: [String] = []
    private var reportsByInspector: [String: [Report]] = [:]
    private var reportsByAuthority: [String: [Report]] = [:]
    private var reportsByDate: [String: [Report]] = [:]
    
    // Firebase
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    // Pagination
    private var currentPage = 0
    private let pageSize = 10
    private var hasMoreData = true
    
    // Search
    private var searchCancellable: AnyCancellable?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()
    
    // Cache file URLs
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
    
    var uniqueInspectors: [String] {
        Array(Set(reports.map { $0.inspector })).sorted()
    }
    
    var uniqueAuthorities: [String] {
        Array(Set(reports.map { $0.localAuthority })).sorted()
    }
    
    var uniqueProvisionTypes: [String] {
        Array(Set(reports.map { $0.typeOfProvision })).sorted()
    }
    
    var uniqueRatings: [String] {
        Array(Set(reports.compactMap { $0.overallRating })).sorted()
    }
    
    var uniqueOutcomes: [String] {
        Array(Set(reports.map { $0.outcome })).sorted()
    }
    
    var uniqueGradesAndOutcomes: [(String, Color)] {
        var results: Set<String> = []
        var gradesWithColors: [(String, Color)] = []
        
        for report in reports {
            if !report.outcome.isEmpty && !results.contains(report.outcome) {
                results.insert(report.outcome)
                gradesWithColors.append((report.outcome, report.outcome == "Met" ? .color2 : .color6))
            } else if let overallRating = report.ratings.first(where: { $0.category == RatingCategory.overallEffectiveness.rawValue }),
                      !results.contains(overallRating.rating),
                      let ratingValue = RatingValue(rawValue: overallRating.rating) {
                results.insert(overallRating.rating)
                gradesWithColors.append((overallRating.rating, ratingValue.color))
            }
        }
        
        return gradesWithColors.sorted { $0.0 < $1.0 }
    }
    
    private func getGradeOrOutcome(for report: Report) -> String? {
        if !report.outcome.isEmpty {
            return report.outcome
        } else if let overallRating = report.ratings.first(where: { $0.category == RatingCategory.overallEffectiveness.rawValue }) {
            return overallRating.rating
        }
        return nil
    }
    
    // MARK: - Cache Management
    
    private func buildCaches() async {
        // Group reports by date, handling any date formatting issues
        let dateGroups = Dictionary(grouping: reports) { report -> String in
            if let dateComponents = report.date.components(separatedBy: " - ").last?.trimmingCharacters(in: .whitespaces),
               let _ = dateFormatter.date(from: dateComponents) {
                return dateComponents
            }
            return report.date // Fallback to original date if parsing fails
        }
        
        let inspectorGroups = Dictionary(grouping: reports) { $0.inspector }
        let authorityGroups = Dictionary(grouping: reports) { $0.localAuthority }
        
        let sortedDateKeys = dateGroups.keys.sorted { date1, date2 in
            guard let date1Date = dateFormatter.date(from: date1),
                  let date2Date = dateFormatter.date(from: date2) else {
                return date1 > date2 // Fallback to string comparison if parsing fails
            }
            return date1Date > date2Date
        }
        
        await MainActor.run {
            self.reportsByDate = dateGroups
            self.reportsByInspector = inspectorGroups
            self.reportsByAuthority = authorityGroups
            self.groupedReports = dateGroups
            self.sortedDates = sortedDateKeys
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
            // Check if the cache file exists and compare content
            if FileManager.default.fileExists(atPath: reportsCacheFile.path),
               let existingData = try? Data(contentsOf: reportsCacheFile),
               let existingReports = try? JSONDecoder().decode([Report].self, from: existingData),
               existingReports.count == reports.count {
                // Skip save if the number of reports is the same
                return
            }
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(reports)
            try data.write(to: reportsCacheFile)
            print("Saved \(reports.count) saveToCacheFilee")
            
            // Update metadata
            self.reportsCount = reports.count
        } catch {
            print("Error saving reports to cache: \(error)")
        }
    }
    
    // MARK: - Firebase Integration
    
    func fetchReports() {
        if !isPremium { return }
        
        print("Fetching Reports")
        isLoading = true
        
        listener = db.collection("reports")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                defer {
                    self.isLoading = false
                }
                
                if let error = error {
                    print("Error fetching reports: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                self.reports = documents.compactMap { document in
                    let data = document.data()
                    
                    // Decode ratings
                    let ratingsData = data["ratings"] as? [[String: Any]] ?? []
                    let ratings = ratingsData.map { ratingData in
                        Rating(
                            category: ratingData["category"] as? String ?? "",
                            rating: ratingData["rating"] as? String ?? ""
                        )
                    }
                    
                    // Decode themes
                    let themesData = data["themes"] as? [[String: Any]] ?? []
                    let themes = themesData.map { themeData in
                        Theme(
                            frequency: themeData["frequency"] as? Int ?? 0,
                            topic: themeData["topic"] as? String ?? ""
                        )
                    }
                    
                    // Decode timestamp
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
                
                self.filteredReports = self.reports
                self.reportsCount = self.reports.count
                self.lastFirebaseUpdate = Date()
                
                // Save to cache
                self.saveToCacheFile()
                
                // Update caches and UI
                Task { @MainActor in
                    await self.buildCaches()
                    await self.updateProvisionTypeDistribution()
                    await self.updateOutcomesDistribution(for: self.reports)
                    
                    // Initialize pagination
                    self.currentPage = 0
                    self.hasMoreData = true
                    self.loadNextPage()
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
    
    private func updateOutcomesDistribution(for reports: [Report]) async {
        let processedOutcomes = reports.map { report -> (String, Color) in
            if !report.outcome.isEmpty {
                return (report.outcome, report.outcome == "Met" ? .color2 : .color6)
            } else if let overallRating = report.ratings.first(where: { $0.category == RatingCategory.overallEffectiveness.rawValue }),
                      let ratingValue = RatingValue(rawValue: overallRating.rating) {
                return (overallRating.rating, ratingValue.color)
            }
            return ("Unknown", .gray)
        }
        
        let outcomeCounts = Dictionary(grouping: processedOutcomes) { $0.0 }
        let outcomes = outcomeCounts.map { outcome, reports in
            OutcomeData(
                outcome: outcome,
                count: reports.count,
                color: reports.first?.1 ?? .gray
            )
        }.sorted { $0.count > $1.count }
        
        await MainActor.run {
            self.outcomesDistribution = outcomes
        }
    }
    
    func getFilteredTotalCount(for data: [OutcomeData]) -> Int {
      
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
        guard hasMoreData && !isLoading else { return }
        
        isLoading = true
        
        let startIndex = currentPage * pageSize
        let endIndex = min(startIndex + pageSize, filteredReports.count)
        
        // Simulate network delay for smooth loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            let newItems = Array(self.filteredReports[startIndex..<endIndex])
            self.currentPage += 1
            self.hasMoreData = endIndex < self.filteredReports.count
            self.isLoading = false
        }
    }
    
    private func processNewReports(_ newReports: [Report]) {
        // Performance: Process in background with chunks
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let filteredNewReports = newReports.filter { report in
                guard let reportDate = self.dateFormatter.date(from: report.date) else { return false }
                return reportDate >= self.selectedTimeFilter.date
            }
            Task{
               await self.updateOutcomesDistribution(for: filteredNewReports)
            }
            // Process in chunks of 50 reports
            let chunkSize = 50
            for i in stride(from: 0, to: filteredNewReports.count, by: chunkSize) {
                let end = min(i + chunkSize, filteredNewReports.count)
                let chunk = Array(filteredNewReports[i..<end])
                
                // Update on main thread
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.filteredReports.append(contentsOf: chunk)
                    Task{
                        self.reportsCount = self.filteredReports.count
                    }
                    
                }
            }
        }
    }
    
    func resetAndReload(timeFilter: TimeFilter) {
        selectedTimeFilter = timeFilter
        groupedReports.removeAll()
        sortedDates.removeAll()
        currentPage = 0
        hasMoreData = true
        loadNextPage()
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
            self.reportsCount = self.filteredReports.count
            Task {
                await self.updateProvisionTypeDistribution()
                await self.updateOutcomesDistribution(for: self.filteredReports)
            }
        }
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
        // Create a dictionary to store theme counts
        var themeCounts: [String: Int] = [:]
        let totalReports = Double(reports.count)
        
        // Process reports in chunks for better performance
        let chunkSize = 100
        for i in stride(from: 0, to: reports.count, by: chunkSize) {
            let endIndex = min(i + chunkSize, reports.count)
            let chunk = reports[i..<endIndex]
            
            for report in chunk {
                let uniqueThemes = Set(report.themes.map { $0.topic })
                for theme in uniqueThemes {
                    themeCounts[theme, default: 0] += 1
                }
            }
        }
        
        // Convert counts to percentages
        return themeCounts.map { theme, count in
            (theme, (Double(count) / totalReports) * 100)
        }.sorted { $0.1 > $1.1 }
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
    
    private func performSearch(_ query: String) {
        guard !query.isEmpty else {
            self.searchResults = [:]
            self.searchDates = []
            return
        }

        let lowercasedQuery = query.lowercased()
        
        let results = reports.filter { report in
            // More lenient search across multiple fields
            report.referenceNumber.lowercased().contains(lowercasedQuery) ||
            report.inspector.lowercased().contains(lowercasedQuery) ||
            report.localAuthority.lowercased().contains(lowercasedQuery) ||
            report.typeOfProvision.lowercased().contains(lowercasedQuery) ||
            report.themes.contains { $0.topic.lowercased().contains(lowercasedQuery) } ||
            // Add more fields as needed
            report.date.lowercased().contains(lowercasedQuery)
        }

        Task { @MainActor in
            let groupedSearchResults = Dictionary(grouping: results) { $0.date }
            
            self.searchResults = groupedSearchResults
            self.searchDates = groupedSearchResults.keys.sorted { date1, date2 in
                guard let date1 = DateFormatter.reportDate.date(from: date1),
                      let date2 = DateFormatter.reportDate.date(from: date2) else {
                    return false
                }
                return date1 > date2
            }
        }
    }

    
    private func applyFilters(to reports: [Report]) -> [Report] {
        var filteredReports = reports
        
        // Apply inspector filter
        if let inspector = selectedInspector {
            filteredReports = filteredReports.filter { $0.inspector == inspector }
        }
        
        // Apply authority filter
        if let authority = selectedAuthority {
            filteredReports = filteredReports.filter { $0.localAuthority == authority }
        }
        
        // Apply provision type filter
        if let provisionType = selectedProvisionType {
            filteredReports = filteredReports.filter { $0.typeOfProvision == provisionType }
        }
        
        // Apply combined grade/outcome filter
        if let gradeOrOutcome = selectedRating ?? selectedOutcome {
            filteredReports = filteredReports.filter { report in
                if !report.outcome.isEmpty {
                    return report.outcome == gradeOrOutcome
                } else if let overallRating = report.ratings.first(where: { $0.category == RatingCategory.overallEffectiveness.rawValue }) {
                    return overallRating.rating == gradeOrOutcome
                }
                return false
            }
        }
        
        // Apply date range filter
        if let dateRange = selectedDateRange {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy"
            
            filteredReports = filteredReports.filter { report in
                if let date = dateFormatter.date(from: report.date) {
                    return dateRange.contains(date)
                }
                return false
            }
        }
        
        return filteredReports
    }
    
    func updateFilters() {
        Task { @MainActor in
            // Apply filters to all reports
            let filteredReports = applyFilters(to: reports)
            
            // Group filtered reports by date, handling any date formatting issues
            let groupedFiltered = Dictionary(grouping: filteredReports) { report -> String in
                if let dateComponents = report.date.components(separatedBy: " - ").last?.trimmingCharacters(in: .whitespaces),
                   let _ = dateFormatter.date(from: dateComponents) {
                    return dateComponents
                }
                return report.date // Fallback to original date if parsing fails
            }
            
            // Update both the filtered reports and the grouped reports
            self.filteredReports = filteredReports
            self.groupedReports = groupedFiltered
            
            // Sort dates safely
            self.sortedDates = groupedFiltered.keys.sorted { date1, date2 in
                if let date1Date = dateFormatter.date(from: date1),
                   let date2Date = dateFormatter.date(from: date2) {
                    return date1Date > date2Date
                }
                return date1 > date2 // Fallback to string comparison if parsing fails
            }
            
            // Also update search results if there's an active search
            if !searchText.isEmpty {
                let searchFiltered = filteredReports.filter { report in
                    let lowercasedQuery = searchText.lowercased()
                    return report.referenceNumber.lowercased().contains(lowercasedQuery) ||
                           report.inspector.lowercased().contains(lowercasedQuery) ||
                           report.localAuthority.lowercased().contains(lowercasedQuery) ||
                           report.typeOfProvision.lowercased().contains(lowercasedQuery) ||
                           report.themes.contains { $0.topic.lowercased().contains(lowercasedQuery) }
                }
                
                // Group search results using the same safe date handling
                let groupedSearchResults = Dictionary(grouping: searchFiltered) { report -> String in
                    if let dateComponents = report.date.components(separatedBy: " - ").last?.trimmingCharacters(in: .whitespaces),
                       let _ = dateFormatter.date(from: dateComponents) {
                        return dateComponents
                    }
                    return report.date
                }
                
                self.searchResults = groupedSearchResults
                self.searchDates = groupedSearchResults.keys.sorted { date1, date2 in
                    if let date1Date = dateFormatter.date(from: date1),
                       let date2Date = dateFormatter.date(from: date2) {
                        return date1Date > date2Date
                    }
                    return date1 > date2
                }
            } else {
                self.searchResults = [:]
                self.searchDates = []
            }
            
            // Update the provision type distribution
            await self.updateProvisionTypeDistribution()
            await self.updateOutcomesDistribution(for: self.filteredReports)
        }
    }
    
    func clearFilters() {
        selectedInspector = nil
        selectedAuthority = nil
        selectedProvisionType = nil
        selectedRating = nil
        selectedOutcome = nil
        selectedDateRange = nil
        updateFilters()
    }
    
    deinit {
        listener?.remove()
    }
}
