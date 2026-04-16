import SwiftUI

// -----------------------------------------------------------------------------
// ContentView — Root / Parent View
// -----------------------------------------------------------------------------
struct ContentView: View {

    @StateObject private var viewModel = ToDoViewModel()
    @State private var selectedTab: Int = 0

    private var theme: Theme { viewModel.currentTheme }

    var body: some View {
        TabView(selection: $selectedTab) {

            // ── Tab 1: Tasks ───────────────────────────────────────────────
            TasksTab(viewModel: viewModel)
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
                .tag(0)

            // ── Tab 2: Profile ─────────────────────────────────────────────
            ProfileView(viewModel: viewModel)
                .tabItem {
                    Label("Profile", systemImage: selectedTab == 1 ? "person.fill" : "person")
                }
                .tag(1)

            // ── Tab 3: Settings ────────────────────────────────────────────
            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: selectedTab == 2 ? "gearshape.fill" : "gearshape")
                }
                .tag(2)
        }
        .accentColor(theme.accentColor)
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
                FloatingAddButton(accentColor: theme.accentColor) {
                    isAddingTask = true
                }
                .padding(.trailing, 22)
                .padding(.bottom, 30)
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

            Color.clear.frame(height: 90)
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}
