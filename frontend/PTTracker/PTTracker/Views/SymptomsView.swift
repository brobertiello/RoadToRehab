import SwiftUI

struct SymptomsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var viewModel: SymptomsViewModel
    @State private var showingAddSymptom = false
    @State private var selectedSymptom: Symptom?
    
    var body: some View {
        ZStack {
            // Ensure background is white
            Color.white.edgesIgnoringSafeArea(.all)
            
            // Main Content
            VStack {
                if viewModel.symptoms.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    symptomListView
                }
            }
            .navigationTitle("Symptoms")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddSymptom = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            
            // Loading Indicator
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.15))
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchSymptoms()
            }
        }
        .sheet(isPresented: $showingAddSymptom) {
            AddSymptomView(viewModel: viewModel)
        }
        .sheet(item: $selectedSymptom) { symptom in
            UpdateSymptomView(viewModel: viewModel, symptom: symptom)
        }
        .refreshable {
            await viewModel.fetchSymptoms()
        }
        .alert(item: alertItem) { item in
            Alert(
                title: Text(item.title),
                message: Text(item.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.path.ecg")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
                .padding(.top, 40)
            
            Text("No Symptoms Recorded")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Track your pain and symptoms by adding your first symptom.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                showingAddSymptom = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Your First Symptom")
                }
                .padding()
                .background(Color.green.opacity(0.2))
                .cornerRadius(10)
            }
            .padding(.bottom, 40)
        }
        .padding()
        .background(Color.white)
    }
    
    private var symptomListView: some View {
        List {
            ForEach(viewModel.symptoms) { symptom in
                SymptomRow(symptom: symptom)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSymptom = symptom
                    }
                    .listRowBackground(Color.white)
            }
            .onDelete { indexSet in
                Task {
                    await viewModel.deleteSymptom(at: indexSet)
                }
            }
        }
        .listStyle(PlainListStyle()) // Use plain style for cleaner appearance
        .background(Color.white)
    }
    
    private var alertItem: Binding<AlertItem?> {
        Binding<AlertItem?>(
            get: {
                if let errorMessage = viewModel.errorMessage {
                    return AlertItem(title: "Error", message: errorMessage)
                }
                return nil
            },
            set: { _ in
                viewModel.errorMessage = nil
            }
        )
    }
}

struct SymptomRow: View {
    let symptom: Symptom
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(symptom.bodyPart)
                .font(.headline)
            
            HStack {
                Text("Pain Level: \(symptom.currentSeverity)/10")
                    .font(.subheadline)
                
                Spacer()
                
                Text(symptom.lastUpdated)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Progress bar for pain level
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 8)
                        .opacity(0.2)
                        .foregroundColor(.gray)
                    
                    Rectangle()
                        .frame(width: CGFloat(symptom.currentSeverity) / 10.0 * geometry.size.width, height: 8)
                        .foregroundColor(painColor(for: symptom.currentSeverity))
                }
                .cornerRadius(4)
            }
            .frame(height: 8)
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
        .background(Color.white)
    }
    
    private func painColor(for severity: Int) -> Color {
        switch severity {
        case 0...3:
            return .green
        case 4...6:
            return .orange
        default:
            return .red
        }
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
} 