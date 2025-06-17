import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/person.dart';
import '../providers/person_provider.dart';
import '../utils/theme.dart';
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
    return Scaffold(
      appBar: AppBar(
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
      ),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isSearching
                        ? 'Arama sonucu bulunamadı'
                        : 'Henüz kişi eklenmemiş',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (!_isSearching) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddPersonDialog(),
                      icon: const Icon(Icons.person_add),
                      label: const Text('İlk Kişiyi Ekle'),
                    ),
                  ],
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await personProvider.loadPeople();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: people.length,
              itemBuilder: (context, index) {
                return _PersonCard(
                  person: people[index],
                  onEdit: () => _showEditPersonDialog(people[index]),
                  onDelete: () => _showDeleteConfirmation(people[index]),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPersonDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Yeni Kişi'),
      ),
    );
  }

  void _filterPeople(String query) {
    final personProvider = Provider.of<PersonProvider>(context, listen: false);
    setState(() {
      _filteredPeople = personProvider.searchPeople(query);
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

  void _showDeleteConfirmation(Person person) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Kişiyi Sil'),
            content: Text(
              '"${person.name}" kişisini silmek istediğinizden emin misiniz?\n\n'
              'Bu işlem geri alınamaz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    final personProvider = Provider.of<PersonProvider>(
                      context,
                      listen: false,
                    );
                    await personProvider.deletePerson(person.id);

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kişi başarıyla silindi'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Hata: ${e.toString()}'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Sil'),
              ),
            ],
          ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final Person person;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PersonCard({
    required this.person,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      person.name.isNotEmpty
                          ? person.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and Email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          person.email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          onDelete();
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
                                Icon(
                                  Icons.delete,
                                  size: 16,
                                  color: AppColors.error,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Sil',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ],
                            ),
                          ),
                        ],
                    child: const Icon(
                      Icons.more_vert,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // Department and Role
              if (person.department != null || person.role != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (person.department != null)
                      Chip(
                        label: Text(person.department!),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        labelStyle: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    if (person.role != null)
                      Chip(
                        label: Text(person.role!),
                        backgroundColor: AppColors.secondary.withOpacity(0.1),
                        labelStyle: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 12,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],

              // Footer
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    'Eklendi: ${DateFormat('dd/MM/yyyy').format(person.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                  if (person.createdAt != person.updatedAt) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.update, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      'Güncellendi: ${DateFormat('dd/MM/yyyy').format(person.updatedAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
