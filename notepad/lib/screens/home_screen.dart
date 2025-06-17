import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/person_provider.dart';
import '../models/task.dart';
import '../models/person.dart';
import '../utils/theme.dart';
import '../utils/platform_utils.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/add_person_dialog.dart';
import '../widgets/web_kanban_layout.dart';

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
    await personProvider.initialize(
      authProvider.user,
      taskProvider.isOfflineMode,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformUtils.isWeb ? _buildWebLayout() : _buildMobileLayout();
  }

  Widget _buildWebLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Side Panel
          Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              final tasks = _getFilteredTasks(taskProvider);

              return WebSidePanel(
                tasks: tasks,
                onAddTask: () => _showAddTaskDialog(context),
                onManagePeople: () => Navigator.pushNamed(context, '/people'),
                onShowFilters: () => _showPersonFilterDialog(),
              );
            },
          ),

          // Main Content
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: Column(
                children: [
                  _buildWebHeader(),
                  Expanded(
                    child: Padding(
                      padding: PlatformUtils.getPagePadding(context),
                      child: Consumer<TaskProvider>(
                        builder: (context, taskProvider, child) {
                          if (taskProvider.isLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final tasks = _getFilteredTasks(taskProvider);

                          return WebKanbanLayout(
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Task Manager',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Web Dashboard',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),

          const Spacer(),

          Container(
            width: 300,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Task ara...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon:
                    _isSearching
                        ? IconButton(
                          icon: const Icon(Icons.close, size: 20),
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
          ),

          const SizedBox(width: 16),

          if (_isPersonFilterActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list, size: 16, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    _selectedPersonFilter?.name ?? 'Atanmamış',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(width: 16),

          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            child: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'people',
                    child: Row(
                      children: [
                        Icon(Icons.people),
                        SizedBox(width: 8),
                        Text('Kişileri Yönet'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Çıkış Yap'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Task ara...',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                  onChanged: _filterTasks,
                )
                : const Text('Task Manager'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _filteredTasks.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          Consumer<PersonProvider>(
            builder: (context, personProvider, child) {
              return IconButton(
                icon: Icon(
                  _isPersonFilterActive ? Icons.person : Icons.person_outline,
                  color:
                      _isPersonFilterActive ? AppColors.warning : Colors.white,
                ),
                onPressed: () => _showPersonFilterDialog(),
                tooltip: 'Kişiye Göre Filtrele',
              );
            },
          ),
          if (!kIsWeb)
            Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                return IconButton(
                  icon: Icon(
                    taskProvider.isOfflineMode
                        ? Icons.offline_bolt
                        : Icons.cloud,
                    color:
                        taskProvider.isOfflineMode
                            ? AppColors.warning
                            : Colors.white,
                  ),
                  onPressed: () {
                    _showModeToggleDialog(context, taskProvider);
                  },
                );
              },
            ),
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'people',
                    child: Row(
                      children: [
                        Icon(Icons.people),
                        SizedBox(width: 8),
                        Text('Kişileri Yönet'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Çıkış Yap'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.list, size: 16),
                  const SizedBox(width: 4),
                  Consumer<TaskProvider>(
                    builder: (context, taskProvider, child) {
                      return Text(
                        'Todo (${_getTaskCountForStatus(TaskStatus.todo, taskProvider)})',
                      );
                    },
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow, size: 16),
                  const SizedBox(width: 4),
                  Consumer<TaskProvider>(
                    builder: (context, taskProvider, child) {
                      return Text(
                        'Devam (${_getTaskCountForStatus(TaskStatus.inProgress, taskProvider)})',
                      );
                    },
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 16),
                  const SizedBox(width: 4),
                  Consumer<TaskProvider>(
                    builder: (context, taskProvider, child) {
                      return Text(
                        'Bitti (${_getTaskCountForStatus(TaskStatus.done, taskProvider)})',
                      );
                    },
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.block, size: 16),
                  const SizedBox(width: 4),
                  Consumer<TaskProvider>(
                    builder: (context, taskProvider, child) {
                      return Text(
                        'Bloke (${_getTaskCountForStatus(TaskStatus.blocked, taskProvider)})',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          if (taskProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTaskList(TaskStatus.todo, taskProvider),
              _buildTaskList(TaskStatus.inProgress, taskProvider),
              _buildTaskList(TaskStatus.done, taskProvider),
              _buildTaskList(TaskStatus.blocked, taskProvider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Task'),
      ),
    );
  }

  List<Task> _getFilteredTasks(TaskProvider taskProvider) {
    if (_isSearching && _isPersonFilterActive) {
      return _filteredTasks;
    } else if (_isSearching) {
      return _filteredTasks;
    } else if (_isPersonFilterActive) {
      _updateFilteredTasks();
      return _filteredTasks;
    } else {
      return taskProvider.tasks;
    }
  }

  int _getTaskCountForStatus(TaskStatus status, TaskProvider taskProvider) {
    final tasks = _getFilteredTasks(taskProvider);
    return tasks.where((t) => t.status == status).length;
  }

  void _updateFilteredTasks() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final allTasks = taskProvider.tasks;

    if (!_isPersonFilterActive) {
      _filteredTasks.clear();
      return;
    }

    if (_selectedPersonFilter == null) {
      _filteredTasks =
          allTasks.where((task) => task.assignedToId == null).toList();
    } else {
      _filteredTasks =
          allTasks
              .where((task) => task.assignedToId == _selectedPersonFilter!.id)
              .toList();
    }
  }

  void _filterTasks(String query) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    List<Task> searchResults = taskProvider.searchTasks(query);

    setState(() {
      if (_isPersonFilterActive) {
        if (_selectedPersonFilter == null) {
          _filteredTasks =
              searchResults.where((task) => task.assignedToId == null).toList();
        } else {
          _filteredTasks =
              searchResults
                  .where(
                    (task) => task.assignedToId == _selectedPersonFilter!.id,
                  )
                  .toList();
        }
      } else {
        _filteredTasks = searchResults;
      }
    });
  }

  Widget _buildTaskList(TaskStatus status, TaskProvider taskProvider) {
    final tasks = _getFilteredTasks(taskProvider);
    final statusTasks = tasks.where((task) => task.status == status).toList();

    if (statusTasks.isEmpty) {
      String emptyMessage;
      if (_isSearching && _isPersonFilterActive) {
        emptyMessage = 'Arama ve filtre sonucu bulunamadı';
      } else if (_isSearching) {
        emptyMessage = 'Arama sonucu bulunamadı';
      } else if (_isPersonFilterActive) {
        emptyMessage =
            _selectedPersonFilter == null
                ? 'Atanmamış ${status.displayName.toLowerCase()} task yok'
                : '${_selectedPersonFilter!.name} için ${status.displayName.toLowerCase()} task yok';
      } else {
        emptyMessage = 'Henüz ${status.displayName.toLowerCase()} task yok';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getStatusIcon(status), size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_isPersonFilterActive || _isSearching) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  if (_isPersonFilterActive) _clearPersonFilter();
                  if (_isSearching) {
                    setState(() {
                      _isSearching = false;
                      _searchController.clear();
                      _filteredTasks.clear();
                    });
                  }
                },
                child: const Text('Filtreleri Temizle'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await taskProvider.loadTasks();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: statusTasks.length,
        itemBuilder: (context, index) {
          return TaskCard(
            task: statusTasks[index],
            onStatusChanged: (newStatus) {
              taskProvider.updateTaskStatus(statusTasks[index].id, newStatus);
            },
            onEdit: () => _showEditTaskDialog(context, statusTasks[index]),
            onDelete:
                () => _showDeleteConfirmation(
                  context,
                  statusTasks[index],
                  taskProvider,
                ),
          );
        },
      ),
    );
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        return Icons.play_circle_outline;
      case TaskStatus.done:
        return Icons.check_circle;
      case TaskStatus.blocked:
        return Icons.block;
    }
  }

  void _showPersonFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Consumer<PersonProvider>(
            builder: (context, personProvider, child) {
              return AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.person, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Kişiye Göre Filtrele'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.list),
                      title: const Text('Tüm Tasklar'),
                      subtitle: const Text('Filtreyi kaldır'),
                      onTap: () {
                        _clearPersonFilter();
                        Navigator.pop(context);
                      },
                      selected: !_isPersonFilterActive,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.person_off),
                      title: const Text('Atanmamış Tasklar'),
                      subtitle: const Text('Kimseye atanmamış tasklar'),
                      onTap: () {
                        _filterByUnassigned();
                        Navigator.pop(context);
                      },
                      selected:
                          _isPersonFilterActive &&
                          _selectedPersonFilter == null,
                    ),
                    const Divider(),
                    ...personProvider.people.map((person) {
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(person.name),
                        subtitle: Text(person.email),
                        onTap: () {
                          _filterByPerson(person);
                          Navigator.pop(context);
                        },
                        selected:
                            _isPersonFilterActive &&
                            _selectedPersonFilter?.id == person.id,
                      );
                    }),
                    if (personProvider.people.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Henüz kişi eklenmemiş',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/people');
                    },
                    child: const Text('Kişileri Yönet'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAddPersonDialog();
                    },
                    child: const Text('Yeni Kişi Ekle'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showAddPersonDialog() {
    showDialog(context: context, builder: (context) => const AddPersonDialog());
  }

  void _clearPersonFilter() {
    setState(() {
      _isPersonFilterActive = false;
      _selectedPersonFilter = null;
      _filteredTasks.clear();
    });
  }

  void _filterByUnassigned() {
    setState(() {
      _isPersonFilterActive = true;
      _selectedPersonFilter = null;
      _updateFilteredTasks();
    });
  }

  void _filterByPerson(Person person) {
    setState(() {
      _isPersonFilterActive = true;
      _selectedPersonFilter = person;
      _updateFilteredTasks();
    });
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const AddTaskDialog());
  }

  void _showEditTaskDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(task: task),
    );
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
            title: const Text('Task\'ı Sil'),
            content: Text(
              '"${task.title}" task\'ını silmek istediğinizden emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () {
                  taskProvider.deleteTask(task.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Task başarıyla silindi'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Sil'),
              ),
            ],
          ),
    );
  }

  void _showModeToggleDialog(BuildContext context, TaskProvider taskProvider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              taskProvider.isOfflineMode
                  ? 'Online Moda Geç'
                  : 'Offline Moda Geç',
            ),
            content: Text(
              taskProvider.isOfflineMode
                  ? 'Online moda geçmek istediğinizden emin misiniz? Yerel veriler senkronize edilecek.'
                  : 'Offline moda geçmek istediğinizden emin misiniz? İnternet bağlantısı olmadan çalışabilirsiniz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  taskProvider.toggleOfflineMode();
                  Navigator.pop(context);
                },
                child: const Text('Değiştir'),
              ),
            ],
          ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'people':
        Navigator.pushNamed(context, '/people');
        break;
      case 'logout':
        _handleLogout();
        break;
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Çıkış Yap'),
            content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () async {
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  final taskProvider = Provider.of<TaskProvider>(
                    context,
                    listen: false,
                  );

                  await authProvider.signOut();
                  await taskProvider.clearAllData();

                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Çıkış Yap'),
              ),
            ],
          ),
    );
  }
}
