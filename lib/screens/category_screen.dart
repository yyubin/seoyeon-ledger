import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/category_group.dart';
import '../models/transaction_type.dart';
import '../services/hive_service.dart';
import '../widgets/category_color_palette.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshDefaults();
  }

  Future<void> _refreshDefaults() async {
    await HiveService.ensureDefaultGroups();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  TransactionType get _currentType =>
      _tabController.index == 0 ? TransactionType.income : TransactionType.expense;

  Future<void> _addGroup(TransactionType type) async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('분류 추가'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '분류 이름',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('추가'),
          ),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty) {
      final order = HiveService.getCategoryGroups(type: type).length;
      final group = CategoryGroup(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.trim(),
        type: type,
        order: order,
      );
      await HiveService.addCategoryGroup(group);
      _changed = true;
      setState(() {});
    }
  }

  Future<void> _editGroup(CategoryGroup group) async {
    final nameController = TextEditingController(text: group.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('분류 이름 수정'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '분류 이름',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty) {
      group.name = name.trim();
      await HiveService.updateCategoryGroup(group);
      _changed = true;
      setState(() {});
    }
  }

  Future<void> _deleteGroup(CategoryGroup group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('분류 삭제'),
        content: Text('"${group.name}" 분류를 삭제할까요?\n분류가 삭제되면 하위 카테고리는 미분류로 이동됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await HiveService.deleteCategoryGroup(group.id);
      _changed = true;
      setState(() {});
    }
  }

  Future<void> _addCategory(CategoryGroup group) async {
    final nameController = TextEditingController();
    var selectedColorIndex = 0;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${group.name} 카테고리 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '카테고리 이름',
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '색상',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < CategoryColorPalette.colors.length; i++)
                    GestureDetector(
                      onTap: () => setDialogState(() => selectedColorIndex = i),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: CategoryColorPalette.colors[i],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColorIndex == i
                                ? Colors.black87
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, nameController.text),
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );

    if (name != null && name.trim().isNotEmpty) {
      final category = Category(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.trim(),
        type: group.type,
        groupId: group.id,
        colorIndex: selectedColorIndex,
      );
      await HiveService.addCategory(category);
      _changed = true;
      setState(() {});
    }
  }

  Future<void> _deleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제'),
        content: Text('"${category.name}" 카테고리를 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await HiveService.deleteCategory(category.id);
      _changed = true;
      setState(() {});
    }
  }

  Future<void> _editCategoryColor(Category category) async {
    var selectedColorIndex =
        category.colorIndex ?? CategoryColorPalette.fallbackIndex(category.id);
    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('카테고리 색상 변경'),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < CategoryColorPalette.colors.length; i++)
                GestureDetector(
                  onTap: () => setDialogState(() => selectedColorIndex = i),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: CategoryColorPalette.colors[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedColorIndex == i
                            ? Colors.black87
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedColorIndex),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      category.colorIndex = result;
      await HiveService.addCategory(category);
      _changed = true;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('분류/카테고리 관리'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '수입'),
              Tab(text: '지출'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCategoryList(TransactionType.income),
            _buildCategoryList(TransactionType.expense),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addGroup(_currentType),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildCategoryList(TransactionType type) {
    final groups = HiveService.getCategoryGroups(type: type);
    final ungrouped = HiveService.getUngroupedCategories(type: type);

    if (groups.isEmpty && ungrouped.isEmpty) {
      return const Center(
        child: Text(
          '분류가 없습니다',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverReorderableList(
          itemBuilder: (context, index) {
            final group = groups[index];
            return _buildGroupSection(group, type, index);
          },
          itemCount: groups.length,
          onReorder: (oldIndex, newIndex) async {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final updated = [...groups];
            final moved = updated.removeAt(oldIndex);
            updated.insert(newIndex, moved);
            await HiveService.updateGroupOrder(type, updated);
            _changed = true;
            setState(() {});
          },
        ),
        if (ungrouped.isNotEmpty)
          SliverToBoxAdapter(child: _buildUngroupedSection(ungrouped, type)),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildGroupSection(CategoryGroup group, TransactionType type, int index) {
    final categories = HiveService.getCategories(type: type, groupId: group.id);

    return Card(
      key: ValueKey(group.id),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.drag_handle),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addCategory(group),
                  tooltip: '카테고리 추가',
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editGroup(group);
                    } else if (value == 'delete') {
                      _deleteGroup(group);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('이름 수정'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('삭제', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (categories.isEmpty)
              const Text(
                '카테고리가 없습니다',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...categories.map(
                (category) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: CategoryColorPalette.resolve(
                        category.colorIndex ??
                            CategoryColorPalette.fallbackIndex(category.id),
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(category.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.palette_outlined),
                        onPressed: () => _editCategoryColor(category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteCategory(category),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUngroupedSection(List<Category> categories, TransactionType type) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '미분류',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...categories.map(
              (category) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: CategoryColorPalette.resolve(
                      category.colorIndex ??
                          CategoryColorPalette.fallbackIndex(category.id),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(category.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.palette_outlined),
                      onPressed: () => _editCategoryColor(category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteCategory(category),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
