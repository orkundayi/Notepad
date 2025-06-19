import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/person.dart';
import '../providers/person_provider.dart';
import '../providers/responsive_provider.dart';
import '../utils/theme.dart';
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
    return Consumer<ResponsiveProvider>(
      builder: (context, responsive, child) {
        if (responsive.isMobile) {
          return _buildMobileLayout(responsive);
        } else {
          return _buildWebLayout(responsive);
        }
      },
    );
  }

  // ====== MOBILE LAYOUT ======
  Widget _buildMobileLayout(ResponsiveProvider responsive) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildMobileAppBar(responsive),
      body: Column(
        children: [
          _buildMobileSearchSection(responsive),
          Expanded(child: _buildMobileContent(responsive)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPersonDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(ResponsiveProvider responsive) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/dashboard');
          }
        },
        icon: const Icon(Icons.arrow_back),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          foregroundColor: AppColors.primary,
        ),
      ),
      title: const Text(
        'Kişiler',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      actions: [
        IconButton(onPressed: _refreshPeople, icon: const Icon(Icons.refresh)),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
      ),
    );
  }

  Widget _buildMobileSearchSection(ResponsiveProvider responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.horizontalPadding),
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border.withOpacity(0.3)),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Kişi ara...',
                hintStyle: TextStyle(
                  color: AppColors.textHint,
                  fontSize: responsive.bodyFontSize,
                ),
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
                  vertical: 12,
                ),
              ),
              onChanged: _filterPeople,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileContent(ResponsiveProvider responsive) {
    return Consumer<PersonProvider>(
      builder: (context, personProvider, child) {
        if (personProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final people = _isSearching ? _filteredPeople : personProvider.people;

        if (people.isEmpty) {
          return _buildMobileEmptyState(responsive);
        }

        return _buildMobilePeopleList(people, responsive);
      },
    );
  }

  Widget _buildMobileEmptyState(ResponsiveProvider responsive) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(responsive.horizontalPadding * 2),
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
                size: responsive.isMobile ? 56 : 64,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: responsive.verticalSpacing * 2),
            Text(
              _isSearching ? 'Kişi Bulunamadı' : 'Henüz Kişi Yok',
              style: TextStyle(
                fontSize: responsive.titleFontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: responsive.verticalSpacing),
            Text(
              _isSearching
                  ? 'Arama kriterlerinize uygun kişi bulunamadı.'
                  : 'Projeye ilk kişinizi ekleyerek başlayın.',
              style: TextStyle(
                fontSize: responsive.bodyFontSize,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (!_isSearching) ...[
              SizedBox(height: responsive.verticalSpacing * 2),
              ElevatedButton.icon(
                onPressed: () => _showAddPersonDialog(),
                icon: const Icon(Icons.add),
                label: const Text('İlk Kişiyi Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.horizontalPadding * 2,
                    vertical: responsive.verticalSpacing,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      responsive.buttonRadius,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobilePeopleList(
    List<Person> people,
    ResponsiveProvider responsive,
  ) {
    return ListView.builder(
      padding: EdgeInsets.all(responsive.horizontalPadding),
      itemCount: people.length,
      itemBuilder: (context, index) {
        return _buildMobilePersonCard(people[index], responsive);
      },
    );
  }

  Widget _buildMobilePersonCard(Person person, ResponsiveProvider responsive) {
    return Container(
      margin: EdgeInsets.only(bottom: responsive.verticalSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(responsive.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => _showEditPersonDialog(person),
        borderRadius: BorderRadius.circular(responsive.cardRadius),
        child: Padding(
          padding: EdgeInsets.all(responsive.horizontalPadding),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                radius: responsive.isMobile ? 24 : 28,
                child: Text(
                  person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: responsive.isMobile ? 16 : 18,
                  ),
                ),
              ),
              SizedBox(width: responsive.horizontalPadding),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: responsive.subtitleFontSize,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: responsive.verticalSpacing / 2),
                    Text(
                      person.email,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: responsive.bodyFontSize,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (person.department != null || person.role != null) ...[
                      SizedBox(height: responsive.verticalSpacing / 2),
                      Row(
                        children: [
                          if (person.department != null) ...[
                            Icon(
                              Icons.business,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                person.department!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // More menu
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
                            Text('Sil', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.more_vert,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====== WEB LAYOUT ======
  Widget _buildWebLayout(ResponsiveProvider responsive) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: responsive.isLargeDesktop ? 320 : 280,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(right: BorderSide(color: AppColors.divider)),
            ),
            child: _buildWebSidebar(responsive),
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                _buildWebHeader(responsive),
                Expanded(child: _buildWebContent(responsive)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebSidebar(ResponsiveProvider responsive) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(responsive.horizontalPadding * 1.5),
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
              SizedBox(width: responsive.horizontalPadding),
              Expanded(
                child: Text(
                  'Kişiler',
                  style: TextStyle(
                    fontSize: responsive.titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(responsive.horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kişi Yönetimi',
                  style: TextStyle(
                    fontSize: responsive.subtitleFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: responsive.verticalSpacing),
                _buildWebActionButton(
                  icon: Icons.person_add,
                  title: 'Yeni Kişi Ekle',
                  subtitle: 'Projeye yeni bir kişi ekleyin',
                  onTap: () => _showAddPersonDialog(),
                  responsive: responsive,
                ),
                SizedBox(height: responsive.verticalSpacing),
                _buildWebActionButton(
                  icon: Icons.refresh,
                  title: 'Yenile',
                  subtitle: 'Kişi listesini yeniden yükleyin',
                  onTap: () => _refreshPeople(),
                  responsive: responsive,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ResponsiveProvider responsive,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(responsive.cardRadius),
      child: Container(
        padding: EdgeInsets.all(responsive.horizontalPadding),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(responsive.cardRadius),
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
            SizedBox(width: responsive.horizontalPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: responsive.bodyFontSize,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: responsive.captionFontSize,
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

  Widget _buildWebHeader(ResponsiveProvider responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.horizontalPadding * 1.5),
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
                  style: TextStyle(
                    fontSize: responsive.titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Projedeki kişileri yönetin ve düzenleyin',
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: responsive.horizontalPadding * 1.5),
          _buildWebSearchBar(responsive),
          SizedBox(width: responsive.horizontalPadding),
          ElevatedButton.icon(
            onPressed: () => _showAddPersonDialog(),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Yeni Kişi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalPadding * 1.25,
                vertical: responsive.verticalSpacing,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(responsive.buttonRadius),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebSearchBar(ResponsiveProvider responsive) {
    return Container(
      width: responsive.isLargeDesktop ? 350 : 300,
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
          hintStyle: TextStyle(
            color: AppColors.textHint,
            fontSize: responsive.bodyFontSize,
          ),
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

  Widget _buildWebContent(ResponsiveProvider responsive) {
    return Consumer<PersonProvider>(
      builder: (context, personProvider, child) {
        if (personProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final people = _isSearching ? _filteredPeople : personProvider.people;

        if (people.isEmpty) {
          return _buildWebEmptyState(responsive);
        }

        return _buildWebPeopleGrid(people, responsive);
      },
    );
  }

  Widget _buildWebEmptyState(ResponsiveProvider responsive) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(responsive.horizontalPadding * 3),
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
            SizedBox(height: responsive.verticalSpacing * 2),
            Text(
              _isSearching ? 'Kişi Bulunamadı' : 'Henüz Kişi Yok',
              style: TextStyle(
                fontSize: responsive.titleFontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: responsive.verticalSpacing),
            Text(
              _isSearching
                  ? 'Arama kriterlerinize uygun kişi bulunamadı.'
                  : 'Projeye ilk kişinizi ekleyerek başlayın.',
              style: TextStyle(
                fontSize: responsive.bodyFontSize,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (!_isSearching) ...[
              SizedBox(height: responsive.verticalSpacing * 2),
              ElevatedButton.icon(
                onPressed: () => _showAddPersonDialog(),
                icon: const Icon(Icons.add),
                label: const Text('İlk Kişiyi Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.horizontalPadding * 1.5,
                    vertical: responsive.verticalSpacing,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      responsive.buttonRadius,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWebPeopleGrid(
    List<Person> people,
    ResponsiveProvider responsive,
  ) {
    return Padding(
      padding: EdgeInsets.all(responsive.horizontalPadding * 1.5),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getWebCrossAxisCount(responsive),
          crossAxisSpacing: responsive.horizontalPadding,
          mainAxisSpacing: responsive.verticalSpacing,
          childAspectRatio: 1.2,
        ),
        itemCount: people.length,
        itemBuilder: (context, index) {
          return _buildWebPersonCard(people[index], responsive);
        },
      ),
    );
  }

  int _getWebCrossAxisCount(ResponsiveProvider responsive) {
    final sidebarWidth = responsive.isLargeDesktop ? 320.0 : 280.0;
    final availableWidth = responsive.screenWidth - sidebarWidth;

    if (availableWidth > 1400) return 5;
    if (availableWidth > 1200) return 4;
    if (availableWidth > 900) return 3;
    if (availableWidth > 600) return 2;
    return 1;
  }

  Widget _buildWebPersonCard(Person person, ResponsiveProvider responsive) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(responsive.cardRadius),
        side: BorderSide(color: AppColors.border, width: 1),
      ),
      child: InkWell(
        onTap: () => _showEditPersonDialog(person),
        borderRadius: BorderRadius.circular(responsive.cardRadius),
        child: Padding(
          padding: EdgeInsets.all(responsive.horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with avatar and more options
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    radius: responsive.isLargeDesktop ? 28 : 24,
                    child: Text(
                      person.name.isNotEmpty
                          ? person.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: responsive.isLargeDesktop ? 20 : 18,
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
              SizedBox(height: responsive.verticalSpacing),

              // Name
              Text(
                person.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: responsive.subtitleFontSize,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Email
              Text(
                person.email,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: responsive.bodyFontSize,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: responsive.verticalSpacing / 2),

              // Department and Role
              if (person.department != null || person.role != null) ...[
                if (person.department != null)
                  _buildWebInfoChip(
                    person.department!,
                    Icons.business,
                    responsive,
                  ),
                if (person.role != null) ...[
                  const SizedBox(height: 4),
                  _buildWebInfoChip(person.role!, Icons.work, responsive),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebInfoChip(
    String text,
    IconData icon,
    ResponsiveProvider responsive,
  ) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: responsive.captionFontSize,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ====== HELPER FUNCTIONS ======
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
