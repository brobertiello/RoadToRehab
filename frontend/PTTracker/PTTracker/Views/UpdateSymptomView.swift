import SwiftUI
import Charts

struct UpdateSymptomView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: SymptomsViewModel
    let symptom: Symptom
    
    @State private var severity: Int
    @State private var notes: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showHistoricalNotes = false
    
    init(viewModel: SymptomsViewModel, symptom: Symptom) {
        self.viewModel = viewModel
        self.symptom = symptom
        self._severity = State(initialValue: symptom.currentSeverity)
    }
    
    // Computed property to get unique notes entries
    private var uniqueNotesEntries: [Severity] {
        let sortedSeverities = symptom.severities
            .sorted(by: { $0.date > $1.date })
            .filter { $0.notes != nil && !$0.notes!.isEmpty }
        
        var uniqueEntries: [Severity] = []
        var seenNotes = Set<String>()
        
        for severity in sortedSeverities {
            if let notes = severity.notes, !seenNotes.contains(notes) {
                uniqueEntries.append(severity)
                seenNotes.insert(notes)
            }
        }
        
        return uniqueEntries
    }
    
    // Get color for severity level
    private func severityColor(_ value: Int) -> Color {
        switch value {
        case 0...3: return .green
        case 4...6: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                // SECTION 1: Current Symptom Info
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        // Body part with badge
                        HStack {
                            Text(symptom.bodyPart)
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text("Current: \(symptom.currentSeverity)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(severityColor(symptom.currentSeverity))
                                .cornerRadius(16)
                        }
                        
                        // Last updated info
                        Text("Last updated: \(symptom.lastUpdated)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Current Status")
                        .font(.headline)
                }
                
                // SECTION 2: Pain History Graph
                if symptom.severities.count > 1 {
                    Section {
                        SeverityHistoryChart(severities: symptom.severities)
                            .frame(height: 220)
                            .padding(.vertical, 8)
                    } header: {
                        Text("Pain History")
                            .font(.headline)
                    }
                } else {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.xyaxis.line")
                                .font(.system(size: 36))
                                .foregroundColor(.gray.opacity(0.7))
                                .padding(.top, 12)
                            
                            Text("No historical data available yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Track your symptoms over time to see your progress")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.bottom, 12)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } header: {
                        Text("Pain History")
                            .font(.headline)
                    }
                }
                
                // SECTION 3: Historical Notes (Collapsible)
                if !uniqueNotesEntries.isEmpty {
                    Section {
                        DisclosureGroup(
                            isExpanded: $showHistoricalNotes,
                            content: {
                                VStack(alignment: .leading, spacing: 16) {
                                    ForEach(uniqueNotesEntries) { severity in
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text(formatDate(severity.date))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                
                                                Spacer()
                                                
                                                Text("Level: \(severity.value)")
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(severityColor(severity.value))
                                                    .cornerRadius(12)
                                            }
                                            
                                            Text(severity.notes ?? "")
                                                .font(.subheadline)
                                                .padding(.vertical, 4)
                                            
                                            if severity != uniqueNotesEntries.last {
                                                Divider()
                                                    .padding(.vertical, 4)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            },
                            label: {
                                HStack {
                                    Text("Previous Notes")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text("\(uniqueNotesEntries.count) \(uniqueNotesEntries.count == 1 ? "entry" : "entries")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        )
                    }
                }
                
                // SECTION 4: New Entry
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        // Pain level selection
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Pain Level:")
                                    .fontWeight(.medium)
                                Text("\(severity)")
                                    .fontWeight(.bold)
                                    .foregroundColor(severityColor(severity))
                            }
                            
                            // Pain level slider
                            Slider(value: Binding(
                                get: { Double(severity) },
                                set: { severity = Int($0) }
                            ), in: 0...10, step: 1)
                            .accentColor(severityColor(severity))
                        }
                        .padding(.vertical, 4)
                        
                        // Notes field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (Optional)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $notes)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("New Entry")
                        .font(.headline)
                }
                
                // Error message section
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.callout)
                            .padding(.vertical, 4)
                    }
                }
                
                // Submit button section
                Section {
                    Button {
                        updateSymptom()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Save New Entry")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                        }
                    }
                    .listRowBackground(Color.blue)
                    .disabled(isLoading)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Update Symptom")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    private func updateSymptom() {
        isLoading = true
        errorMessage = nil
        
        // Trim notes and set to nil if empty
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let notesToSend = trimmedNotes.isEmpty ? nil : trimmedNotes
        
        Task {
            do {
                try await viewModel.updateSymptom(symptomId: symptom.id, severity: severity, notes: notesToSend)
                DispatchQueue.main.async {
                    isLoading = false
                    dismiss()
                }
            } catch APIError.requestFailed(let message) {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = message
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "An error occurred: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Helper function to format dates
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct SeverityHistoryChart: View {
    let severities: [Severity]
    
    var chartData: [ChartDataPoint] {
        // Create a sorted array of data points from oldest to newest
        let sortedSeverities = severities.sorted { $0.date < $1.date }
        return sortedSeverities.map { severity in
            ChartDataPoint(date: severity.date, value: severity.value)
        }
    }
    
    // Date formatter for the x-axis
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }()
    
    // Get color for severity level
    private func severityColor(_ value: Int) -> Color {
        switch value {
        case 0...3: return .green
        case 4...6: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        if #available(iOS 16.0, *) {
            VStack(alignment: .leading, spacing: 12) {
                Chart {
                    ForEach(chartData) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Pain Level", dataPoint.value)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.linear)
                        
                        PointMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Pain Level", dataPoint.value)
                        )
                        .foregroundStyle(severityColor(dataPoint.value))
                        .symbolSize(CGSize(width: 10, height: 10))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: min(chartData.count, 5))) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(dateFormatter.string(from: date))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .stride(by: 1)) { value in
                        if let intValue = value.as(Int.self), intValue <= 10 {
                            AxisValueLabel {
                                Text("\(intValue)")
                                    .font(.caption)
                            }
                            AxisGridLine()
                        }
                    }
                }
                .chartYScale(domain: 0...10)
                .frame(height: 220)
                .padding(.vertical, 8)
            }
        } else {
            // Fallback for iOS 15
            VStack(alignment: .center) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                    .padding(.bottom, 8)
                
                Text("Pain history chart requires iOS 16 or later")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
}

// Data structure for the chart
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Int
}

// Extension to check if an optional string is nil or empty
extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        return self == nil || self!.isEmpty
    }
} 