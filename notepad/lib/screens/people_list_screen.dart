import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/person.dart';
import '../providers/person_provider.dart';
import '../utils/theme.dart';
import '../utils/platform_utils.dart';
import '../widgets/edit_person_dialog.dart';
import '../widgets/add_person_dialog.dart';

class PeopleListScreen extends StatefulWidget {
  const PeopleListScreen({super.key});

  @override
  State<PeopleListScreen> createState() => _PeopleListScreenState();
}

class _PeopleListScreenState extends State<PeopleListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Person> _filteredPeople = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformUtils.isWeb ? _buildWebLayout() : _buildMobileLayout();
  }

  Widget _buildWebLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildWebAppBar(),
      body: SizedBox(
        width: double.infinity,
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: PlatformUtils.getContentWidth(context),
            ),
            padding: PlatformUtils.getPagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                _buildWebHeader(),
                SizedBox(height: PlatformUtils.getSpacing(3)),

                // People grid/list
                Expanded(
                  child: Consumer<PersonProvider>(
                    builder: (context, personProvider, child) {
                      if (personProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final people =
                          _isSearching && _filteredPeople.isNotEmpty
                              ? _filteredPeople
                              : personProvider.people;

                      if (people.isEmpty) {
                        return _buildWebEmptyState();
                      }

                      return _buildWebPeopleGrid(people);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: _buildMobileAppBar(),
      body: Consumer<PersonProvider>(
        builder: (context, personProvider, child) {
          if (personProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final people =
              _isSearching && _filteredPeople.isNotEmpty
                  ? _filteredPeople
                  : personProvider.people;

          if (people.isEmpty) {
            return _buildMobileEmptyState();
          }

          return _buildMobilePeopleList(people);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPersonDialog(),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  PreferredSizeWidget _buildWebAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      toolbarHeight: PlatformUtils.getAppBarHeight(),
      title: Row(
        children: [
          Icon(
            Icons.people,
            size: PlatformUtils.getIconSize(),
            color: AppColors.primary,
          ),
          SizedBox(width: PlatformUtils.getSpacing(1)),
          Text('Kişiler', style: PlatformUtils.getTitleStyle(context)),
        ],
      ),
      actions: [
        if (_isSearching)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Kişi ara...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                        _filteredPeople.clear();
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: PlatformUtils.getButtonRadius(),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: _filterPeople,
              ),
            ),
          )
        else ...[
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
            tooltip: 'Ara',
          ),
          SizedBox(width: PlatformUtils.getSpacing(1)),
          ElevatedButton.icon(
            onPressed: () => _showAddPersonDialog(),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Kişi Ekle'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: PlatformUtils.getButtonRadius(),
              ),
            ),
          ),
          SizedBox(width: PlatformUtils.getSpacing(2)),
        ],
      ],
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      title:
          _isSearching
              ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Kişi ara...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: _filterPeople,
              )
              : const Text('Kişiler'),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              if (_isSearching) {
                _isSearching = false;
                _searchController.clear();
                _filteredPeople.clear();
              } else {
                _isSearching = true;
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildWebHeader() {
    return Card(
      elevation: PlatformUtils.getCardElevation(),
      shape: RoundedRectangleBorder(
        borderRadius: PlatformUtils.getCardRadius(),
      ),
      child: Padding(
        padding: PlatformUtils.getCardPadding(),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kişi Yönetimi',
                    style: PlatformUtils.getTitleStyle(context).copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: PlatformUtils.getSpacing(0.5)),
                  Text(
                    'Projenizde çalışan kişileri yönetin, görevler atayın',
                    style: PlatformUtils.getBodyStyle(
                      context,
                    ).copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Consumer<PersonProvider>(
              builder: (context, personProvider, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${personProvider.people.length} Kişi',
                    style: PlatformUtils.getBodyStyle(context).copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebEmptyState() {
    return Center(
      child: Card(
        elevation: PlatformUtils.getCardElevation(),
        shape: RoundedRectangleBorder(
          borderRadius: PlatformUtils.getCardRadius(),
        ),
        child: Container(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
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
              SizedBox(height: PlatformUtils.getSpacing(3)),
              Text(
                _isSearching
                    ? 'Arama sonucu bulunamadı'
                    : 'Henüz kişi eklenmemiş',
                style: PlatformUtils.getTitleStyle(
                  context,
                ).copyWith(color: AppColors.textSecondary),
              ),
              SizedBox(height: PlatformUtils.getSpacing(1)),
              Text(
                _isSearching
                    ? 'Farklı anahtar kelimeler deneyebilirsiniz'
                    : 'İlk kişiyi ekleyerek başlayın',
                style: PlatformUtils.getBodyStyle(
                  context,
                ).copyWith(color: AppColors.textHint),
              ),
              if (!_isSearching) ...[
                SizedBox(height: PlatformUtils.getSpacing(3)),
                ElevatedButton.icon(
                  onPressed: () => _showAddPersonDialog(),
                  icon: const Icon(Icons.person_add),
                  label: const Text('İlk Kişiyi Ekle'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: PlatformUtils.getButtonRadius(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileEmptyState() {
    return Center(
      child: Padding(
        padding: PlatformUtils.getPagePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textHint,
            ),
            SizedBox(height: PlatformUtils.getSpacing(2)),
            Text(
              _isSearching
                  ? 'Arama sonucu bulunamadı'
                  : 'Henüz kişi eklenmemiş',
              style: PlatformUtils.getSubtitleStyle(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
            if (!_isSearching) ...[
              SizedBox(height: PlatformUtils.getSpacing(2)),
              ElevatedButton.icon(
                onPressed: () => _showAddPersonDialog(),
                icon: const Icon(Icons.person_add),
                label: const Text('İlk Kişiyi Ekle'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWebPeopleGrid(List<Person> people) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: PlatformUtils.isLargeScreen(context) ? 3 : 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: PlatformUtils.getSpacing(2),
        mainAxisSpacing: PlatformUtils.getSpacing(2),
      ),
      itemCount: people.length,
      itemBuilder: (context, index) {
        final person = people[index];
        return _buildWebPersonCard(person);
      },
    );
  }

  Widget _buildMobilePeopleList(List<Person> people) {
    return ListView.builder(
      padding: PlatformUtils.getPagePadding(context),
      itemCount: people.length,
      itemBuilder: (context, index) {
        final person = people[index];
        return _buildMobilePersonCard(person);
      },
    );
  }

  Widget _buildWebPersonCard(Person person) {
    return Card(
      elevation: PlatformUtils.getCardElevation(),
      shape: RoundedRectangleBorder(
        borderRadius: PlatformUtils.getCardRadius(),
      ),
      child: InkWell(
        onTap: () => _showEditPersonDialog(person),
        borderRadius: PlatformUtils.getCardRadius(),
        child: Padding(
          padding: PlatformUtils.getCardPadding(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with actions
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
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
                      if (value == 'edit') {
                        _showEditPersonDialog(person);
                      } else if (value == 'delete') {
                        _deletePerson(person);
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
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.more_vert,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: PlatformUtils.getSpacing(2)),

              // Name and title
              Text(
                person.name,
                style: PlatformUtils.getSubtitleStyle(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (person.role?.isNotEmpty == true) ...[
                SizedBox(height: PlatformUtils.getSpacing(0.5)),
                Text(
                  person.role!,
                  style: PlatformUtils.getBodyStyle(
                    context,
                  ).copyWith(color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const Spacer(),

              // Footer info
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy').format(person.createdAt),
                    style: PlatformUtils.getCaptionStyle(
                      context,
                    ).copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobilePersonCard(Person person) {
    return Card(
      margin: EdgeInsets.only(bottom: PlatformUtils.getSpacing(1.5)),
      elevation: PlatformUtils.getCardElevation(),
      shape: RoundedRectangleBorder(
        borderRadius: PlatformUtils.getCardRadius(),
      ),
      child: ListTile(
        onTap: () => _showEditPersonDialog(person),
        contentPadding: PlatformUtils.getCardPadding(),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          person.name,
          style: PlatformUtils.getSubtitleStyle(context),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (person.role?.isNotEmpty == true) ...[
              SizedBox(height: PlatformUtils.getSpacing(0.5)),
              Text(
                person.role!,
                style: PlatformUtils.getBodyStyle(
                  context,
                ).copyWith(color: Colors.grey[600]),
              ),
            ],
            SizedBox(height: PlatformUtils.getSpacing(0.5)),
            Text(
              DateFormat('dd/MM/yyyy').format(person.createdAt),
              style: PlatformUtils.getCaptionStyle(
                context,
              ).copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditPersonDialog(person);
            } else if (value == 'delete') {
              _deletePerson(person);
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
                      Text('Sil', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
        ),
      ),
    );
  }

  void _filterPeople(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredPeople.clear();
      });
      return;
    }

    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    final filtered =
        personProvider.people.where((person) {
          return person.name.toLowerCase().contains(query.toLowerCase()) ||
              (person.role?.toLowerCase().contains(query.toLowerCase()) ==
                  true);
        }).toList();

    setState(() {
      _filteredPeople = filtered;
    });
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

  void _deletePerson(Person person) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Kişiyi Sil'),
            content: Text(
              '${person.name} kişisini silmek istediğinizden emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final personProvider = Provider.of<PersonProvider>(
                    context,
                    listen: false,
                  );
                  await personProvider.deletePerson(person.id);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Sil'),
              ),
            ],
          ),
    );
  }
}
