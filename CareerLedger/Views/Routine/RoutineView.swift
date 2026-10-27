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
    @State private var showingProClaimSheet = false
    @State private var showingTermsSheet = false
    @State private var showingPrivacySheet = false

    // Toast state
    @State private var toastMessage: String? = nil
    @State private var toastIcon: String = "sparkles"
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
                if t1.isAllDay != t2.isAllDay { return t1.isAllDay } // All-day tasks like in screenshot first
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
                        // Top Header (Title + Sort button)
                        topHeaderBar

                        // Horizontal Calendar Day Strip
                        horizontalCalendarStrip

                        // Promo Hero Banner ("Meet a better self with Me+!" / CareerLedger Pro)
                        promoHeroBanner

                        // Category Filter Chips
                        categoryFilterChips

                        // Task List
                        taskListView

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
                        .padding(.bottom, 24)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddTask) {
                AddRoutineTaskSheet(scheduledDate: selectedDate) { newTask in
                    showToast("✨ Task Added Success!", icon: "sparkles")
                }
                .applyAppTheme()
            }
            .sheet(item: $editingTask) { task in
                EditRoutineTaskSheet(task: task) {
                    showToast("✨ Task Edited Success!", icon: "sparkles")
                }
                .applyAppTheme()
            }
            .sheet(isPresented: $showingProClaimSheet) {
                CareerProClaimSheet()
                    .applyAppTheme()
            }
            .sheet(isPresented: $showingTermsSheet) {
                TermsAndConditionsView()
                    .applyAppTheme()
            }
            .sheet(isPresented: $showingPrivacySheet) {
                PrivacyPolicyView()
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

    // MARK: - Top Header Bar
    private var topHeaderBar: some View {
        HStack {
            Spacer()

            Text("Today")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? Color.white : Color(red: 0.12, green: 0.12, blue: 0.16))

            Spacer()

            Menu {
                Picker("Sort Tasks", selection: $sortOption) {
                    ForEach(RoutineSortOption.allCases) { option in
                        Label(option.rawValue, systemImage: option.icon).tag(option)
                    }
                }

                Divider()

                Menu {
                    Button {
                        selectedTheme = "light"
                        ThemeManager.applyTheme("light")
                    } label: {
                        Label("Light Theme (Screenshot)", systemImage: "sun.max.fill")
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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(colorScheme == .dark ? Color(red: 0.8, green: 0.8, blue: 0.85) : Color(red: 0.2, green: 0.2, blue: 0.25))
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                    )
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
                                            .shadow(color: Color.purple.opacity(0.18), radius: 4, y: 2)
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

    // MARK: - Promo Hero Banner Card
    private var promoHeroBanner: some View {
        ZStack(alignment: .topTrailing) {
            // Background Gradient Card
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.50, green: 0.25, blue: 0.96),
                            Color(red: 0.42, green: 0.16, blue: 0.90),
                            Color(red: 0.35, green: 0.12, blue: 0.84)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(red: 0.45, green: 0.18, blue: 0.92).opacity(0.35), radius: 14, x: 0, y: 7)

            VStack(alignment: .leading, spacing: 14) {
                // Headline & Sub-offer
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Meet a better\nself with Me+!")
                            .font(.system(size: 23, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .lineSpacing(2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Only $1.67/month")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(red: 1.0, green: 0.90, blue: 0.35))

                            Text("Total $19.99/year ($39.99)")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.9))
                        }
                        .padding(.top, 4)
                    }

                    Spacer()

                    // "50% OFF" Tag
                    VStack(spacing: -2) {
                        HStack(spacing: 3) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 14))
                                .rotationEffect(.degrees(-25))
                                .foregroundStyle(Color(red: 1.0, green: 0.92, blue: 0.25))

                            Text("50%")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color(red: 1.0, green: 0.92, blue: 0.25))
                        }

                        Text("OFF")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(red: 1.0, green: 0.92, blue: 0.25))
                            .offset(y: -4)
                    }
                    .padding(.top, 4)
                    .padding(.trailing, 8)
                }

                // White "Claim Now! ->" Button
                Button {
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    #endif
                    showingProClaimSheet = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Claim Now!")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.12, green: 0.10, blue: 0.20))

                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color(red: 0.12, green: 0.10, blue: 0.20))
                        Spacer()
                    }
                    .frame(height: 48)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.12), radius: 6, y: 3)
                }
                .buttonStyle(.plain)

                // Subtext link: "Terms of Service and Privacy Policy"
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Button("Terms of Service") {
                            showingTermsSheet = true
                        }
                        .underline()

                        Text("and")

                        Button("Privacy Policy") {
                            showingPrivacySheet = true
                        }
                        .underline()
                    }
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.85))
                    Spacer()
                }
                .padding(.top, -4)
            }
            .padding(18)
        }
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
                                            .shadow(color: Color.purple.opacity(0.15), radius: 4, y: 2)
                                    } else {
                                        Capsule()
                                            .fill(colorScheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.18) : Color.white)
                                            .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
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
                        .font(.system(size: 40))
                        .foregroundStyle(Color(red: 0.65, green: 0.55, blue: 0.95))
                    Text("No tasks for \(selectedCategory == "All" ? "Today" : selectedCategory)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color(red: 0.2, green: 0.2, blue: 0.25))

                    Text("Tap the + button to add a new habit or milestone.")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)

                    Button {
                        showingAddTask = true
                    } label: {
                        Text("Add New Task")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(Color(red: 0.48, green: 0.25, blue: 0.94))
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
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.48, green: 0.22, blue: 0.94),
                                Color(red: 0.40, green: 0.15, blue: 0.88)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                    .shadow(color: Color(red: 0.45, green: 0.18, blue: 0.92).opacity(0.40), radius: 10, x: 0, y: 5)

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
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.white)

            Text(message)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .background(
            Capsule()
                .fill(Color(red: 0.23, green: 0.23, blue: 0.27).opacity(0.96))
                .shadow(color: Color.black.opacity(0.25), radius: 10, y: 5)
        )
        .padding(.bottom, 98)
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

        showToast("Task Edited Success!", icon: "sparkles")
    }

    private func deleteTask(_ task: RoutineTask) {
        withAnimation {
            modelContext.delete(task)
            try? modelContext.save()
        }
        showToast("Task deleted", icon: "trash.fill")
    }

    private func showToast(_ message: String, icon: String = "sparkles") {
        toastTimer?.invalidate()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            toastMessage = message
            toastIcon = icon
        }
        toastTimer = Timer.scheduledTimer(withTimeInterval: 2.4, repeats: false) { _ in
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
                            lineWidth: 2
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
                    color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.blue.opacity(0.03),
                    radius: 8,
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
                .shadow(color: Color(hex: task.iconTintHex).opacity(0.20), radius: 4, y: 2)

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

// MARK: - Career Pro Claim Sheet
struct CareerProClaimSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var hasClaimed = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.50, green: 0.25, blue: 0.96),
                                    Color(red: 0.40, green: 0.15, blue: 0.88)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.purple.opacity(0.3), radius: 10, y: 5)

                    Image(systemName: "sparkles")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(Color(red: 1.0, green: 0.92, blue: 0.25))
                }
                .padding(.top, 20)

                VStack(spacing: 8) {
                    Text("Meet a Better Self")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))

                    Text("Unlock CareerLedger Pro with 50% Off")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                // Features list
                VStack(alignment: .leading, spacing: 14) {
                    proFeatureRow(icon: "checkmark.seal.fill", title: "Unlimited Verified Credentials", subtitle: "Instant SHA-256 evidence proofing for all certificates")
                    proFeatureRow(icon: "sparkle.magnifyingglass", title: "Smart Resume AI Extractor", subtitle: "Parse full PDF resumes directly into portfolio models")
                    proFeatureRow(icon: "globe.americas.fill", title: "Public Portfolio Hosting", subtitle: "Share your ledger profile with recruiters worldwide")
                    proFeatureRow(icon: "bell.badge.fill", title: "Routine & Milestone Habit Alerts", subtitle: "Never miss daily coding goals or study schedules")
                }
                .padding(.horizontal, 20)

                // Pricing Card
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Annual VIP Access")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Text("Only $1.67/month (Billed at $19.99/year)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("50% OFF")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 0.38, green: 0.18, blue: 0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(red: 0.90, green: 0.84, blue: 0.98))
                        .clipShape(Capsule())
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.primary.opacity(0.04))
                )
                .padding(.horizontal, 20)

                Spacer()

                Button {
                    #if os(iOS)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    #endif
                    hasClaimed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        dismiss()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text(hasClaimed ? "✓ 50% Discount Claimed!" : "Claim 50% Discount Now")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .frame(height: 52)
                    .background(
                        hasClaimed
                            ? Color.green
                            : Color(red: 0.48, green: 0.22, blue: 0.94)
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color.purple.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func proFeatureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(red: 0.48, green: 0.22, blue: 0.94))
                .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
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
