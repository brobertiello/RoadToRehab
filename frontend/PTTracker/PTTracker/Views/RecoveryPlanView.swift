import SwiftUI

struct RecoveryPlanView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var symptomViewModel: SymptomsViewModel
    @EnvironmentObject var exercisesViewModel: ExercisesViewModel
    
    @State private var showingGenerateSheet = false
    @State private var selectedDate: Date = Date()
    @State private var selectedTabIndex = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector for Weekly/Calendar/List views
                Picker("View Mode", selection: $selectedTabIndex) {
                    Text("Weekly").tag(0)
                    Text("Calendar").tag(1)
                    Text("List").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Filter by symptom
                if !symptomViewModel.symptoms.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            Button(action: {
                                exercisesViewModel.filterBySymptom(symptomId: nil)
                            }) {
                                Text("All")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(exercisesViewModel.filterSymptomId == nil ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(exercisesViewModel.filterSymptomId == nil ? .white : .primary)
                                    .cornerRadius(20)
                            }
                            
                            ForEach(symptomViewModel.symptoms) { symptom in
                                Button(action: {
                                    exercisesViewModel.filterBySymptom(symptomId: symptom.id)
                                }) {
                                    Text(symptom.bodyPart)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(exercisesViewModel.filterSymptomId == symptom.id ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundColor(exercisesViewModel.filterSymptomId == symptom.id ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
                
                Divider()
                
                // Content based on selected tab
                if exercisesViewModel.isLoading {
                    ProgressView("Loading exercises...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = exercisesViewModel.errorMessage {
                    VStack {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                        Button("Retry") {
                            Task {
                                await exercisesViewModel.fetchExercises()
                            }
                        }
                        .padding()
                    }
                } else {
                    TabView(selection: $selectedTabIndex) {
                        // Weekly view
                        WeeklyView(viewModel: exercisesViewModel, selectedDate: $selectedDate)
                            .tag(0)
                        
                        // Calendar view
                        CalendarView(viewModel: exercisesViewModel, selectedDate: $selectedDate)
                            .tag(1)
                        
                        // List view
                        ExerciseListView(viewModel: exercisesViewModel)
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: selectedTabIndex)
                }
            }
            .navigationTitle("Recovery Plan")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingGenerateSheet = true
                    }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("Generate")
                        }
                    }
                    .disabled(symptomViewModel.symptoms.isEmpty)
                }
            }
            .sheet(isPresented: $showingGenerateSheet) {
                GenerateExercisesView(isPresented: $showingGenerateSheet, exercisesViewModel: exercisesViewModel)
            }
        }
        .onAppear {
            Task {
                await exercisesViewModel.fetchExercises()
            }
        }
    }
}

// Weekly view component
struct WeeklyView: View {
    @ObservedObject var viewModel: ExercisesViewModel
    @Binding var selectedDate: Date
    
    var body: some View {
        VStack {
            // Week navigation
            HStack {
                Text(weekRange)
                    .font(.headline)
                Spacer()
                HStack(spacing: 20) {
                    Button(action: { moveToPreviousWeek() }) {
                        Image(systemName: "chevron.left")
                    }
                    Button(action: { moveToNextWeek() }) {
                        Image(systemName: "chevron.right")
                    }
                }
            }
            .padding(.horizontal)
            
            // Days of week
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            // Week days with exercise indicators
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(weekDates, id: \.self) { date in
                    VStack {
                        Text(date.formatted(.dateTime.day()))
                            .padding(8)
                            .background(isSelected(date) ? Color.blue : Color.clear)
                            .foregroundColor(isSelected(date) ? .white : .primary)
                            .clipShape(Circle())
                        
                        // Exercise indicators
                        let exercisesForDay = viewModel.exercisesForDate(date)
                        if !exercisesForDay.isEmpty {
                            Text("\(exercisesForDay.count)")
                                .font(.caption)
                                .padding(4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
            .padding(.horizontal)
            
            Divider()
                .padding(.vertical)
            
            // Exercises for selected day
            if viewModel.exercisesForDate(selectedDate).isEmpty {
                VStack {
                    Text("No exercises for \(selectedDate.formatted(.dateTime.month().day()))")
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                }
            } else {
                List {
                    ForEach(viewModel.exercisesForDate(selectedDate)) { exercise in
                        ExerciseRowView(
                            exercise: exercise,
                            toggleCompletion: {
                                Task {
                                    await viewModel.toggleExerciseCompletion(exercise: exercise)
                                }
                            },
                            viewModel: viewModel
                        )
                    }
                }
            }
        }
    }
    
    // Helper computed properties for week view
    private var weekRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        if let firstDay = weekDates.first, let lastDay = weekDates.last {
            return "\(formatter.string(from: firstDay)) - \(formatter.string(from: lastDay))"
        }
        return ""
    }
    
    private var weekdays: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        
        var days: [String] = []
        for i in 0..<7 {
            let day = Calendar.current.date(byAdding: .day, value: i, to: startOfWeek)!
            days.append(formatter.string(from: day))
        }
        return days
    }
    
    private var startOfWeek: Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)
        return calendar.date(from: components) ?? selectedDate
    }
    
    private var weekDates: [Date] {
        var dates: [Date] = []
        for i in 0..<7 {
            if let date = Calendar.current.date(byAdding: .day, value: i, to: startOfWeek) {
                dates.append(date)
            }
        }
        return dates
    }
    
    private func isSelected(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    private func moveToPreviousWeek() {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func moveToNextWeek() {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

// Calendar view component
struct CalendarView: View {
    @ObservedObject var viewModel: ExercisesViewModel
    @Binding var selectedDate: Date
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack {
            // Month navigation
            HStack {
                Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                Spacer()
                HStack(spacing: 20) {
                    Button(action: { moveToPreviousMonth() }) {
                        Image(systemName: "chevron.left")
                    }
                    Button(action: { moveToNextMonth() }) {
                        Image(systemName: "chevron.right")
                    }
                }
            }
            .padding(.horizontal)
            
            // Days of week header
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            // Calendar grid
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(daysInMonth(), id: \.self) { date in
                    CalendarCellView(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        currentMonth: isInCurrentMonth(date),
                        exerciseCount: viewModel.exercisesForDate(date).count
                    )
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
            .padding(.horizontal)
            
            Divider()
                .padding(.vertical)
            
            // Exercises for selected day
            if viewModel.exercisesForDate(selectedDate).isEmpty {
                VStack {
                    Text("No exercises for \(selectedDate.formatted(.dateTime.month().day()))")
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                }
            } else {
                List {
                    ForEach(viewModel.exercisesForDate(selectedDate)) { exercise in
                        ExerciseRowView(
                            exercise: exercise,
                            toggleCompletion: {
                                Task {
                                    await viewModel.toggleExerciseCompletion(exercise: exercise)
                                }
                            },
                            viewModel: viewModel
                        )
                    }
                }
            }
        }
    }
    
    // Helper methods for calendar
    private func daysInMonth() -> [Date] {
        let calendar = Calendar.current
        
        // Get start of the month
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        let startOfMonth = calendar.date(from: components)!
        
        // Get the first weekday of the month (0 is Sunday, 1 is Monday, etc.)
        let firstWeekdayOfMonth = calendar.component(.weekday, from: startOfMonth) - 1
        
        // Get the number of days in the month
        let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)!.count
        
        // Get previous month days to fill in the first row
        let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: startOfMonth)!
        let previousMonthComponents = calendar.dateComponents([.year, .month], from: previousMonthDate)
        let startOfPreviousMonth = calendar.date(from: previousMonthComponents)!
        let daysInPreviousMonth = calendar.range(of: .day, in: .month, for: startOfPreviousMonth)!.count
        
        var days: [Date] = []
        
        // Add days from previous month to fill the first row
        for day in 1...firstWeekdayOfMonth {
            let previousDay = daysInPreviousMonth - firstWeekdayOfMonth + day
            if let date = calendar.date(byAdding: .day, value: previousDay - 1, to: startOfPreviousMonth) {
                days.append(date)
            }
        }
        
        // Add days from current month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        // Add days from next month to complete the grid (6 rows x 7 columns = 42 cells)
        let remainingCells = 42 - days.count
        for day in 1...remainingCells {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: calendar.date(byAdding: .month, value: 1, to: startOfMonth)!) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func isInCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.component(.month, from: date) == calendar.component(.month, from: selectedDate)
    }
    
    private func moveToPreviousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func moveToNextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

// Calendar Cell View
struct CalendarCellView: View {
    let date: Date
    let isSelected: Bool
    let currentMonth: Bool
    let exerciseCount: Int
    
    var body: some View {
        VStack {
            Text(date.formatted(.dateTime.day()))
                .foregroundColor(cellTextColor)
                .padding(8)
                .background(isSelected ? Color.blue : Color.clear)
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Circle())
            
            if exerciseCount > 0 {
                Text("\(exerciseCount)")
                    .font(.caption)
                    .padding(4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(10)
            }
        }
        .frame(height: 50)
    }
    
    var cellTextColor: Color {
        if isSelected {
            return .white
        } else if !currentMonth {
            return .gray
        } else {
            return .primary
        }
    }
}

// List view component
struct ExerciseListView: View {
    @ObservedObject var viewModel: ExercisesViewModel
    
    var body: some View {
        if viewModel.filteredExercises.isEmpty {
            VStack {
                Text("No exercises found")
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            }
        } else {
            List {
                ForEach(groupedExercises.keys.sorted(), id: \.self) { date in
                    if let exercises = groupedExercises[date] {
                        Section(header: Text(dateFormatter.string(from: date))) {
                            ForEach(exercises) { exercise in
                                ExerciseRowView(
                                    exercise: exercise,
                                    toggleCompletion: {
                                        Task {
                                            await viewModel.toggleExerciseCompletion(exercise: exercise)
                                        }
                                    },
                                    viewModel: viewModel
                                )
                                .swipeActions {
                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.deleteExercise(id: exercise.id)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Group exercises by date
    var groupedExercises: [Date: [Exercise]] {
        viewModel.exercisesByDay()
    }
    
    // Date formatter for section headers
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

// Exercise Row View
struct ExerciseRowView: View {
    let exercise: Exercise
    let toggleCompletion: () -> Void
    @ObservedObject var viewModel: ExercisesViewModel
    
    var body: some View {
        NavigationLink(destination: ExerciseDetailView(viewModel: viewModel, exercise: exercise)) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(exercise.exerciseType)
                            .font(.headline)
                            .foregroundColor(exercise.completed ? .gray : .primary)
                            .strikethrough(exercise.completed)
                        
                        Text(exercise.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Button(action: toggleCompletion) {
                        Image(systemName: exercise.completed ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(exercise.completed ? .green : .gray)
                            .font(.title2)
                    }
                }
                
                HStack {
                    Text(exercise.formattedDuration)
                        .font(.caption)
                        .padding(5)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(5)
                    
                    Text(exercise.difficultyText)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                if let notes = exercise.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 5)
        }
    }
}

// Preview provider
struct RecoveryPlanView_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryPlanView()
            .environmentObject(AuthManager.shared)
            .environmentObject(SymptomsViewModel(authManager: AuthManager.shared))
            .environmentObject(ExercisesViewModel(authManager: AuthManager.shared))
    }
} 