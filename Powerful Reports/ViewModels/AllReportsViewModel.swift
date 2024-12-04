import SwiftUI

@MainActor class AllReportsViewModel: ObservableObject {
    @Published private(set) var filteredReports: [Report] = []
    @Published private(set) var groupedReports: [String: [Report]] = [:]
    @Published private(set) var sortedDates: [String] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasActiveFilters = false
    
    // Pagination properties
    private var allDates: [String] = []
    private var displayedDatesCount = 50
    private var reportsPerPage = 20
    private var displayedReportsCount: [String: Int] = [:]
    
    // Cache for performance
    private var reportCountCache: Int = 0
    private var activeFiltersCache: [ActiveFilter] = []
    private var filterRestored = false
    
    enum FilterType: String, Hashable {
        case inspector
        case authority
        case provisionType
        case rating
        case outcome
        case dateRange
    }
    
    struct ActiveFilter: Hashable {
        let type: FilterType
        let text: String
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(text)
        }
        
        static func == (lhs: ActiveFilter, rhs: ActiveFilter) -> Bool {
            return lhs.type == rhs.type && lhs.text == rhs.text
        }
    }
    
    @Published var selectedInspector: String? {
        didSet {
            if let inspector = selectedInspector {
                UserDefaults.standard.set(inspector, forKey: "allReports.inspector")
            } else {
                UserDefaults.standard.removeObject(forKey: "allReports.inspector")
            }
            // Reset dependent filters if the selected inspector doesn't have reports in the current authority
            if let authority = selectedAuthority,
               !availableAuthorities.contains(authority) {
                selectedAuthority = nil
            }
            updateFilters()
        }
    }
    
    @Published var selectedAuthority: String? {
        didSet {
            if let authority = selectedAuthority {
                UserDefaults.standard.set(authority, forKey: "allReports.authority")
            } else {
                UserDefaults.standard.removeObject(forKey: "allReports.authority")
            }
            // Reset dependent filters if the selected authority doesn't have reports from the current inspector
            if let inspector = selectedInspector,
               !availableInspectors.contains(inspector) {
                selectedInspector = nil
            }
            updateFilters()
        }
    }
    
    @Published var selectedProvisionType: String? {
        didSet {
            if let type = selectedProvisionType {
                UserDefaults.standard.set(type, forKey: "allReports.provisionType")
            } else {
                UserDefaults.standard.removeObject(forKey: "allReports.provisionType")
            }
            updateFilters()
        }
    }
    
    @Published var selectedRating: String? {
        didSet {
            if let rating = selectedRating {
                UserDefaults.standard.set(rating, forKey: "allReports.rating")
            } else {
                UserDefaults.standard.removeObject(forKey: "allReports.rating")
            }
            updateFilters()
        }
    }
    
    @Published var selectedOutcome: String? {
        didSet {
            if let outcome = selectedOutcome {
                UserDefaults.standard.set(outcome, forKey: "allReports.outcome")
            } else {
                UserDefaults.standard.removeObject(forKey: "allReports.outcome")
            }
            updateFilters()
        }
    }
    
    @Published var selectedDateRange: DateInterval? {
        didSet {
            if let range = selectedDateRange {
                UserDefaults.standard.set(range.start.timeIntervalSince1970, forKey: "allReports.dateRange.start")
                UserDefaults.standard.set(range.end.timeIntervalSince1970, forKey: "allReports.dateRange.end")
            } else {
                UserDefaults.standard.removeObject(forKey: "allReports.dateRange.start")
                UserDefaults.standard.removeObject(forKey: "allReports.dateRange.end")
            }
            updateFilters()
        }
    }
    
    private let mainViewModel: InspectionReportsViewModel
    private let dateFormatter: DateFormatter
    
    init(mainViewModel: InspectionReportsViewModel) {
        self.mainViewModel = mainViewModel
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "dd/MM/yyyy"
        
        // Initialize with empty values first
        self.selectedInspector = nil
        self.selectedAuthority = nil
        self.selectedProvisionType = nil
        self.selectedRating = nil
        self.selectedOutcome = nil
        
        // Load data asynchronously
        Task { @MainActor in
            isLoading = true
            defer { isLoading = false }
            
            // Restore filters safely
            if let inspector = UserDefaults.standard.string(forKey: "allReports.inspector"),
               availableInspectors.contains(inspector) {
                selectedInspector = inspector
            }
            
            if let authority = UserDefaults.standard.string(forKey: "allReports.authority"),
               availableAuthorities.contains(authority) {
                selectedAuthority = authority
            }
            
            if let type = UserDefaults.standard.string(forKey: "allReports.provisionType"),
               availableProvisionTypes.contains(type) {
                selectedProvisionType = type
            }
            
            if let rating = UserDefaults.standard.string(forKey: "allReports.rating"),
               availableRatings.contains(rating) {
                selectedRating = rating
            }
            
            if let outcome = UserDefaults.standard.string(forKey: "allReports.outcome"),
               availableOutcomes.contains(outcome) {
                selectedOutcome = outcome
            }
            
            // Restore date range if it exists
            if let startTimestamp = UserDefaults.standard.object(forKey: "allReports.dateRange.start") as? TimeInterval,
               let endTimestamp = UserDefaults.standard.object(forKey: "allReports.dateRange.end") as? TimeInterval {
                let startDate = Date(timeIntervalSince1970: startTimestamp)
                let endDate = Date(timeIntervalSince1970: endTimestamp)
                selectedDateRange = DateInterval(start: startDate, end: endDate)
            }
            
            filterRestored = true
            updateFilters()
        }
    }
    
    var uniqueInspectors: [String] {
        guard !mainViewModel.reports.isEmpty else { return [] }
        return Array(Set(mainViewModel.reports.map { $0.inspector })).sorted()
    }
    
    var uniqueAuthorities: [String] {
        guard !mainViewModel.reports.isEmpty else { return [] }
        return Array(Set(mainViewModel.reports.map { $0.localAuthority })).sorted()
    }
    
    var uniqueProvisionTypes: [String] {
        guard !mainViewModel.reports.isEmpty else { return [] }
        return Array(Set(mainViewModel.reports.map { $0.typeOfProvision })).sorted()
    }
    
    var uniqueGradesAndOutcomes: [(String, Color)] {
        let allValues = RatingValue.allCases
            .filter { $0 != .none }
            .map { ($0.rawValue, $0.color) }
        return allValues.sorted { $0.0 < $1.0 }
    }
    
    var availableInspectors: [String] {
        let allReports = mainViewModel.reports
        guard !allReports.isEmpty else { return [] }
        
        if let selectedAuthority = selectedAuthority {
            return Array(Set(allReports.filter { $0.localAuthority == selectedAuthority }
                .map { $0.inspector }))
                .sorted()
        }
        
        return Array(Set(allReports.map { $0.inspector })).sorted()
    }
    
    var availableAuthorities: [String] {
        let allReports = mainViewModel.reports
        guard !allReports.isEmpty else { return [] }
        
        if let selectedInspector = selectedInspector {
            return Array(Set(allReports.filter { $0.inspector == selectedInspector }
                .map { $0.localAuthority }))
                .sorted()
        }
        
        return Array(Set(allReports.map { $0.localAuthority })).sorted()
    }
    
    var availableProvisionTypes: [String] {
        let filteredReports = mainViewModel.reports.filter { report in
            var matches = true
            
            if let inspector = selectedInspector {
                matches = matches && report.inspector == inspector
            }
            if let authority = selectedAuthority {
                matches = matches && report.localAuthority == authority
            }
            
            return matches
        }
        
        guard !filteredReports.isEmpty else { return [] }
        
        return Array(Set(filteredReports.map { $0.typeOfProvision })).sorted()
    }
    
    var availableRatings: [String] {
        let filteredReports = mainViewModel.reports.filter { report in
            var matches = true
            
            if let inspector = selectedInspector {
                matches = matches && report.inspector == inspector
            }
            if let authority = selectedAuthority {
                matches = matches && report.localAuthority == authority
            }
            if let typeOfProvision = selectedProvisionType {
                matches = matches && report.typeOfProvision == typeOfProvision
            }
            
            return matches
        }
        
        guard !filteredReports.isEmpty else { return [] }
        
        return Array(Set(filteredReports.compactMap { $0.overallRating })).sorted()
    }
    
    var availableOutcomes: [String] {
        let filteredReports = mainViewModel.reports.filter { report in
            var matches = true
            
            if let inspector = selectedInspector {
                matches = matches && report.inspector == inspector
            }
            if let authority = selectedAuthority {
                matches = matches && report.localAuthority == authority
            }
            if let typeOfProvision = selectedProvisionType {
                matches = matches && report.typeOfProvision == typeOfProvision
            }
            
            return matches
        }
        
        guard !filteredReports.isEmpty else { return [] }
        
        return Array(Set(filteredReports.map { $0.outcome }.filter { !$0.isEmpty })).sorted()
    }
    
    var totalReportsCount: Int {
        reportCountCache
    }
    
    var activeFilters: [ActiveFilter] {
        var filters: [ActiveFilter] = []
        
        if let inspector = selectedInspector {
            filters.append(ActiveFilter(type: .inspector, text: inspector))
        }
        if let authority = selectedAuthority {
            filters.append(ActiveFilter(type: .authority, text: authority))
        }
        if let type = selectedProvisionType {
            filters.append(ActiveFilter(type: .provisionType, text: type))
        }
        if let rating = selectedRating {
            filters.append(ActiveFilter(type: .rating, text: rating))
        }
        if let outcome = selectedOutcome {
            filters.append(ActiveFilter(type: .outcome, text: outcome))
        }
        if let dateRange = selectedDateRange {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            let dateString = "\(formatter.string(from: dateRange.start)) - \(formatter.string(from: dateRange.end))"
            filters.append(ActiveFilter(type: .dateRange, text: dateString))
        }
        
        return filters
    }
    
    func clearFilter(_ filterType: FilterType) {
        switch filterType {
        case .inspector:
            selectedInspector = nil
        case .authority:
            selectedAuthority = nil
        case .provisionType:
            selectedProvisionType = nil
        case .rating:
            selectedRating = nil
        case .outcome:
            selectedOutcome = nil
        case .dateRange:
            selectedDateRange = nil
        }
        updateFilters()
    }
    
    func loadMoreDates() {
        guard displayedDatesCount < allDates.count else { return }
        
        displayedDatesCount += 50
        updateSortedDates()
    }
    
    func loadMoreReports(for date: String) {
        guard let currentCount = displayedReportsCount[date],
              let totalReportsForDate = groupedReports[date]?.count,
              currentCount < totalReportsForDate else {
            return
        }
        
        displayedReportsCount[date] = min(currentCount + reportsPerPage, totalReportsForDate)
        objectWillChange.send()
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
    
    func updateFilters() {
        guard filterRestored else { return }
        
        Task { @MainActor in
            isLoading = true
            defer { isLoading = false }
            
            let filtered = applyFilters(to: mainViewModel.reports)
            filteredReports = filtered
            reportCountCache = filtered.count
            
            processReports(filtered)
            
            // Update hasActiveFilters based on active filters
            hasActiveFilters = selectedInspector != nil ||
                             selectedAuthority != nil ||
                             selectedProvisionType != nil ||
                             selectedRating != nil ||
                             selectedOutcome != nil ||
                             selectedDateRange != nil
        }
    }
    
    func resetAndReload(timeFilter: TimeFilter) {
        Task { @MainActor in
            isLoading = true
            defer { isLoading = false }
            
            // Reset pagination
            displayedDatesCount = 50
            displayedReportsCount = [:]
            
            // Update filters with new time filter
            selectedDateRange = timeFilter.dateInterval
            updateFilters()
        }
    }
    
    private func processReports(_ reports: [Report]) {
        // Group reports by date
        var newGroupedReports: [String: [Report]] = [:]
        for report in reports {
            let dateString = report.date
            if newGroupedReports[dateString] == nil {
                newGroupedReports[dateString] = []
            }
            newGroupedReports[dateString]?.append(report)
        }
        
        // Sort reports within each group
        for (date, reports) in newGroupedReports {
            newGroupedReports[date] = reports.sorted { $0.date > $1.date }
        }
        
        groupedReports = newGroupedReports
        
        // Sort dates in descending order
        allDates = Array(newGroupedReports.keys).sorted { date1, date2 in
            if let date1Date = dateFormatter.date(from: date1),
               let date2Date = dateFormatter.date(from: date2) {
                return date1Date > date2Date
            }
            return date1 > date2
        }
        
        // Update sortedDates directly with all dates
        sortedDates = allDates
        
        // Update cache
        activeFiltersCache = activeFilters
    }
    
    private func updateSortedDates() {
        // Show all dates without pagination
        sortedDates = allDates
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
        if let typeOfProvision = selectedProvisionType {
            filteredReports = filteredReports.filter { $0.typeOfProvision == typeOfProvision }
        }
        
        // Apply rating filter
        if let rating = selectedRating {
            filteredReports = filteredReports.filter { $0.overallRating == rating }
        }
        
        // Apply outcome filter
        if let outcome = selectedOutcome {
            filteredReports = filteredReports.filter { $0.outcome == outcome }
        }
        
        // Apply date range filter
        if let dateRange = selectedDateRange {
            filteredReports = filteredReports.filter { report in
                if let dateStr = report.date.components(separatedBy: " - ").last?.trimmingCharacters(in: .whitespaces),
                   let date = dateFormatter.date(from: dateStr) {
                    return dateRange.contains(date)
                }
                return false
            }
        }
        
        return filteredReports
    }
}
