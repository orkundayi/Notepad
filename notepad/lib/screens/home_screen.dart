import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/person_provider.dart';
import '../providers/responsive_provider.dart';
import '../models/task.dart';
import '../models/person.dart';
import '../utils/theme.dart';
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
  bool _isMobileSearchActive = false;
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
    return Consumer<ResponsiveProvider>(
      builder: (context, responsive, child) {
        if (responsive.isMobile) {
          return _buildMobileLayout();
        } else {
          return _buildWebLayout();
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    final responsive = Provider.of<ResponsiveProvider>(context, listen: false);
    return WillPopScope(
      onWillPop: () async {
        if (_isMobileSearchActive) {
          setState(() {
            _isMobileSearchActive = false;
            _isSearching = false;
            _searchController.clear();
            _filteredTasks.clear();
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: _buildMobileAppBar(responsive),
        body: Container(
          color: AppColors.background,
          child: Column(
            children: [
              if (_isFilterBarVisible && !_isMobileSearchActive)
                _buildMobileFilterBar(),
              if (_isMobileSearchActive && _isSearching)
                _buildMobileSearchResults(),
              Expanded(
                child: Consumer<TaskProvider>(
                  builder: (context, taskProvider, child) {
                    if (taskProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final tasks = _getFilteredTasks(taskProvider);

                    return ResponsiveWebKanbanLayout(
                      filteredTasks: tasks,
                      isFiltered: _isPersonFilterActive || _isSearching,
                      onRefresh: () => taskProvider.loadTasks(),
                      onEditTask: (task) => _showEditTaskDialog(context, task),
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
        floatingActionButton:
            _isMobileSearchActive
                ? null
                : FloatingActionButton(
                  onPressed: () => _showAddTaskDialog(context),
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
        drawer: _isMobileSearchActive ? null : _buildMobileDrawer(),
      ),
    );
  }

  Widget _buildWebLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Responsive Side Panel
          Consumer<ResponsiveProvider>(
            builder: (context, responsive, child) {
              if (responsive.shouldShowSidebar) {
                return Consumer<TaskProvider>(
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
                );
              }
              return const SizedBox.shrink();
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

  PreferredSizeWidget _buildMobileAppBar(ResponsiveProvider responsive) {
    if (_isMobileSearchActive) {
      return _buildMobileSearchAppBar(responsive);
    }
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      title: Row(
        children: [
          Icon(
            Icons.developer_board,
            color: AppColors.primary,
            size: responsive.getResponsiveFontSize(24),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Manager',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: responsive.getResponsiveFontSize(18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Mobil Dashboard',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: responsive.getResponsiveFontSize(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isFilterBarVisible ? Icons.filter_list_off : Icons.filter_list,
            color:
                _isPersonFilterActive || _isFilterBarVisible
                    ? AppColors.primary
                    : AppColors.textSecondary,
          ),
          onPressed: () {
            setState(() {
              if (_isPersonFilterActive) {
                _isPersonFilterActive = false;
                _selectedPersonFilter = null;
              } else {
                _isFilterBarVisible = !_isFilterBarVisible;
              }
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.search, color: AppColors.textSecondary),
          onPressed: () {
            setState(() {
              _isMobileSearchActive = true;
            });
          },
        ),
        PopupMenuButton<String>(
          icon: const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, size: 16, color: Colors.white),
          ),
          onSelected: (value) {
            switch (value) {
              case 'people':
                context.go('/people');
                break;
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
                  value: 'people',
                  child: ListTile(
                    leading: Icon(Icons.people),
                    title: Text('Kişiler'),
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
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Çıkış'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
        ),
      ],
    );
  }

  PreferredSizeWidget _buildMobileSearchAppBar(ResponsiveProvider responsive) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
        onPressed: () {
          setState(() {
            _isMobileSearchActive = false;
            _isSearching = false;
            _searchController.clear();
            _filteredTasks.clear();
          });
        },
      ),
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(responsive.borderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Görev ara...',
            hintStyle: TextStyle(
              color: AppColors.textHint,
              fontSize: responsive.getResponsiveFontSize(14),
            ),
            prefixIcon: Icon(
              Icons.search,
              size: responsive.getResponsiveFontSize(20),
              color: AppColors.textSecondary,
            ),
            suffixIcon:
                _isSearching
                    ? IconButton(
                      icon: Icon(
                        Icons.close,
                        size: responsive.getResponsiveFontSize(20),
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
            contentPadding: EdgeInsets.symmetric(
              horizontal: responsive.responsiveValue(
                mobile: 12.0,
                desktop: 16.0,
              ),
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
      ),
      actions: [
        if (_isSearching)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_filteredTasks.length}',
              style: TextStyle(
                fontSize: responsive.getResponsiveFontSize(12),
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileFilterBar() {
    return Consumer2<ResponsiveProvider, PersonProvider>(
      builder: (context, responsive, personProvider, child) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            responsive.responsiveValue(mobile: 16.0, desktop: 24.0),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: AppColors.divider.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtreler',
                style: TextStyle(
                  fontSize: responsive.getResponsiveFontSize(16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMobileFilterChip(
                    label: 'Tümü',
                    isSelected: !_isPersonFilterActive,
                    onSelected: () {
                      setState(() {
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
                  _buildMobileFilterChip(
                    label: 'Atanmamış',
                    isSelected:
                        _isPersonFilterActive && _selectedPersonFilter == null,
                    onSelected: () {
                      setState(() {
                        if (_isPersonFilterActive &&
                            _selectedPersonFilter == null) {
                          _isPersonFilterActive = false;
                          _selectedPersonFilter = null;
                        } else {
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
                  ...personProvider.people.map((person) {
                    final isSelected =
                        _isPersonFilterActive &&
                        _selectedPersonFilter?.id == person.id;
                    final taskCount =
                        Provider.of<TaskProvider>(context, listen: false).tasks
                            .where((task) => task.assignedToId == person.id)
                            .length;

                    return _buildMobileFilterChip(
                      label: person.name,
                      isSelected: isSelected,
                      onSelected: () {
                        setState(() {
                          if (isSelected) {
                            _isPersonFilterActive = false;
                            _selectedPersonFilter = null;
                          } else {
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
          ),
        );
      },
    );
  }

  Widget _buildMobileFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    IconData? icon,
    String? avatar,
    required Color color,
    required int count,
  }) {
    return Consumer<ResponsiveProvider>(
      builder: (context, responsive, child) {
        return InkWell(
          onTap: onSelected,
          borderRadius: BorderRadius.circular(responsive.borderRadius),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.responsiveValue(
                mobile: 10.0,
                desktop: 12.0,
              ),
              vertical: responsive.responsiveValue(mobile: 6.0, desktop: 8.0),
            ),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? color.withOpacity(0.15)
                      : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              border: Border.all(
                color: isSelected ? color : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (avatar != null)
                  CircleAvatar(
                    backgroundColor:
                        isSelected ? color : AppColors.textSecondary,
                    radius: 6,
                    child: Text(
                      avatar,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsive.getResponsiveFontSize(8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (icon != null)
                  Icon(
                    icon,
                    size: responsive.getResponsiveFontSize(12),
                    color: isSelected ? color : AppColors.textSecondary,
                  ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: responsive.getResponsiveFontSize(12),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? color : AppColors.textSecondary,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? color.withOpacity(0.2)
                              : AppColors.textHint.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: responsive.getResponsiveFontSize(9),
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
      },
    );
  }

  Widget _buildMobileDrawer() {
    return Consumer<ResponsiveProvider>(
      builder: (context, responsive, child) {
        return Drawer(
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.developer_board,
                      color: Colors.white,
                      size: responsive.getResponsiveFontSize(32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Task Manager',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: responsive.getResponsiveFontSize(20),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Mobil Dashboard',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: responsive.getResponsiveFontSize(14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildMobileDrawerItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/dashboard');
                      },
                    ),
                    _buildMobileDrawerItem(
                      icon: Icons.add_task,
                      title: 'Yeni Görev',
                      onTap: () {
                        Navigator.pop(context);
                        _showAddTaskDialog(context);
                      },
                    ),
                    _buildMobileDrawerItem(
                      icon: Icons.people,
                      title: 'Kişiler',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/people');
                      },
                    ),
                    const Divider(),
                    _buildMobileDrawerItem(
                      icon: Icons.settings,
                      title: 'Ayarlar',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/settings');
                      },
                    ),
                    _buildMobileDrawerItem(
                      icon: Icons.logout,
                      title: 'Çıkış',
                      onTap: () {
                        Navigator.pop(context);
                        _handleLogout();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Consumer<ResponsiveProvider>(
      builder: (context, responsive, child) {
        return ListTile(
          leading: Icon(
            icon,
            color: AppColors.textSecondary,
            size: responsive.getResponsiveFontSize(20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: responsive.getResponsiveFontSize(16),
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          onTap: onTap,
        );
      },
    );
  }

  Widget _buildResponsiveWebHeader() {
    return Consumer<ResponsiveProvider>(
      builder: (context, responsive, child) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.responsiveValue(mobile: 16.0, desktop: 32.0),
            vertical: responsive.responsiveValue(mobile: 12.0, desktop: 16.0),
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.divider, width: 1),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Logo and Title Section
                  Spacer(),

                  // Search and Actions
                  SizedBox(
                    width: responsive.responsiveValue(
                      mobile: 12.0,
                      desktop: 24.0,
                    ),
                  ),
                  _buildSearchBar(),
                  SizedBox(
                    width: responsive.responsiveValue(
                      mobile: 8.0,
                      desktop: 16.0,
                    ),
                  ),
                  _buildHeaderActions(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Consumer<ResponsiveProvider>(
      builder: (context, responsive, child) {
        return Container(
          width: responsive.responsiveValue(
            mobile: 250.0,
            tablet: 280.0,
            desktop: 300.0,
          ),
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(responsive.borderRadius + 8),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Görev ara...',
              hintStyle: TextStyle(
                color: AppColors.textHint,
                fontSize: responsive.getResponsiveFontSize(14),
              ),
              prefixIcon: Icon(
                Icons.search,
                size: responsive.getResponsiveFontSize(20),
                color: AppColors.textSecondary,
              ),
              suffixIcon:
                  _isSearching
                      ? IconButton(
                        icon: Icon(
                          Icons.close,
                          size: responsive.getResponsiveFontSize(20),
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsive.responsiveValue(
                  mobile: 12.0,
                  desktop: 16.0,
                ),
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
      },
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
              case 'people':
                context.go('/people');
                break;
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
                  value: 'people',
                  child: ListTile(
                    leading: Icon(Icons.people),
                    title: Text('Kişiler'),
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
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Çıkış'),
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
                  style: const TextStyle(
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

  Widget _buildMobileSearchResults() {
    return Consumer<ResponsiveProvider>(
      builder: (context, responsive, child) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: responsive.responsiveValue(mobile: 16.0, desktop: 24.0),
            vertical: responsive.responsiveValue(mobile: 8.0, desktop: 12.0),
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(
                color: AppColors.divider.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                size: responsive.getResponsiveFontSize(16),
                color: AppColors.primary,
              ),
              SizedBox(
                width: responsive.responsiveValue(mobile: 8.0, desktop: 12.0),
              ),
              Expanded(
                child: Text(
                  '${_filteredTasks.length} sonuç bulundu',
                  style: TextStyle(
                    fontSize: responsive.getResponsiveFontSize(14),
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (_filteredTasks.isEmpty)
                Text(
                  'Sonuç bulunamadı',
                  style: TextStyle(
                    fontSize: responsive.getResponsiveFontSize(12),
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class ResponsiveWebSidePanel extends StatelessWidget {
  final List<Task> tasks;
  final VoidCallback onAddTask;
  final VoidCallback onManagePeople;
  final VoidCallback onShowFilters;

  const ResponsiveWebSidePanel({
    super.key,
    required this.tasks,
    required this.onAddTask,
    required this.onManagePeople,
    required this.onShowFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ResponsiveProvider>(
      builder: (context, responsive, child) {
        return Container(
          width: responsive.responsiveValue(
            mobile: 0.0,
            tablet: 280.0,
            desktop: 320.0,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: AppColors.divider, width: 1),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(
                  responsive.responsiveValue(mobile: 16.0, desktop: 24.0),
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.divider, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.developer_board,
                          color: AppColors.primary,
                          size: responsive.getResponsiveFontSize(24),
                        ),
                        SizedBox(
                          width: responsive.responsiveValue(
                            mobile: 8.0,
                            desktop: 12.0,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Task Manager',
                            style: TextStyle(
                              fontSize: responsive.getResponsiveFontSize(18),
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: responsive.responsiveValue(
                        mobile: 16.0,
                        desktop: 20.0,
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onAddTask,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'Yeni Görev',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(
                            vertical: responsive.responsiveValue(
                              mobile: 12.0,
                              desktop: 16.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(
                    responsive.responsiveValue(mobile: 12.0, desktop: 16.0),
                  ),
                  children: [
                    _buildSidebarItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      subtitle: '${tasks.length} görev',
                      onTap: () {},
                      responsive: responsive,
                    ),
                    _buildSidebarItem(
                      icon: Icons.people,
                      title: 'Kişiler',
                      subtitle: 'Ekip yönetimi',
                      onTap: onManagePeople,
                      responsive: responsive,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ResponsiveProvider responsive,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.textSecondary,
        size: responsive.getResponsiveFontSize(20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: responsive.getResponsiveFontSize(14),
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: responsive.getResponsiveFontSize(12),
          color: AppColors.textSecondary,
        ),
      ),
      onTap: onTap,
    );
  }
}
