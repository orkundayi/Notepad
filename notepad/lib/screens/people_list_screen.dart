import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/person.dart';
import '../providers/person_provider.dart';
import '../utils/theme.dart';
import '../utils/platform_utils.dart';
import '../widgets/add_person_dialog.dart';
import '../widgets/edit_person_dialog.dart';

class PeopleListScreen extends StatefulWidget {
  const PeopleListScreen({super.key});

  @override
  State<PeopleListScreen> createState() => _PeopleListScreenState();
}

class _PeopleListScreenState extends State<PeopleListScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  List<Person> _filteredPeople = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PersonProvider>(context, listen: false).loadPeople();
    });
  }

  @override
  void dispose() {
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
          // Sidebar
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(right: BorderSide(color: AppColors.divider)),
            ),
            child: _buildSidebar(),
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                _buildWebHeader(),
                Expanded(child: _buildWebContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/dashboard');
                  }
                },
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Kişiler',
                  style: PlatformUtils.getTitleStyle(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kişi Yönetimi',
                  style: PlatformUtils.getSubtitleStyle(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  icon: Icons.person_add,
                  title: 'Yeni Kişi Ekle',
                  subtitle: 'Projeye yeni bir kişi ekleyin',
                  onTap: () => _showAddPersonDialog(),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  icon: Icons.refresh,
                  title: 'Yenile',
                  subtitle: 'Kişi listesini yeniden yükleyin',
                  onTap: () => _refreshPeople(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: PlatformUtils.getCardRadius(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: PlatformUtils.getCardRadius(),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kişi Yönetimi',
                  style: PlatformUtils.getTitleStyle(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Projedeki kişileri yönetin ve düzenleyin',
                  style: PlatformUtils.getBodyStyle(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          _buildSearchBar(),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddPersonDialog(),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Yeni Kişi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: PlatformUtils.getButtonRadius(),
              ),
            ),
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
          hintText: 'Kişi ara...',
          hintStyle: const TextStyle(color: AppColors.textHint),
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: AppColors.textSecondary,
          ),
          suffixIcon:
              _isSearching
                  ? IconButton(
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.clear, size: 20),
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
        onChanged: _filterPeople,
      ),
    );
  }

  Widget _buildWebContent() {
    return Consumer<PersonProvider>(
      builder: (context, personProvider, child) {
        if (personProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final people = _isSearching ? _filteredPeople : personProvider.people;

        if (people.isEmpty) {
          return _buildWebEmptyState();
        }

        return _buildWebPeopleGrid(people);
      },
    );
  }

  Widget _buildWebEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isSearching ? 'Kişi Bulunamadı' : 'Henüz Kişi Yok',
              style: PlatformUtils.getTitleStyle(
                context,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _isSearching
                  ? 'Arama kriterlerinize uygun kişi bulunamadı.'
                  : 'Projeye ilk kişinizi ekleyerek başlayın.',
              style: PlatformUtils.getBodyStyle(
                context,
              ).copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (!_isSearching)
              ElevatedButton.icon(
                onPressed: () => _showAddPersonDialog(),
                icon: const Icon(Icons.add),
                label: const Text('İlk Kişiyi Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: PlatformUtils.getButtonRadius(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebPeopleGrid(List<Person> people) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(),
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.2,
        ),
        itemCount: people.length,
        itemBuilder: (context, index) {
          return _buildWebPersonCard(people[index]);
        },
      ),
    );
  }

  int _getCrossAxisCount() {
    final width =
        MediaQuery.of(context).size.width - 280; // Subtract sidebar width
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildWebPersonCard(Person person) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: PlatformUtils.getCardRadius(),
        side: BorderSide(color: AppColors.border, width: 1),
      ),
      child: InkWell(
        onTap: () => _showEditPersonDialog(person),
        borderRadius: PlatformUtils.getCardRadius(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with avatar and more options
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    radius: 24,
                    child: Text(
                      person.name.isNotEmpty
                          ? person.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditPersonDialog(person);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(person);
                          break;
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('Düzenle'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Sil',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.more_vert,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Name
              Text(
                person.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Email
              Text(
                person.email,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Department and Role
              if (person.department != null || person.role != null) ...[
                if (person.department != null)
                  _buildInfoChip(person.department!, Icons.business),
                if (person.role != null) ...[
                  const SizedBox(height: 4),
                  _buildInfoChip(person.role!, Icons.work),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _filterPeople(String query) {
    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    final allPeople = personProvider.people;

    setState(() {
      _isSearching = query.isNotEmpty;
      if (_isSearching) {
        _filteredPeople =
            allPeople.where((person) {
              return person.name.toLowerCase().contains(query.toLowerCase()) ||
                  person.email.toLowerCase().contains(query.toLowerCase()) ||
                  (person.department?.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ??
                      false) ||
                  (person.role?.toLowerCase().contains(query.toLowerCase()) ??
                      false);
            }).toList();
      } else {
        _filteredPeople.clear();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _filteredPeople.clear();
    });
  }

  void _refreshPeople() {
    Provider.of<PersonProvider>(context, listen: false).loadPeople();
  }

  void _showAddPersonDialog() {
    showDialog(context: context, builder: (context) => const AddPersonDialog());
  }

  void _showEditPersonDialog(Person person) {
    showDialog(
      context: context,
      builder: (context) => EditPersonDialog(person: person),
    );
  }

  void _showDeleteConfirmation(Person person) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Kişiyi Sil'),
            content: Text(
              '${person.name} kişisini silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  navigator.pop();
                  try {
                    await Provider.of<PersonProvider>(
                      context,
                      listen: false,
                    ).deletePerson(person.id);
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Kişi başarıyla silindi'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Hata: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Sil'),
              ),
            ],
          ),
    );
  }
}
