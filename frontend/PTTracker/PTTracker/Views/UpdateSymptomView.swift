import SwiftUI
import Charts

struct UpdateSymptomView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: SymptomsViewModel
    let symptom: Symptom
    
    @State private var severity: Int
    @State private var notes: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    init(viewModel: SymptomsViewModel, symptom: Symptom) {
        self.viewModel = viewModel
        self.symptom = symptom
        self._severity = State(initialValue: symptom.currentSeverity)
        self._notes = State(initialValue: symptom.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Update Pain Level")) {
                    HStack {
                        Text("Body Part:")
                            .fontWeight(.semibold)
                        Text(symptom.bodyPart)
                            .foregroundColor(.primary)
                    }
                    
                    Text("Last recorded: \(symptom.lastUpdated)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading) {
                        Text("Current Pain Severity: \(severity)")
                        HStack {
                            Text("0")
                            Slider(value: Binding(
                                get: { Double(severity) },
                                set: { severity = Int($0) }
                            ), in: 0...10, step: 1)
                            Text("10")
                        }
                    }
                    .padding(.vertical)
                }
                
                Section(header: Text("Additional Notes (Optional)")) {
                    TextField("Describe your symptoms...", text: $notes)
                    Text("Add details about your symptoms that might help with recovery planning")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if symptom.severities.count > 1 {
                    Section(header: Text("Pain History")) {
                        SeverityHistoryChart(severities: symptom.severities)
                            .frame(height: 200)
                            .padding(.vertical, 8)
                        
                        // Display historical notes
                        if symptom.severities.contains(where: { $0.notes != nil }) {
                            Divider()
                                .padding(.vertical, 4)
                            
                            Text("Historical Notes:")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            // Show notes from each severity entry, newest first
                            let sortedSeverities = symptom.severities
                                .sorted(by: { $0.date > $1.date })
                                .filter { $0.notes != nil && !$0.notes!.isEmpty }
                            
                            ForEach(sortedSeverities) { severity in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(formatDate(severity.date))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text("(Pain Level: \(severity.value))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text(severity.notes ?? "")
                                        .padding(.bottom, 8)
                                    
                                    if severity != sortedSeverities.last {
                                        Divider()
                                            .padding(.bottom, 8)
                                    }
                                }
                            }
                        }
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button {
                        updateSymptom()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Update Pain Level")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .listRowBackground(Color.blue)
                    .disabled(isLoading)
                }
            }
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
    
    var body: some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(chartData) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Pain Level", dataPoint.value)
                    )
                    .foregroundStyle(Color.red.gradient)
                    .interpolationMethod(.cardinal)
                    
                    PointMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Pain Level", dataPoint.value)
                    )
                    .foregroundStyle(Color.red)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: min(chartData.count, 5))) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(dateFormatter.string(from: date))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: .stride(by: 1)) { value in
                    if let intValue = value.as(Int.self), intValue <= 10 {
                        AxisValueLabel {
                            Text("\(intValue)")
                        }
                    }
                }
            }
            .chartYScale(domain: 0...10)
        } else {
            // Fallback for iOS 15
            Text("Pain history chart requires iOS 16 or later")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
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