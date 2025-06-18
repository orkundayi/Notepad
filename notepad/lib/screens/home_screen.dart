import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/person_provider.dart';
import '../models/task.dart';
import '../models/person.dart';
import '../utils/theme.dart';
import '../utils/platform_utils.dart';
import '../widgets/responsive_web_kanban.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<Task> _filteredTasks = [];
  bool _isSearching = false;
  Person? _selectedPersonFilter;
  bool _isPersonFilterActive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
    });
  }

  void _initializeProvider() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    await taskProvider.initialize(authProvider.user);
    await personProvider.initialize(authProvider.user);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildWebLayout();
  }

  Widget _buildWebLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Responsive Side Panel
          if (PlatformUtils.shouldShowSidebar(context))
            Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                final tasks = _getFilteredTasks(taskProvider);

                return ResponsiveWebSidePanel(
                  tasks: tasks,
                  onAddTask: () => _showAddTaskDialog(context),
                  onManagePeople: () => context.go('/people'),
                  onShowFilters: () => _showPersonFilterDialog(),
                );
              },
            ),

          // Main Content
          Expanded(
            child: Container(
              color: AppColors.background,
              child: Column(
                children: [
                  _buildResponsiveWebHeader(),
                  Expanded(
                    child: Consumer<TaskProvider>(
                      builder: (context, taskProvider, child) {
                        if (taskProvider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final tasks = _getFilteredTasks(taskProvider);

                        return ResponsiveWebKanbanLayout(
                          filteredTasks: tasks,
                          isFiltered: _isPersonFilterActive || _isSearching,
                          onRefresh: () => taskProvider.loadTasks(),
                          onEditTask:
                              (task) => _showEditTaskDialog(context, task),
                          onDeleteTask:
                              (task) => _showDeleteConfirmation(
                                context,
                                task,
                                taskProvider,
                              ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveWebHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Logo and Title Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Task Manager',
                      style: AppTheme.getResponsiveTextStyle(
                        context,
                        baseFontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Profesyonel Web Dashboard',
                      style: AppTheme.getResponsiveTextStyle(
                        context,
                        baseFontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Search and Actions
              const SizedBox(width: 24),
              _buildSearchBar(),
              const SizedBox(width: 16),
              _buildHeaderActions(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 300,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Görev ara...',
          hintStyle: const TextStyle(color: AppColors.textHint),
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: AppColors.textSecondary,
          ),
          suffixIcon:
              _isSearching
                  ? IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                        _filteredTasks.clear();
                      });
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _isSearching = value.isNotEmpty;
          });
          _filterTasks(value);
        },
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      children: [
        // Quick Add Task Button
        _buildQuickActionButton(
          icon: Icons.add,
          label: 'Yeni Görev',
          onTap: () => _showAddTaskDialog(context),
        ),

        const SizedBox(width: 8),

        // Filter Button
        _buildQuickActionButton(
          icon: Icons.filter_list,
          label: 'Filtreler',
          onTap: () => _showPersonFilterDialog(),
          isActive: _isPersonFilterActive,
        ),

        const SizedBox(width: 8),

        // Profile Menu
        PopupMenuButton<String>(
          icon: const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, size: 16, color: Colors.white),
          ),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                // Handle profile
                break;
              case 'settings':
                // Handle settings
                break;
              case 'logout':
                _handleLogout();
                break;
            }
          },
          itemBuilder:
              (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Profil'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Ayarlar'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout, color: AppColors.error),
                    title: Text(
                      'Çıkış Yap',
                      style: TextStyle(color: AppColors.error),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isActive
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  List<Task> _getFilteredTasks(TaskProvider taskProvider) {
    List<Task> tasks = taskProvider.tasks;

    if (_isPersonFilterActive && _selectedPersonFilter != null) {
      tasks =
          tasks
              .where((task) => task.assignedToId == _selectedPersonFilter!.id)
              .toList();
    }

    if (_isSearching) {
      return _filteredTasks;
    }

    return tasks;
  }

  void _filterTasks(String query) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final allTasks = taskProvider.tasks;

    if (query.isEmpty) {
      _filteredTasks.clear();
      return;
    }

    _filteredTasks =
        allTasks.where((task) {
          return task.title.toLowerCase().contains(query.toLowerCase()) ||
              task.description.toLowerCase().contains(query.toLowerCase()) ||
              task.taskNumber.toLowerCase().contains(query.toLowerCase());
        }).toList();
  }

  void _showAddTaskDialog(BuildContext context) {
    context.go('/task/create');
  }

  void _showEditTaskDialog(BuildContext context, Task task) {
    context.go('/task/edit/${task.id}', extra: task);
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Task task,
    TaskProvider taskProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Görevi Sil'),
            content: Text(
              '${task.title} görevini silmek istediğinizden emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await taskProvider.deleteTask(task.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Görev silindi')),
                    );
                  }
                },
                child: const Text('Sil'),
              ),
            ],
          ),
    );
  }

  void _showPersonFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Consumer<PersonProvider>(
            builder: (context, personProvider, child) {
              return AlertDialog(
                title: const Text('Kişiye Göre Filtrele'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('Tümü'),
                      onTap: () {
                        setState(() {
                          _isPersonFilterActive = false;
                          _selectedPersonFilter = null;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ...personProvider.people.map(
                      (person) => ListTile(
                        title: Text(person.name),
                        onTap: () {
                          setState(() {
                            _isPersonFilterActive = true;
                            _selectedPersonFilter = person;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  void _handleLogout() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.signOut();
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list_rounded, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Filters',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (_isPersonFilterActive)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isPersonFilterActive = false;
                      _selectedPersonFilter = null;
                    });
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPersonFilter(),
        ],
      ),
    );
  }

  Widget _buildPersonFilter() {
    return Consumer<PersonProvider>(
      builder: (context, personProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assign to:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: !_isPersonFilterActive,
                  onSelected: (selected) {
                    setState(() {
                      _isPersonFilterActive = false;
                      _selectedPersonFilter = null;
                    });
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).primaryColor,
                ),
                FilterChip(
                  label: const Text('Unassigned'),
                  selected:
                      _isPersonFilterActive && _selectedPersonFilter == null,
                  onSelected: (selected) {
                    setState(() {
                      _isPersonFilterActive = true;
                      _selectedPersonFilter = null;
                    });
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: Colors.orange.withOpacity(0.2),
                  checkmarkColor: Colors.orange,
                ),
                ...personProvider.people.map((person) {
                  final isSelected =
                      _isPersonFilterActive &&
                      _selectedPersonFilter?.id == person.id;
                  return FilterChip(
                    avatar: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      radius: 12,
                      child: Text(
                        person.name.isNotEmpty
                            ? person.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    label: Text(person.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _isPersonFilterActive = selected;
                        _selectedPersonFilter = selected ? person : null;
                      });
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                  );
                }),
              ],
            ),
          ],
        );
      },
    );
  }
}
