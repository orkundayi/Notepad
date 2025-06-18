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
  bool _isFilterBarVisible = false;

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
                  onShowFilters: () {
                    // Filters are now always visible in the filter bar
                    // No action needed as filters are embedded in the UI
                  },
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
                  if (_isFilterBarVisible) _buildFilterBar(),
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
        _buildQuickActionButton(
          icon: Icons.add,
          label: 'Yeni Görev',
          onTap: () => _showAddTaskDialog(context),
        ),

        const SizedBox(width: 8),
        _buildQuickActionButton(
          icon:
              _isPersonFilterActive ? Icons.filter_list_off : Icons.filter_list,
          label:
              _isPersonFilterActive
                  ? 'Filtreleri Temizle'
                  : _isFilterBarVisible
                  ? 'Filtreleri Gizle'
                  : 'Filtreleri Göster',
          onTap: () {
            setState(() {
              if (_isPersonFilterActive) {
                // Clear filters but keep filter bar visible
                _isPersonFilterActive = false;
                _selectedPersonFilter = null;
              } else {
                // Toggle filter bar visibility
                _isFilterBarVisible = !_isFilterBarVisible;
              }
            });
          },
          isActive: _isPersonFilterActive || _isFilterBarVisible,
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
              case 'settings':
                context.go('/settings');
                break;
              case 'logout':
                _handleLogout();
                break;
            }
          },
          itemBuilder:
              (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Ayarlar'),
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

    if (_isPersonFilterActive) {
      if (_selectedPersonFilter == null) {
        // Atanmamış task'ları filtrele
        tasks =
            tasks
                .where(
                  (task) =>
                      task.assignedToId == null || task.assignedToId!.isEmpty,
                )
                .toList();
      } else {
        // Belirli bir kişiye atanmış task'ları filtrele
        tasks =
            tasks
                .where((task) => task.assignedToId == _selectedPersonFilter!.id)
                .toList();
      }
    }

    if (_isSearching) {
      // Arama sonuçlarını mevcut filtreler ile birleştir
      if (_isPersonFilterActive) {
        return _filteredTasks.where((task) {
          if (_selectedPersonFilter == null) {
            return task.assignedToId == null || task.assignedToId!.isEmpty;
          } else {
            return task.assignedToId == _selectedPersonFilter!.id;
          }
        }).toList();
      }
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

  void _handleLogout() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.signOut();
  }

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider.withOpacity(0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Consumer<PersonProvider>(
        builder: (context, personProvider, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Header
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildFilterChip(
                    label: 'Tümü',
                    isSelected: !_isPersonFilterActive,
                    onSelected: () {
                      setState(() {
                        // "Tümü" seçiliyken tekrar tıklanırsa hiçbir şey yapma
                        // Zaten varsayılan durum bu
                        _isPersonFilterActive = false;
                        _selectedPersonFilter = null;
                      });
                    },
                    icon: Icons.view_list_rounded,
                    color: AppColors.primary,
                    count:
                        Provider.of<TaskProvider>(
                          context,
                          listen: false,
                        ).tasks.length,
                  ),

                  // Unassigned Tasks Filter
                  _buildFilterChip(
                    label: 'Atanmamış',
                    isSelected:
                        _isPersonFilterActive && _selectedPersonFilter == null,
                    onSelected: () {
                      setState(() {
                        if (_isPersonFilterActive &&
                            _selectedPersonFilter == null) {
                          // Zaten atanmamış filtresi aktif, kaldır
                          _isPersonFilterActive = false;
                          _selectedPersonFilter = null;
                        } else {
                          // Atanmamış filtresini aktif et
                          _isPersonFilterActive = true;
                          _selectedPersonFilter = null;
                        }
                      });
                    },
                    icon: Icons.person_off_rounded,
                    color: Colors.orange,
                    count:
                        Provider.of<TaskProvider>(context, listen: false).tasks
                            .where(
                              (task) =>
                                  task.assignedToId == null ||
                                  task.assignedToId!.isEmpty,
                            )
                            .length,
                  ),

                  // Person Filters
                  ...personProvider.people.map((person) {
                    final isSelected =
                        _isPersonFilterActive &&
                        _selectedPersonFilter?.id == person.id;
                    final taskCount =
                        Provider.of<TaskProvider>(context, listen: false).tasks
                            .where((task) => task.assignedToId == person.id)
                            .length;

                    return _buildFilterChip(
                      label: person.name,
                      isSelected: isSelected,
                      onSelected: () {
                        setState(() {
                          if (isSelected) {
                            // Zaten seçili, kaldır (tümüne dön)
                            _isPersonFilterActive = false;
                            _selectedPersonFilter = null;
                          } else {
                            // Bu kişiyi seç
                            _isPersonFilterActive = true;
                            _selectedPersonFilter = person;
                          }
                        });
                      },
                      avatar:
                          person.name.isNotEmpty
                              ? person.name[0].toUpperCase()
                              : '?',
                      color: AppColors.primary,
                      count: taskCount,
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    IconData? icon,
    String? avatar,
    required Color color,
    required int count,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withOpacity(0.15) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar or Icon
            if (avatar != null)
              CircleAvatar(
                backgroundColor: isSelected ? color : AppColors.textSecondary,
                radius: 8,
                child: Text(
                  avatar,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (icon != null)
              Icon(
                icon,
                size: 14,
                color: isSelected ? color : AppColors.textSecondary,
              ),

            const SizedBox(width: 6),

            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ), // Count Badge
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? color.withOpacity(0.2)
                          : AppColors.textHint.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? color : AppColors.textHint,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
