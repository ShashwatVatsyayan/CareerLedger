import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Routine Sort Option
enum RoutineSortOption: String, CaseIterable, Identifiable {
    case byTime = "Sort by Time"
    case byCategory = "Sort by Category"
    case byStatus = "Sort by Completion"
    case byTitle = "Sort by Title"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .byTime: return "clock"
        case .byCategory: return "tag"
        case .byStatus: return "checkmark.circle"
        case .byTitle: return "textformat"
        }
    }
}

// MARK: - Main Routine View
struct RoutineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("selectedTheme") private var selectedTheme = "light"
    @Query(sort: \RoutineTask.orderIndex) private var tasks: [RoutineTask]

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedCategory: String = "All"
    @State private var sortOption: RoutineSortOption = .byTime

    // Sheet states
    @State private var showingAddTask = false
    @State private var editingTask: RoutineTask? = nil
    @State private var showingTermsSheet = false
    @State private var showingPrivacySheet = false

    // Toast state
    @State private var toastMessage: String? = nil
    @State private var toastIcon: String = "checkmark.circle.fill"
    @State private var toastTimer: Timer? = nil

    private let calendar = Calendar.current

    // Distinct categories found in tasks + default ones
    private var categories: [String] {
        var base = ["All", "Clean Room", "Academics", "Projects", "Certificates", "Wellness"]
        for t in tasks {
            if !base.contains(t.category) && !t.category.isEmpty {
                base.append(t.category)
            }
        }
        return base
    }

    // Filtered & sorted tasks
    private var filteredTasks: [RoutineTask] {
        let matching = tasks.filter { task in
            let isCategoryMatch = (selectedCategory == "All") || (task.category == selectedCategory)
            let isDateMatch = calendar.isDate(task.scheduledDate, inSameDayAs: selectedDate) || task.isAllDay
            return isCategoryMatch && isDateMatch
        }

        switch sortOption {
        case .byTime:
            return matching.sorted { t1, t2 in
                if t1.isAllDay != t2.isAllDay { return t1.isAllDay }
                return t1.orderIndex < t2.orderIndex
            }
        case .byCategory:
            return matching.sorted { $0.category < $1.category }
        case .byStatus:
            return matching.sorted { !$0.isCompleted && $1.isCompleted }
        case .byTitle:
            return matching.sorted { $0.title < $1.title }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // Background
                backgroundColor
                    .ignoresSafeArea()

                // Main Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // Top Header (H1 Title + Sort/Legal button)
                        topHeaderBar

                        // Horizontal Calendar Day Strip
                        horizontalCalendarStrip

                        // Category Filter Chips
                        categoryFilterChips

                        // Task List
                        taskListView

                        // Legal & Privacy Policy
                        privacyAndTermsFooter

                        // Extra bottom spacing so content scrolls comfortably above tab bar & FAB
                        Spacer(minLength: 90)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                }

                // Floating Action Button (+)
                floatingActionButton

                // Floating Toast Notification
                if let message = toastMessage {
                    toastView(message: message, icon: toastIcon)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 98)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddTask) {
                AddRoutineTaskSheet(scheduledDate: selectedDate) { newTask in
                    showToast("Task added successfully", icon: "checkmark.circle.fill")
                }
                .applyAppTheme()
            }
            .sheet(item: $editingTask) { task in
                EditRoutineTaskSheet(task: task) {
                    showToast("Task updated successfully", icon: "checkmark.circle.fill")
                }
                .applyAppTheme()
            }
            .sheet(isPresented: $showingTermsSheet) {
                NavigationStack {
                    TermsAndConditionsView()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showingTermsSheet = false
                                }
                            }
                        }
                }
                .applyAppTheme()
            }
            .sheet(isPresented: $showingPrivacySheet) {
                NavigationStack {
                    PrivacyPolicyView()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showingPrivacySheet = false
                                }
                            }
                        }
                }
                .applyAppTheme()
            }
            .onAppear {
                PersistenceController.seedIfNeeded(modelContext: modelContext)
            }
        }
    }

    // MARK: - Background Color
    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.08, green: 0.08, blue: 0.10)
            : Color(red: 0.97, green: 0.96, blue: 0.99)
    }

    // MARK: - Top Header Bar (H1 Heading)
    private var topHeaderBar: some View {
        HStack(alignment: .center) {
            // Explicit H1 Heading
            Text("Today")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(colorScheme == .dark ? Color.white : Color(red: 0.10, green: 0.10, blue: 0.14))

            Spacer()

            HStack(spacing: 8) {
                // Privacy Policy & Terms Quick Menu
                Menu {
                    Button {
                        showingPrivacySheet = true
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }

                    Button {
                        showingTermsSheet = true
                    } label: {
                        Label("Terms and Conditions", systemImage: "doc.text.fill")
                    }
                } label: {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(colorScheme == .dark ? Color(red: 0.8, green: 0.8, blue: 0.85) : Color(red: 0.25, green: 0.25, blue: 0.30))
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                        )
                }

                // Sort & Appearance Menu
                Menu {
                    Picker("Sort Tasks", selection: $sortOption) {
                        ForEach(RoutineSortOption.allCases) { option in
                            Label(option.rawValue, systemImage: option.icon).tag(option)
                        }
                    }

                    Divider()

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedDate = calendar.startOfDay(for: Date())
                        }
                    } label: {
                        Label("Jump to Today", systemImage: "calendar.badge.clock")
                    }

                    Divider()

                    Menu {
                        Button {
                            selectedTheme = "light"
                            ThemeManager.applyTheme("light")
                        } label: {
                            Label("Light Theme", systemImage: "sun.max.fill")
                        }

                        Button {
                            selectedTheme = "dark"
                            ThemeManager.applyTheme("dark")
                        } label: {
                            Label("Dark Theme", systemImage: "moon.fill")
                        }
                    } label: {
                        Label("Theme (\(selectedTheme.capitalized))", systemImage: selectedTheme == "light" ? "sun.max" : "moon")
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(colorScheme == .dark ? Color(red: 0.8, green: 0.8, blue: 0.85) : Color(red: 0.25, green: 0.25, blue: 0.30))
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                        )
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Horizontal Calendar Strip
    private var horizontalCalendarStrip: some View {
        let currentWeekDays = weekDays(around: selectedDate)

        return HStack(spacing: 8) {
            ForEach(currentWeekDays, id: \.self) { day in
                let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
                let dayLetter = weekdayLetter(for: day)
                let dayNumber = calendar.component(.day, from: day)

                Button {
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
                        selectedDate = day
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(dayLetter)
                            .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                            .foregroundStyle(
                                isSelected
                                    ? Color(red: 0.22, green: 0.15, blue: 0.45)
                                    : (colorScheme == .dark ? Color.gray : Color(red: 0.55, green: 0.55, blue: 0.62))
                            )

                        Text("\(dayNumber)")
                            .font(.system(size: 15, weight: isSelected ? .bold : .medium, design: .rounded))
                            .foregroundStyle(
                                isSelected
                                    ? Color(red: 0.18, green: 0.12, blue: 0.38)
                                    : (colorScheme == .dark ? Color.white.opacity(0.85) : Color(red: 0.45, green: 0.45, blue: 0.52))
                            )
                            .frame(width: 32, height: 32)
                            .background(
                                Group {
                                    if isSelected {
                                        Circle()
                                            .fill(Color.white)
                                            .shadow(color: Color.black.opacity(0.06), radius: 3, y: 1)
                                    }
                                }
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        Group {
                            if isSelected {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.90, green: 0.84, blue: 0.98),
                                                Color(red: 0.85, green: 0.78, blue: 0.96)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Color(red: 0.78, green: 0.70, blue: 0.94), lineWidth: 1)
                                    )
                            } else {
                                Capsule()
                                    .fill(Color.clear)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Category Filter Chips
    private var categoryFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { category in
                    let isSelected = selectedCategory == category

                    Button {
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedCategory = category
                        }
                    } label: {
                        Text(category)
                            .font(.system(size: 14, weight: isSelected ? .bold : .medium, design: .rounded))
                            .foregroundStyle(
                                isSelected
                                    ? Color(red: 0.25, green: 0.14, blue: 0.50)
                                    : (colorScheme == .dark ? Color.white.opacity(0.8) : Color(red: 0.35, green: 0.35, blue: 0.40))
                            )
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background(
                                Group {
                                    if isSelected {
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color(red: 0.89, green: 0.82, blue: 0.98),
                                                        Color(red: 0.84, green: 0.76, blue: 0.96)
                                                    ],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .shadow(color: Color.black.opacity(0.04), radius: 3, y: 1)
                                    } else {
                                        Capsule()
                                            .fill(colorScheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.18) : Color.white)
                                            .shadow(color: Color.black.opacity(0.03), radius: 3, y: 1)
                                            .overlay(
                                                Capsule()
                                                    .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05), lineWidth: 0.8)
                                            )
                                    }
                                }
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Task List View
    private var taskListView: some View {
        VStack(spacing: 12) {
            if filteredTasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.badge.plus")
                        .font(.system(size: 38))
                        .foregroundStyle(Color(red: 0.55, green: 0.45, blue: 0.85))

                    Text("No Tasks for Selected Filter")
                        .font(.headline)
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color(red: 0.2, green: 0.2, blue: 0.25))

                    Text("Use the + button to add routine items, academic goals, or project tasks.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Button {
                        showingAddTask = true
                    } label: {
                        Text("Add New Task")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(Color(red: 0.48, green: 0.22, blue: 0.94))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(.vertical, 36)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? Color(red: 0.12, green: 0.12, blue: 0.15) : Color.white)
                        .shadow(color: Color.black.opacity(0.03), radius: 4, y: 1)
                )
            } else {
                ForEach(filteredTasks) { task in
                    RoutineTaskCard(
                        task: task,
                        onToggleCompletion: {
                            toggleTaskCompletion(task)
                        },
                        onTapCard: {
                            editingTask = task
                        },
                        onDelete: {
                            deleteTask(task)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Privacy Policy & Terms and Conditions Footer
    private var privacyAndTermsFooter: some View {
        HStack(spacing: 16) {
            Button {
                showingPrivacySheet = true
            } label: {
                Text("Privacy Policy")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .underline()
            }

            Text("•")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button {
                showingTermsSheet = true
            } label: {
                Text("Terms and Conditions")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .underline()
            }
        }
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    // MARK: - Floating Action Button (+)
    private var floatingActionButton: some View {
        Button {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
            showingAddTask = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color(red: 0.48, green: 0.22, blue: 0.94))
                    .frame(width: 58, height: 58)
                    .shadow(color: Color.black.opacity(0.16), radius: 6, x: 0, y: 3)

                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .padding(.trailing, 20)
        .padding(.bottom, 94)
    }

    // MARK: - Floating Toast View
    private func toastView(message: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.white)

            Text(message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color(red: 0.20, green: 0.20, blue: 0.24).opacity(0.96))
                .shadow(color: Color.black.opacity(0.18), radius: 6, y: 3)
        )
        .padding(.bottom, 96)
    }

    // MARK: - Actions
    private func toggleTaskCompletion(_ task: RoutineTask) {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            task.isCompleted.toggle()
        }
        try? modelContext.save()

        if task.isCompleted {
            showToast("Task completed", icon: "checkmark.circle.fill")
        } else {
            showToast("Task marked pending", icon: "arrow.counterclockwise")
        }
    }

    private func deleteTask(_ task: RoutineTask) {
        withAnimation {
            modelContext.delete(task)
            try? modelContext.save()
        }
        showToast("Task deleted", icon: "trash.fill")
    }

    private func showToast(_ message: String, icon: String = "checkmark.circle.fill") {
        toastTimer?.invalidate()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            toastMessage = message
            toastIcon = icon
        }
        toastTimer = Timer.scheduledTimer(withTimeInterval: 2.2, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                toastMessage = nil
            }
        }
    }

    // MARK: - Date Helpers
    private func weekDays(around date: Date) -> [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfMonth, for: date) else {
            return [date]
        }
        var days: [Date] = []
        var current = weekInterval.start
        for _ in 0..<7 {
            days.append(current)
            if let next = calendar.date(byAdding: .day, value: 1, to: current) {
                current = next
            }
        }
        return days
    }

    private func weekdayLetter(for date: Date) -> String {
        let weekday = calendar.component(.weekday, from: date)
        switch weekday {
        case 1: return "Su"
        case 2: return "Mo"
        case 3: return "Tu"
        case 4: return "We"
        case 5: return "Th"
        case 6: return "Fr"
        case 7: return "Sa"
        default: return ""
        }
    }
}

// MARK: - Routine Task Card (Soft pastel rounded card matching screenshot)
struct RoutineTaskCard: View {
    let task: RoutineTask
    let onToggleCompletion: () -> Void
    let onTapCard: () -> Void
    let onDelete: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            // Left 3D-styled / vibrant icon squircle
            taskIconView
                .frame(width: 48, height: 48)

            // Middle: Time caption & Task title
            VStack(alignment: .leading, spacing: 3) {
                Text(task.timeString)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? Color.gray : Color(red: 0.35, green: 0.38, blue: 0.45))

                Text(task.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        task.isCompleted
                            ? Color.secondary
                            : (colorScheme == .dark ? Color.white : Color(red: 0.10, green: 0.10, blue: 0.15))
                    )
                    .strikethrough(task.isCompleted, color: Color.secondary.opacity(0.6))
                    .lineLimit(1)
            }

            Spacer()

            // Right Checkbox Circle
            Button {
                onToggleCompletion()
            } label: {
                ZStack {
                    Circle()
                        .stroke(
                            task.isCompleted
                                ? Color(red: 0.48, green: 0.25, blue: 0.94)
                                : Color(red: 0.70, green: 0.74, blue: 0.82),
                            lineWidth: 1.6
                        )
                        .frame(width: 28, height: 28)

                    if task.isCompleted {
                        Circle()
                            .fill(Color(red: 0.48, green: 0.25, blue: 0.94))
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(cardBorderColor, lineWidth: 1)
                )
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.18) : Color.black.opacity(0.04),
                    radius: 5,
                    x: 0,
                    y: 2
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTapCard()
        }
        .contextMenu {
            Button {
                onToggleCompletion()
            } label: {
                Label(task.isCompleted ? "Mark Incomplete" : "Mark Complete", systemImage: task.isCompleted ? "circle" : "checkmark.circle")
            }

            Button {
                onTapCard()
            } label: {
                Label("Edit Task", systemImage: "pencil")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Task", systemImage: "trash")
            }
        }
    }

    // MARK: - Card Background
    private var cardBackground: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(Color(red: 0.13, green: 0.13, blue: 0.16))
        } else {
            if task.category == "Wellness" || task.title.lowercased().contains("water") {
                return AnyShapeStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.90, blue: 0.99),
                            Color(red: 0.91, green: 0.86, blue: 0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            } else {
                return AnyShapeStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.91, green: 0.95, blue: 1.0),
                            Color(red: 0.88, green: 0.93, blue: 0.99)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
        }
    }

    private var cardBorderColor: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.06)
        } else if task.category == "Wellness" || task.title.lowercased().contains("water") {
            return Color(red: 0.86, green: 0.80, blue: 0.95)
        } else {
            return Color(red: 0.82, green: 0.88, blue: 0.97)
        }
    }

    // MARK: - Task Icon View
    @ViewBuilder
    private var taskIconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: task.iconBgHex).opacity(0.85),
                            Color(hex: task.iconBgHex)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if task.title.lowercased().contains("wash") {
                Image(systemName: "basket.fill")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(Color(hex: task.iconTintHex))
            } else if task.title.lowercased().contains("kitchen") {
                Image(systemName: "fork.knife")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(Color(hex: task.iconTintHex))
            } else if task.title.lowercased().contains("water") {
                Image(systemName: "drop.fill")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(Color(hex: task.iconTintHex))
            } else {
                Image(systemName: task.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(hex: task.iconTintHex))
            }
        }
    }
}

// MARK: - Add Routine Task Sheet
struct AddRoutineTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let scheduledDate: Date
    let onSave: (RoutineTask) -> Void

    @State private var title = ""
    @State private var category = "Clean Room"
    @State private var isAllDay = true
    @State private var selectedTime = Date()
    @State private var selectedIcon = "basket.fill"
    @State private var selectedBgHex = "#E0F2FE"
    @State private var selectedTintHex = "#0284C7"
    @State private var notes = ""

    private let availableCategories = ["Clean Room", "Routine", "Academics", "Projects", "Certificates", "Wellness"]

    private let iconPresets: [(name: String, icon: String, bg: String, tint: String)] = [
        ("Laundry", "basket.fill", "#E0F2FE", "#0284C7"),
        ("Kitchen", "fork.knife", "#FCE7F3", "#DB2777"),
        ("Hydration", "drop.fill", "#E0F2FE", "#2563EB"),
        ("Academics", "book.fill", "#FEF3C7", "#D97706"),
        ("Coding", "laptopcomputer", "#EDE9FE", "#7C3AED"),
        ("Certificates", "checkmark.seal.fill", "#DCFCE7", "#16A34A"),
        ("Fitness", "figure.run", "#FFEDD5", "#EA580C"),
        ("Goals", "target", "#FEE2E2", "#DC2626")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Title") {
                    TextField("e.g. wash cloths, Review Algorithms", text: $title)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(availableCategories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Time") {
                    Toggle("All-Day", isOn: $isAllDay)

                    if !isAllDay {
                        DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    }
                }

                Section("Style & Icon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(iconPresets, id: \.icon) { preset in
                                let isSelected = selectedIcon == preset.icon

                                Button {
                                    selectedIcon = preset.icon
                                    selectedBgHex = preset.bg
                                    selectedTintHex = preset.tint
                                } label: {
                                    VStack(spacing: 4) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(hex: preset.bg))
                                                .frame(width: 44, height: 44)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
                                                )

                                            Image(systemName: preset.icon)
                                                .font(.system(size: 18))
                                                .foregroundStyle(Color(hex: preset.tint))
                                        }

                                        Text(preset.name)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Notes (Optional)") {
                    TextField("Additional details or steps", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("New Routine Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveTask() {
        let timeString: String
        if isAllDay {
            timeString = "Time: All-Day"
        } else {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            timeString = "Time: \(formatter.string(from: selectedTime))"
        }

        let newTask = RoutineTask(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            timeString: timeString,
            isAllDay: isAllDay,
            scheduledDate: scheduledDate,
            iconName: selectedIcon,
            iconBgHex: selectedBgHex,
            iconTintHex: selectedTintHex,
            notes: notes
        )

        modelContext.insert(newTask)
        try? modelContext.save()
        onSave(newTask)
        dismiss()
    }
}

// MARK: - Edit Routine Task Sheet
struct EditRoutineTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let task: RoutineTask
    let onSave: () -> Void

    @State private var title: String = ""
    @State private var category: String = ""
    @State private var isAllDay: Bool = true
    @State private var selectedTime: Date = Date()
    @State private var selectedIcon: String = "basket.fill"
    @State private var selectedBgHex: String = "#E0F2FE"
    @State private var selectedTintHex: String = "#0284C7"
    @State private var notes: String = ""

    private let availableCategories = ["Clean Room", "Routine", "Academics", "Projects", "Certificates", "Wellness"]

    private let iconPresets: [(name: String, icon: String, bg: String, tint: String)] = [
        ("Laundry", "basket.fill", "#E0F2FE", "#0284C7"),
        ("Kitchen", "fork.knife", "#FCE7F3", "#DB2777"),
        ("Hydration", "drop.fill", "#E0F2FE", "#2563EB"),
        ("Academics", "book.fill", "#FEF3C7", "#D97706"),
        ("Coding", "laptopcomputer", "#EDE9FE", "#7C3AED"),
        ("Certificates", "checkmark.seal.fill", "#DCFCE7", "#16A34A"),
        ("Fitness", "figure.run", "#FFEDD5", "#EA580C"),
        ("Goals", "target", "#FEE2E2", "#DC2626")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Title") {
                    TextField("Title", text: $title)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(availableCategories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Time") {
                    Toggle("All-Day", isOn: $isAllDay)

                    if !isAllDay {
                        DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    }
                }

                Section("Style & Icon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(iconPresets, id: \.icon) { preset in
                                let isSelected = selectedIcon == preset.icon

                                Button {
                                    selectedIcon = preset.icon
                                    selectedBgHex = preset.bg
                                    selectedTintHex = preset.tint
                                } label: {
                                    VStack(spacing: 4) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(hex: preset.bg))
                                                .frame(width: 44, height: 44)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
                                                )

                                            Image(systemName: preset.icon)
                                                .font(.system(size: 18))
                                                .foregroundStyle(Color(hex: preset.tint))
                                        }

                                        Text(preset.name)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Button(role: .destructive) {
                        modelContext.delete(task)
                        try? modelContext.save()
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Task")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveChanges()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                title = task.title
                category = task.category
                isAllDay = task.isAllDay
                selectedIcon = task.iconName
                selectedBgHex = task.iconBgHex
                selectedTintHex = task.iconTintHex
                notes = task.notes
            }
        }
    }

    private func saveChanges() {
        task.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        task.category = category
        task.isAllDay = isAllDay
        task.iconName = selectedIcon
        task.iconBgHex = selectedBgHex
        task.iconTintHex = selectedTintHex
        task.notes = notes

        if isAllDay {
            task.timeString = "Time: All-Day"
        } else {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            task.timeString = "Time: \(formatter.string(from: selectedTime))"
        }

        try? modelContext.save()
        onSave()
        dismiss()
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 124, 58, 237)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
