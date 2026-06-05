import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/services/bank_accounts_service.dart';
import 'package:intl/intl.dart';

class BankAccountsScreen extends StatefulWidget {
  const BankAccountsScreen({super.key});

  @override
  State<BankAccountsScreen> createState() => _BankAccountsScreenState();
}

class _BankAccountsScreenState extends State<BankAccountsScreen> {
  final BankAccountsService _service = BankAccountsService();

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
                Text('Cuentas Bancarias', style: AppTheme.heading1),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Agregar Cuenta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.blue,
                    foregroundColor: AppTheme.white,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.getBankAccountsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final accounts = snapshot.data ?? [];

                if (accounts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.account_balance_rounded,
                          size: 64,
                          color: AppTheme.mediumGray,
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        Text('No hay cuentas bancarias',
                            style: AppTheme.heading3),
                        const SizedBox(height: AppTheme.spacingS),
                        Text('Agrega tu primera cuenta bancaria',
                            style: AppTheme.bodyMedium
                                .copyWith(color: AppTheme.mediumGray)),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingXL),
                  child: Column(
                    children: [
                      _buildSummaryCards(accounts),
                      const SizedBox(height: AppTheme.spacingL),
                      _buildAccountsList(accounts),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<Map<String, dynamic>> accounts) {
    double totalQTZ = 0;
    double totalUSD = 0;

    for (var account in accounts) {
      if (account['isActive'] != true) continue;
      final balance = (account['currentBalance'] as num?)?.toDouble() ?? 0;
      final currency = account['currency'] as String?;
      if (currency == 'QTZ') {
        totalQTZ += balance;
      } else if (currency == 'USD') {
        totalUSD += balance;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Quetzales',
            'Q${NumberFormat('#,##0.00').format(totalQTZ)}',
            AppTheme.blue,
            Icons.attach_money_rounded,
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: _buildSummaryCard(
            'Total Dólares',
            '\$${NumberFormat('#,##0.00').format(totalUSD)}',
            AppTheme.success,
            Icons.attach_money_rounded,
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: _buildSummaryCard(
            'Cuentas Activas',
            '${accounts.where((a) => a['isActive'] == true).length}',
            AppTheme.orange,
            Icons.account_balance_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String label, String value, Color color, IconData icon) {
    return Container(
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
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: AppTheme.borderRadiusSmall,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(label,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray)),
          const SizedBox(height: AppTheme.spacingS),
          Text(value, style: AppTheme.heading2.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildAccountsList(List<Map<String, dynamic>> accounts) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: accounts.asMap().entries.map((entry) {
          final index = entry.key;
          final account = entry.value;
          final isLast = index == accounts.length - 1;

          return Column(
            children: [
              _buildAccountCard(account),
              if (!isLast)
                const Divider(height: 1, color: AppTheme.lightGray),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account) {
    final accountName = account['accountName'] as String? ?? 'Sin nombre';
    final bankName = account['bankName'] as String? ?? '';
    final accountType = account['accountType'] as String? ?? 'personal';
    final currency = account['currency'] as String? ?? 'QTZ';
    final last4 = account['last4Digits'] as String? ?? '****';
    final balance = (account['currentBalance'] as num?)?.toDouble() ?? 0;
    final isActive = account['isActive'] as bool? ?? true;
    final notes = account['notes'] as String? ?? '';

    return InkWell(
      onTap: () => _showAddEditDialog(context, account: account),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.blue.withValues(alpha: 0.1)
                    : AppTheme.mediumGray.withValues(alpha: 0.1),
                borderRadius: AppTheme.borderRadiusSmall,
              ),
              child: Icon(
                accountType == 'business'
                    ? Icons.business_rounded
                    : Icons.person_rounded,
                color: isActive ? AppTheme.blue : AppTheme.mediumGray,
                size: 28,
              ),
            ),
            const SizedBox(width: AppTheme.spacingL),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        accountName,
                        style: AppTheme.bodyLarge
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      if (!isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingS,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.mediumGray.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Inactiva',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.mediumGray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    '$bankName • **** $last4 • ${accountType == 'business' ? 'Negocio' : 'Personal'}',
                    style:
                        AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      notes,
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.mediumGray),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currency == 'USD'
                      ? '\$${NumberFormat('#,##0.00').format(balance)}'
                      : 'Q${NumberFormat('#,##0.00').format(balance)}',
                  style: AppTheme.heading3.copyWith(
                    color: isActive ? AppTheme.blue : AppTheme.mediumGray,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  currency,
                  style:
                      AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
                ),
              ],
            ),
            const SizedBox(width: AppTheme.spacingL),

            // Actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) async {
                if (value == 'edit') {
                  _showAddEditDialog(context, account: account);
                } else if (value == 'update_balance') {
                  _showUpdateBalanceDialog(context, account);
                } else if (value == 'toggle') {
                  await _service.updateBankAccount(
                    account['id'],
                    isActive: !isActive,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isActive
                            ? 'Cuenta desactivada'
                            : 'Cuenta activada'),
                      ),
                    );
                  }
                } else if (value == 'delete') {
                  _showDeleteConfirmation(context, account);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded),
                      SizedBox(width: AppTheme.spacingM),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'update_balance',
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded),
                      SizedBox(width: AppTheme.spacingM),
                      Text('Actualizar Saldo'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(isActive
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded),
                      const SizedBox(width: AppTheme.spacingM),
                      Text(isActive ? 'Desactivar' : 'Activar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded, color: AppTheme.danger),
                      SizedBox(width: AppTheme.spacingM),
                      Text('Eliminar', style: TextStyle(color: AppTheme.danger)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context,
      {Map<String, dynamic>? account}) {
    final isEditing = account != null;
    final formKey = GlobalKey<FormState>();

    final nameController =
        TextEditingController(text: account?['accountName'] ?? '');
    final bankController =
        TextEditingController(text: account?['bankName'] ?? '');
    final last4Controller =
        TextEditingController(text: account?['last4Digits'] ?? '');
    final balanceController = TextEditingController(
        text: account?['currentBalance']?.toStringAsFixed(2) ?? '0.00');
    final notesController =
        TextEditingController(text: account?['notes'] ?? '');

    String accountType = account?['accountType'] ?? 'personal';
    String currency = account?['currency'] ?? 'QTZ';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Editar Cuenta' : 'Agregar Cuenta'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la Cuenta *',
                        hintText: 'Ej: BI Cuenta Corriente',
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    TextFormField(
                      controller: bankController,
                      decoration: const InputDecoration(
                        labelText: 'Banco *',
                        hintText: 'Ej: Banco Industrial',
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: accountType,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Cuenta *',
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'personal', child: Text('Personal')),
                              DropdownMenuItem(
                                  value: 'business', child: Text('Negocio')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => accountType = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: currency,
                            decoration: const InputDecoration(
                              labelText: 'Moneda *',
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'QTZ', child: Text('Quetzales (Q)')),
                              DropdownMenuItem(
                                  value: 'USD', child: Text('Dólares (\$)')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => currency = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    TextFormField(
                      controller: last4Controller,
                      decoration: const InputDecoration(
                        labelText: 'Últimos 4 Dígitos *',
                        hintText: '1234',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Campo requerido';
                        if (value!.length != 4) return 'Debe tener 4 dígitos';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    TextFormField(
                      controller: balanceController,
                      decoration: InputDecoration(
                        labelText: isEditing
                            ? 'Saldo Actual *'
                            : 'Saldo Inicial *',
                        prefixText: currency == 'USD' ? '\$ ' : 'Q ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notas (opcional)',
                        hintText: 'Ej: Para recibir pagos de clientes',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                try {
                  if (isEditing) {
                    await _service.updateBankAccount(
                      account['id'],
                      accountName: nameController.text.trim(),
                      bankName: bankController.text.trim(),
                      accountType: accountType,
                      currency: currency,
                      last4Digits: last4Controller.text.trim(),
                      currentBalance: double.parse(balanceController.text),
                      notes: notesController.text.trim(),
                    );
                  } else {
                    await _service.addBankAccount(
                      accountName: nameController.text.trim(),
                      bankName: bankController.text.trim(),
                      accountType: accountType,
                      currency: currency,
                      last4Digits: last4Controller.text.trim(),
                      initialBalance: double.parse(balanceController.text),
                      notes: notesController.text.trim(),
                    );
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEditing
                            ? 'Cuenta actualizada'
                            : 'Cuenta agregada'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppTheme.danger,
                      ),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Guardar' : 'Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateBalanceDialog(
      BuildContext context, Map<String, dynamic> account) {
    final balanceController = TextEditingController(
        text: account['currentBalance']?.toStringAsFixed(2) ?? '0.00');
    final formKey = GlobalKey<FormState>();
    final currency = account['currency'] as String? ?? 'QTZ';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Actualizar Saldo'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                account['accountName'] ?? 'Sin nombre',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppTheme.spacingL),
              TextFormField(
                controller: balanceController,
                decoration: InputDecoration(
                  labelText: 'Nuevo Saldo *',
                  prefixText: currency == 'USD' ? '\$ ' : 'Q ',
                  hintText: 'Ingresa el saldo actual del banco',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Campo requerido' : null,
                autofocus: true,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'Ingresa el saldo actual según tu estado de cuenta bancario',
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              try {
                await _service.updateBalance(
                  account['id'],
                  double.parse(balanceController.text),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saldo actualizado')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, Map<String, dynamic> account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cuenta'),
        content: Text(
          '¿Estás segura de eliminar "${account['accountName']}"?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _service.deleteBankAccount(account['id']);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cuenta eliminada')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: AppTheme.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
