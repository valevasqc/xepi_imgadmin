import 'package:flutter/material.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/services/expenses_service.dart';

class ExpenseCategoriesScreen extends StatefulWidget {
  const ExpenseCategoriesScreen({super.key});

  @override
  State<ExpenseCategoriesScreen> createState() =>
      _ExpenseCategoriesScreenState();
}

class _ExpenseCategoriesScreenState extends State<ExpenseCategoriesScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  final TextEditingController _nameController = TextEditingController();
  String _type = 'operativo';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final items = await ExpensesService.fetchCategories();
      setState(() {
        _categories = items;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.white),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                  child: Text('Error cargando categorías: $e',
                      style:
                          AppTheme.bodySmall.copyWith(color: AppTheme.white))),
            ],
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              color: AppTheme.white,
              boxShadow: AppTheme.subtleShadow,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: AppTheme.spacingM),
                const Icon(Icons.category_rounded,
                    color: AppTheme.blue, size: 32),
                const SizedBox(width: AppTheme.spacingM),
                Text('Categorías de Gastos', style: AppTheme.heading1),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _showAddCategoryDialog,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Agregar Categoría'),
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.blue),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacingXL),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: AppTheme.borderRadiusMedium,
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Nombre',
                                    style: AppTheme.bodySmall
                                        .copyWith(color: AppTheme.mediumGray)),
                              ),
                              SizedBox(
                                  width: 120,
                                  child: Text('Tipo',
                                      style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.mediumGray))),
                              const SizedBox(width: AppTheme.spacingM),
                              const SizedBox(width: 80),
                            ],
                          ),
                          const Divider(height: AppTheme.spacingXL),
                          ..._categories.map((cat) => _buildRow(cat)),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> cat) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      child: Row(
        children: [
          Expanded(
              child: Text(cat['name'] as String, style: AppTheme.bodyMedium)),
          SizedBox(
            width: 120,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingS, vertical: 4),
              decoration: BoxDecoration(
                color: (cat['type'] == 'operativo'
                        ? AppTheme.blue
                        : AppTheme.orange)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                cat['type'] == 'operativo' ? 'Operativo' : 'No Operativo',
                textAlign: TextAlign.center,
                style: AppTheme.caption.copyWith(
                  color: cat['type'] == 'operativo'
                      ? AppTheme.blue
                      : AppTheme.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          SizedBox(
            width: 80,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  onPressed: () => _showEditCategoryDialog(cat),
                ),
                IconButton(
                  tooltip: 'Eliminar',
                  icon: const Icon(Icons.delete_rounded,
                      size: 18, color: AppTheme.danger),
                  onPressed: () => _deleteCategory(cat),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    _nameController.clear();
    _type = 'operativo';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Categoría'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: AppTheme.spacingM),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(
                      value: 'operativo', child: Text('Operativo')),
                  DropdownMenuItem(
                      value: 'no_operativo', child: Text('No Operativo')),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'operativo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (_nameController.text.trim().isNotEmpty) {
                await ExpensesService.addCategory(
                    _nameController.text.trim(), _type);
                await _loadCategories();
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(Map<String, dynamic> cat) {
    _nameController.text = cat['name'] as String;
    _type = cat['type'] as String;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Categoría'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: AppTheme.spacingM),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(
                      value: 'operativo', child: Text('Operativo')),
                  DropdownMenuItem(
                      value: 'no_operativo', child: Text('No Operativo')),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'operativo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              await ExpensesService.updateCategory(cat['id'] as String,
                  name: _nameController.text.trim(), type: _type);
              await _loadCategories();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(Map<String, dynamic> cat) async {
    await ExpensesService.deleteCategory(cat['id'] as String);
    await _loadCategories();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppTheme.white),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Text('Categoría eliminada',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.white)),
            ),
          ],
        ),
        backgroundColor: AppTheme.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
