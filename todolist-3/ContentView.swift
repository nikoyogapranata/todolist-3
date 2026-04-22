import SwiftUI

// -----------------------------------------------------------------------------
// ContentView — Root / Parent View
// Hosts a custom floating pill tab bar instead of the system UITabBar.
// The system tab bar is hidden via UITabBar.appearance() in init.
// -----------------------------------------------------------------------------
struct ContentView: View {

    @EnvironmentObject private var authVM: AuthViewModel

    let uid: String
    @StateObject private var viewModel: ToDoViewModel
    @State private var selectedTab: Int = 0

    init(uid: String) {
        self.uid = uid
        _viewModel = StateObject(wrappedValue: ToDoViewModel(uid: uid))
        // Hide the native system tab bar so our custom pill renders cleanly.
        UITabBar.appearance().isHidden = true
    }

    private var theme: Theme { viewModel.currentTheme }

    var body: some View {
        ZStack(alignment: .bottom) {
            // ── Tab Content ───────────────────────────────────────────────
            TabView(selection: $selectedTab) {
                TasksTab(viewModel: viewModel)
                    .tag(0)
                ProfileView(viewModel: viewModel)
                    .tag(1)
                SettingsView(viewModel: viewModel)
                    .tag(2)
            }

            // ── Floating Pill Tab Bar ─────────────────────────────────────
            FloatingTabBar(
                selectedTab: $selectedTab,
                theme: theme
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// =============================================================================
// MARK: - TasksTab
// =============================================================================
struct TasksTab: View {
    @ObservedObject var viewModel: ToDoViewModel

    @State private var isAddingTask: Bool = false
    private var theme: Theme { viewModel.currentTheme }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {

                // ── Background ───────────────────────
                LinearGradient(
                    colors: theme.backgroundColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // ── Main Column ───────────────────────────────────────────
                VStack(spacing: 0) {
                    FilterBarView(filterState: $viewModel.filterState, theme: theme)

                    if viewModel.filteredTasks.isEmpty {
                        EmptyStateView(theme: theme, filterState: viewModel.filterState)
                    } else {
                        taskList
                    }
                }

                // ── Floating Action Button ────────────────────────────────
                // Bottom padding = pill height (~68) + pill bottom padding (28) + gap (12)
                FloatingAddButton(accentColor: theme.accentColor) {
                    isAddingTask = true
                }
                .padding(.trailing, 22)
                .padding(.bottom, 108)
            }
            .navigationTitle("My Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("\(viewModel.filteredTasks.count) tasks")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(theme.secondaryLabelColor)
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search tasks…")
            .preferredColorScheme(theme.preferredColorScheme)
            .sheet(isPresented: $isAddingTask) {
                AddTaskView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Task List
    private var taskList: some View {
        List {
            /* IMPORTANT: We loop through filteredTasks directly.
               Since Firebase handles the source of truth, we pass a constant task
               snapshot to the row and let the ViewModel handle mutations.
            */
            ForEach(viewModel.filteredTasks) { task in
                ZStack {
                    // Hidden NavigationLink to remove the chevron icon
                    NavigationLink(destination: TaskDetailView(viewModel: viewModel, task: task)) {
                        EmptyView()
                    }
                    .opacity(0)

                    TaskRowView(
                        task: .constant(task), // Pass as constant since ViewModel handles updates
                        theme: theme,
                        onToggle: { taskToToggle in
                            viewModel.toggleCompletion(for: taskToToggle)
                        },
                        onDelete: { taskToDelete in
                            viewModel.deleteTask(withID: taskToDelete.id)
                        }
                    )
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }

            Color.clear.frame(height: 110)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}
