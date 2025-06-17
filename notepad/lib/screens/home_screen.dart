import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/person_provider.dart';
import '../models/task.dart';
import '../models/person.dart';
import '../utils/theme.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/add_person_dialog.dart';

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
    // Initialize provider after the build phase
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
          // Person filter button
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
          // Mode toggle button - only show on mobile
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

  Widget _buildTaskList(TaskStatus status, TaskProvider taskProvider) {
    List<Task> tasks;

    if (_isSearching && _isPersonFilterActive) {
      // Both search and person filter active
      tasks = _filteredTasks.where((task) => task.status == status).toList();
    } else if (_isSearching) {
      // Only search active
      tasks = _filteredTasks.where((task) => task.status == status).toList();
    } else if (_isPersonFilterActive) {
      // Only person filter active
      _updateFilteredTasks(); // Ensure filtered tasks are up to date
      tasks = _filteredTasks.where((task) => task.status == status).toList();
    } else {
      // No filters active
      tasks = taskProvider.getTasksByStatus(status);
    }

    if (tasks.isEmpty) {
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
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return TaskCard(
            task: tasks[index],
            onStatusChanged: (newStatus) {
              taskProvider.updateTaskStatus(tasks[index].id, newStatus);
            },
            onEdit: () => _showEditTaskDialog(context, tasks[index]),
            onDelete:
                () => _showDeleteConfirmation(
                  context,
                  tasks[index],
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
        return Icons.list;
      case TaskStatus.inProgress:
        return Icons.play_arrow;
      case TaskStatus.done:
        return Icons.check_circle;
      case TaskStatus.blocked:
        return Icons.block;
    }
  }

  void _filterTasks(String query) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    List<Task> searchResults = taskProvider.searchTasks(query);

    setState(() {
      if (_isPersonFilterActive) {
        // Apply person filter to search results
        if (_selectedPersonFilter == null) {
          // Filter unassigned tasks from search results
          _filteredTasks =
              searchResults.where((task) => task.assignedToId == null).toList();
        } else {
          // Filter by specific person from search results
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
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Task silindi')));
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
                  ? 'Online moda geçmek istediğinizden emin misiniz? Verileriniz Firebase ile senkronize edilecek.'
                  : 'Offline moda geçmek istediğinizden emin misiniz? Verileriniz sadece bu cihazda saklanacak.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
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
                    // All tasks option
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
                    // Unassigned tasks option
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
                    // People list
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

  int _getTaskCountForStatus(TaskStatus status, TaskProvider taskProvider) {
    if (_isSearching && _isPersonFilterActive) {
      return _filteredTasks.where((t) => t.status == status).length;
    } else if (_isSearching) {
      return _filteredTasks.where((t) => t.status == status).length;
    } else if (_isPersonFilterActive) {
      _updateFilteredTasks();
      return _filteredTasks.where((t) => t.status == status).length;
    } else {
      return taskProvider.getTasksByStatus(status).length;
    }
  }

  void _updateFilteredTasks() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final allTasks = taskProvider.tasks;

    if (!_isPersonFilterActive) {
      _filteredTasks.clear();
      return;
    }

    if (_selectedPersonFilter == null) {
      // Filter unassigned tasks
      _filteredTasks =
          allTasks.where((task) => task.assignedToId == null).toList();
    } else {
      // Filter by specific person
      _filteredTasks =
          allTasks
              .where((task) => task.assignedToId == _selectedPersonFilter!.id)
              .toList();
    }
  }
}
