import SwiftUI

struct RecoveryPlanCalendarView: View {
    @ObservedObject var viewModel: RecoveryPlanViewModel
    @State private var selectedDate = Date()
    @State private var calendarId = UUID()
    @State private var weekOffset = 0
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 20) {
            // Weekly calendar navigation
            HStack {
                Button(action: {
                    weekOffset -= 1
                    updateSelectedDate()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                        .padding(10)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                }
                
                Spacer()
                
                Text(getWeekHeader())
                    .font(.headline)
                    .animation(.none)
                
                Spacer()
                
                Button(action: {
                    weekOffset += 1
                    updateSelectedDate()
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                        .padding(10)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            // Days of the week
            weekView
                .padding(.horizontal)
            
            Divider()
            
            // Exercises for the selected day
            ScrollView {
                if let exercisesForDay = getExercisesForSelectedDate() {
                    if exercisesForDay.isEmpty {
                        restDayView
                    } else {
                        exerciseListView(exercises: exercisesForDay)
                    }
                } else {
                    Text("No recovery plan available")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                }
            }
            .padding(.top)
        }
    }
    
    private var weekView: some View {
        HStack {
            ForEach(getDaysOfWeek(), id: \.self) { date in
                VStack(spacing: 8) {
                    // Day name
                    Text(formatWeekDay(date))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // Day number
                    Button(action: {
                        selectedDate = date
                    }) {
                        ZStack {
                            Circle()
                                .fill(calendar.isDate(date, inSameDayAs: selectedDate) ? Color.blue : Color.clear)
                                .frame(width: 36, height: 36)
                            
                            Text("\(calendar.component(.day, from: date))")
                                .font(.subheadline)
                                .fontWeight(calendar.isDate(date, inSameDayAs: selectedDate) ? .bold : .regular)
                                .foregroundColor(calendar.isDate(date, inSameDayAs: selectedDate) ? .white : .primary)
                        }
                    }
                    
                    // Exercise indicator
                    if let count = getExerciseCount(for: date), count > 0 {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 6, height: 6)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func exerciseListView(exercises: [RecoveryExercise]) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Exercises for \(dateFormatter.string(from: selectedDate))")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(exercises.indices, id: \.self) { index in
                exerciseRow(exercise: exercises[index], index: index)
            }
        }
    }
    
    private func exerciseRow(exercise: RecoveryExercise, index: Int) -> some View {
        Button(action: {
            viewModel.showExerciseDetails(exercise: exercise, weekNumber: findWeekNumber(for: exercise))
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    // Exercise number and completion indicator
                    ZStack {
                        Circle()
                            .fill(exercise.isCompleted ? Color.green : Color.gray.opacity(0.2))
                            .frame(width: 30, height: 30)
                        
                        if exercise.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(exercise.frequency)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                    
                    Text(exercise.bodyPart)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
                
                Text(exercise.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // View details button
                HStack {
                    Spacer()
                    
                    Text("View Details")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(exercise.isCompleted ? Color.green.opacity(0.05) : Color.gray.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(exercise.isCompleted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var restDayView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 50))
                .foregroundColor(.blue.opacity(0.7))
                .padding(.top, 40)
            
            Text("Rest Day")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("No exercises scheduled for today. Take time to rest and recover.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Methods
    
    private func getDaysOfWeek() -> [Date] {
        guard let startOfWeek = getStartOfCurrentWeek() else {
            return []
        }
        
        var weekDays: [Date] = []
        for day in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: day, to: startOfWeek) {
                weekDays.append(date)
            }
        }
        
        return weekDays
    }
    
    private func getStartOfCurrentWeek() -> Date? {
        let today = Date()
        let baseStartOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))
        
        // Apply the week offset
        return calendar.date(byAdding: .weekOfYear, value: weekOffset, to: baseStartOfWeek ?? today)
    }
    
    private func formatWeekDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    private func getWeekHeader() -> String {
        guard let startOfWeek = getStartOfCurrentWeek(),
              let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
            return "Current Week"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
    }
    
    private func updateSelectedDate() {
        guard let startOfWeek = getStartOfCurrentWeek() else { return }
        selectedDate = startOfWeek
        calendarId = UUID() // Force refresh
    }
    
    private func getExercisesForSelectedDate() -> [RecoveryExercise]? {
        guard let plan = viewModel.recoveryPlan else { return nil }
        
        // Flatten all exercises from all weeks
        let allExercises = plan.weeks.flatMap { week in
            week.exercises.map { exercise -> (RecoveryExercise, Int) in
                return (exercise, week.weekNumber)
            }
        }
        
        // Filter exercises scheduled for the selected date
        return allExercises
            .filter { exercise, _ in
                if let scheduledDate = exercise.scheduledDate {
                    return calendar.isDate(scheduledDate, inSameDayAs: selectedDate)
                }
                return false
            }
            .map { $0.0 }
    }
    
    private func getExerciseCount(for date: Date) -> Int? {
        guard let plan = viewModel.recoveryPlan else { return nil }
        
        // Flatten all exercises from all weeks
        let allExercises = plan.weeks.flatMap { $0.exercises }
        
        // Count exercises scheduled for the given date
        return allExercises.filter { exercise in
            if let scheduledDate = exercise.scheduledDate {
                return calendar.isDate(scheduledDate, inSameDayAs: date)
            }
            return false
        }.count
    }
    
    private func findWeekNumber(for exercise: RecoveryExercise) -> Int {
        guard let plan = viewModel.recoveryPlan else { return 1 }
        
        for week in plan.weeks {
            if week.exercises.contains(where: { $0.id == exercise.id }) {
                return week.weekNumber
            }
        }
        
        return 1 // Default to week 1 if not found
    }
}

struct RecoveryPlanCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryPlanCalendarView(viewModel: RecoveryPlanViewModel(authManager: AuthManager.shared))
    }
} 