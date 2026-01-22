import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';

/// Deposits management screen - create deposits and link pending cash
class DepositsScreen extends StatefulWidget {
  const DepositsScreen({super.key});

  @override
  State<DepositsScreen> createState() => _DepositsScreenState();
}

class _DepositsScreenState extends State<DepositsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedSource = 'store';
  Uint8List? _imageBytes;
  String? _imageFileName;
  bool _isProcessing = false;

  final _currencyFormat = NumberFormat.currency(symbol: 'Q', decimalDigits: 2);
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _cleanupPendingCash() async {
    try {
      final pendingCashDocs = await _firestore.collection('pendingCash').get();
      final batch = _firestore.batch();
      int cleanedCount = 0;

      for (final doc in pendingCashDocs.docs) {
        final data = doc.data();
        final saleIds = List<String>.from(data['saleIds'] ?? []);
        
        if (saleIds.isEmpty) continue;

        // Check which sales still exist
        final validSaleIds = <String>[];
        double correctTotal = 0.0;

        for (final saleId in saleIds) {
          final saleDoc = await _firestore.collection('sales').doc(saleId).get();
          if (saleDoc.exists) {
            validSaleIds.add(saleId);
            correctTotal += (saleDoc.data()?['total'] as num?)?.toDouble() ?? 0.0;
          }
        }

        // Update if different
        if (validSaleIds.length != saleIds.length) {
          cleanedCount++;
          batch.update(doc.reference, {
            'saleIds': validSaleIds,
            'amount': correctTotal,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (cleanedCount > 0) {
        await batch.commit();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Limpieza completada: $cleanedCount fuente(s) actualizada(s)'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ No se encontraron referencias obsoletas'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al limpiar: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageFileName = image.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _createDeposit() async {
    // Prevent multiple simultaneous calls
    if (_isProcessing) return;

    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el monto del depósito'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un monto válido'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adjunta el comprobante del depósito'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Get pending cash data for this source
      final pendingCashDoc =
          await _firestore.collection('pendingCash').doc(_selectedSource).get();

      if (!pendingCashDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay efectivo pendiente para este origen'),
              backgroundColor: AppTheme.warning,
            ),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      final pendingData = pendingCashDoc.data()!;
      final pendingAmount = (pendingData['amount'] as num?)?.toDouble() ?? 0.0;
      final pendingSaleIds = List<String>.from(pendingData['saleIds'] ?? []);

      List<String> selectedSaleIds;

      // Check if amounts match
      if ((amount - pendingAmount).abs() < 0.01) {
        // Perfect match - link all pending sales automatically
        selectedSaleIds = pendingSaleIds;
      } else {
        // Amounts don't match - show manual selection dialog
        setState(() => _isProcessing = false);

        final result = await _showManualSaleSelectionDialog(
          pendingSaleIds,
          pendingAmount,
          amount,
        );

        if (result == null) {
          // User cancelled
          return;
        }

        selectedSaleIds = result;
        setState(() => _isProcessing = true);

        // Validate: Load selected sales and verify total matches deposit amount
        final selectedSaleDocs = await Future.wait(
          selectedSaleIds
              .map((id) => _firestore.collection('sales').doc(id).get()),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Timeout al cargar ventas seleccionadas');
          },
        );

        double selectedTotal = 0.0;
        final missingSaleIds = <String>[];
        
        for (int i = 0; i < selectedSaleDocs.length; i++) {
          final doc = selectedSaleDocs[i];
          final saleId = selectedSaleIds[i];
          
          if (!doc.exists) {
            missingSaleIds.add(saleId);
            continue;
          }
          
          final data = doc.data()!;
          selectedTotal += (data['total'] as num?)?.toDouble() ?? 0.0;

          // Check if it's a delivery sale and validate it's delivered
          final saleType = data['saleType'] as String?;
          if (saleType == 'delivery') {
            final deliveryStatus =
                data['deliveryStatus'] as String? ?? 'pending';
            if (deliveryStatus != 'delivered' &&
                deliveryStatus != 'completed') {
              setState(() => _isProcessing = false);
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppTheme.white),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: Text(
                          'Error: La venta #${doc.id.substring(0, 8)} aún no ha sido entregada. Marca como entregado antes de registrar el depósito.',
                          style: AppTheme.bodySmall
                              .copyWith(color: AppTheme.white),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppTheme.danger,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 5),
                ),
              );
              return;
            }
          }
        }

        // Check if any sales were deleted
        if (missingSaleIds.isNotEmpty) {
          setState(() => _isProcessing = false);
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppTheme.white),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Text(
                      'Error: ${missingSaleIds.length} venta(s) fueron eliminadas y ya no existen. Actualiza la selección.',
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.danger,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }

        // Check if selected sales total matches deposit amount
        if ((selectedTotal - amount).abs() > 0.01) {
          setState(() => _isProcessing = false);
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppTheme.white),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Text(
                      'Error: Las ventas seleccionadas suman Q${selectedTotal.toStringAsFixed(2)}, pero el depósito es Q${amount.toStringAsFixed(2)}. Los montos deben coincidir.',
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.danger,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }
      }

      // Create deposit document
      final depositRef = _firestore.collection('deposits').doc();
      final depositId = depositRef.id;

      // Upload comprobante image
      final storageRef =
          _storage.ref().child('deposits/$depositId/comprobante.jpg');
      await storageRef.putData(_imageBytes!);
      final imageUrl = await storageRef.getDownloadURL();

      // Fetch all sale documents in parallel first (avoid sequential await in loop)
      final saleDocs = await Future.wait(
        selectedSaleIds
            .map((id) => _firestore.collection('sales').doc(id).get()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout al cargar ventas');
        },
      );

      final batch = _firestore.batch();

      // Create deposit
      batch.set(depositRef, {
        'source': _selectedSource,
        'amount': amount,
        'saleIds': selectedSaleIds,
        'comprobanteUrl': imageUrl,
        'notes': _notesController.text.trim(),
        'depositedBy': user.uid,
        'depositedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update sales with depositId and mark deliveries as completed
      for (final saleDoc in saleDocs) {
        if (saleDoc.exists) {
          final saleData = saleDoc.data()!;
          final updates = <String, dynamic>{
            'depositId': depositId,
          };

          // If delivery and delivered, mark as completed
          if (saleData['saleType'] == 'delivery' &&
              saleData['deliveryStatus'] == 'delivered') {
            updates['deliveryStatus'] = 'completed';
            updates['completedAt'] = FieldValue.serverTimestamp();
          }

          batch.update(saleDoc.reference, updates);
        }
      }

      // Update pending cash: deduct amount and remove linked saleIds
      final remainingSaleIds =
          pendingSaleIds.where((id) => !selectedSaleIds.contains(id)).toList();

      final remainingAmount = pendingAmount - amount;

      if (remainingSaleIds.isEmpty || remainingAmount <= 0.01) {
        // Clear pending cash completely
        batch.delete(_firestore.collection('pendingCash').doc(_selectedSource));
      } else {
        // Update with remaining sales and amount
        batch.update(
          _firestore.collection('pendingCash').doc(_selectedSource),
          {
            'amount': remainingAmount,
            'saleIds': remainingSaleIds,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: AppTheme.white),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'Depósito registrado${selectedSaleIds.length > 1 ? ' (${selectedSaleIds.length} ventas vinculadas)' : ''}',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Clear form
        _amountController.clear();
        _notesController.clear();
        setState(() {
          _imageBytes = null;
          _imageFileName = null;
          _selectedSource = 'store';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear depósito: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<List<String>?> _showManualSaleSelectionDialog(
    List<String> pendingSaleIds,
    double pendingAmount,
    double depositAmount,
  ) async {
    final selectedSaleIds = <String>{};

    return showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Simplified: Don't load full sale data to avoid Firebase SDK bug
        // Just show sale IDs and let user select
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final selectedCount = selectedSaleIds.length;

            return AlertDialog(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Seleccionar Ventas'),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'El monto no coincide. Selecciona las ventas para este depósito.',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.mediumGray,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundGray,
                      borderRadius: AppTheme.borderRadiusSmall,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Depósito:', style: AppTheme.bodyMedium),
                            Text(
                              'Q${depositAmount.toStringAsFixed(2)}',
                              style: AppTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Pendiente:',
                                style: AppTheme.bodyMedium),
                            Text(
                              'Q${pendingAmount.toStringAsFixed(2)}',
                              style: AppTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Seleccionadas:', style: AppTheme.bodyMedium),
                            Text(
                              '$selectedCount de ${pendingSaleIds.length}',
                              style: AppTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: selectedCount > 0
                                    ? AppTheme.blue
                                    : AppTheme.mediumGray,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pendingSaleIds.length,
                  itemBuilder: (context, index) {
                    final saleId = pendingSaleIds[index];
                    final isSelected = selectedSaleIds.contains(saleId);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (selected) {
                        setDialogState(() {
                          if (selected == true) {
                            selectedSaleIds.add(saleId);
                          } else {
                            selectedSaleIds.remove(saleId);
                          }
                        });
                      },
                      title: Text(
                        'Venta #${saleId.substring(0, 8)}',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'ID: $saleId',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: selectedSaleIds.isNotEmpty
                      ? () => Navigator.pop(context, selectedSaleIds.toList())
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.blue,
                    foregroundColor: AppTheme.white,
                  ),
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
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
                const Icon(Icons.account_balance_rounded,
                    size: 32, color: AppTheme.darkGray),
                const SizedBox(width: AppTheme.spacingM),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Depósitos', style: AppTheme.heading2),
                    Text(
                      'Registra depósitos y vincula efectivo pendiente',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.mediumGray),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Create Deposit Form
                  Expanded(
                    flex: 2,
                    child: _buildCreateDepositCard(),
                  ),
                  const SizedBox(width: AppTheme.spacingL),

                  // Right: Pending Cash & Recent Deposits
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildPendingCashCard(),
                        const SizedBox(height: AppTheme.spacingL),
                        _buildRecentDepositsCard(),
                      ],
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

  Widget _buildCreateDepositCard() {
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
              const Icon(Icons.add_circle_outline_rounded,
                  color: AppTheme.blue, size: 24),
              const SizedBox(width: AppTheme.spacingM),
              Text('Registrar Depósito', style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Source selection
          Text('Origen del Efectivo', style: AppTheme.bodyLarge),
          const SizedBox(height: AppTheme.spacingS),
          Row(
            children: [
              _buildSourceButton(
                icon: Icons.store_rounded,
                label: 'Tienda',
                value: 'store',
              ),
              const SizedBox(width: AppTheme.spacingS),
              _buildSourceButton(
                icon: Icons.delivery_dining_rounded,
                label: 'Mensajero',
                value: 'mensajero',
              ),
              const SizedBox(width: AppTheme.spacingS),
              _buildSourceButton(
                icon: Icons.local_shipping_rounded,
                label: 'Forza',
                value: 'forza',
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Amount input
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monto Depositado',
              prefixText: 'Q ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Notes
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notas (opcional)',
              border: OutlineInputBorder(),
              hintText: 'Ej: Banco, No. de boleta, etc.',
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Image picker
          Text('Comprobante', style: AppTheme.bodyLarge),
          const SizedBox(height: AppTheme.spacingS),
          if (_imageBytes == null)
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_photo_alternate_rounded),
              label: const Text('Adjuntar Comprobante'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.lightGray),
                borderRadius: AppTheme.borderRadiusSmall,
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: AppTheme.borderRadiusSmall,
                    child: Image.memory(
                      _imageBytes!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.image_rounded, color: AppTheme.blue),
                    title: Text(_imageFileName ?? 'Comprobante',
                        style: AppTheme.bodySmall),
                    trailing: IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppTheme.danger),
                      onPressed: () {
                        setState(() {
                          _imageBytes = null;
                          _imageFileName = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppTheme.spacingXL),

          // Submit button
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _createDeposit,
            icon: _isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.white,
                    ),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(_isProcessing ? 'Procesando...' : 'Registrar Depósito'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: AppTheme.blue,
              foregroundColor: AppTheme.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCashCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('pendingCash').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final pendingDocs = snapshot.data!.docs;
        final totalPending = pendingDocs.fold<double>(
          0.0,
          (sum, doc) => sum + ((doc.data() as Map)['amount'] ?? 0.0),
        );

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
                  const Icon(Icons.payments_rounded,
                      color: AppTheme.warning, size: 24),
                  const SizedBox(width: AppTheme.spacingM),
                  Text('Efectivo Pendiente', style: AppTheme.heading3),
                  const Spacer(),
                  // Add cleanup button for admins
                  if (totalPending == 0 && pendingDocs.any((doc) => (doc.data() as Map)['saleIds']?.isNotEmpty == true))
                    Tooltip(
                      message: 'Limpiar referencias obsoletas',
                      child: IconButton(
                        icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                        color: AppTheme.mediumGray,
                        onPressed: _cleanupPendingCash,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Total pending
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGray,
                  borderRadius: AppTheme.borderRadiusSmall,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Pendiente',
                        style: AppTheme.bodyLarge
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      _currencyFormat.format(totalPending),
                      style:
                          AppTheme.heading2.copyWith(color: AppTheme.warning),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Breakdown by source
              if (pendingDocs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 48, color: AppTheme.success.withOpacity(0.5)),
                        const SizedBox(height: AppTheme.spacingM),
                        Text(
                          'No hay efectivo pendiente',
                          style: AppTheme.bodyLarge
                              .copyWith(color: AppTheme.mediumGray),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...pendingDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final source = doc.id;
                  final amount = data['amount'] ?? 0.0;
                  final saleIds = List<String>.from(data['saleIds'] ?? []);
                  final updatedAt = data['updatedAt'] as Timestamp?;

                  // Calculate days pending
                  int daysPending = 0;
                  if (updatedAt != null) {
                    final diff = DateTime.now().difference(updatedAt.toDate());
                    daysPending = diff.inDays;
                  }

                  // Color based on days pending
                  Color statusColor = AppTheme.success;
                  if (daysPending > 7) {
                    statusColor = AppTheme.danger;
                  } else if (daysPending > 3) {
                    statusColor = AppTheme.warning;
                  }

                  IconData sourceIcon;
                  String sourceName;
                  switch (source) {
                    case 'store':
                      sourceIcon = Icons.store_rounded;
                      sourceName = 'Tienda';
                      break;
                    case 'mensajero':
                      sourceIcon = Icons.delivery_dining_rounded;
                      sourceName = 'Mensajero';
                      break;
                    case 'forza':
                      sourceIcon = Icons.local_shipping_rounded;
                      sourceName = 'Forza';
                      break;
                    default:
                      sourceIcon = Icons.account_balance_wallet_rounded;
                      sourceName = source;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                        borderRadius: AppTheme.borderRadiusSmall,
                        color: statusColor.withOpacity(0.05),
                      ),
                      child: Row(
                        children: [
                          Icon(sourceIcon, color: statusColor, size: 32),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(sourceName, style: AppTheme.bodyLarge),
                                Text(
                                  '${saleIds.length} venta${saleIds.length != 1 ? 's' : ''}',
                                  style: AppTheme.bodySmall
                                      .copyWith(color: AppTheme.mediumGray),
                                ),
                                if (daysPending > 0)
                                  Text(
                                    '$daysPending día${daysPending != 1 ? 's' : ''} pendiente${daysPending != 1 ? 's' : ''}',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            _currencyFormat.format(amount),
                            style:
                                AppTheme.heading3.copyWith(color: statusColor),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentDepositsCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('deposits')
          .orderBy('depositedAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final deposits = snapshot.data!.docs;

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
                  const Icon(Icons.history_rounded,
                      color: AppTheme.darkGray, size: 24),
                  const SizedBox(width: AppTheme.spacingM),
                  Text('Depósitos Recientes', style: AppTheme.heading3),
                ],
              ),
              const SizedBox(height: AppTheme.spacingL),
              if (deposits.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Text(
                      'No hay depósitos registrados',
                      style: AppTheme.bodyLarge
                          .copyWith(color: AppTheme.mediumGray),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: deposits.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = deposits[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final source = data['source'] ?? '';
                    final amount = data['amount'] ?? 0.0;
                    final saleIds = List<String>.from(data['saleIds'] ?? []);
                    final depositedAt = data['depositedAt'] as Timestamp?;
                    final notes = data['notes'] as String?;
                    final comprobanteUrl = data['comprobanteUrl'] as String?;

                    IconData sourceIcon;
                    String sourceName;
                    switch (source) {
                      case 'store':
                        sourceIcon = Icons.store_rounded;
                        sourceName = 'Tienda';
                        break;
                      case 'mensajero':
                        sourceIcon = Icons.delivery_dining_rounded;
                        sourceName = 'Mensajero';
                        break;
                      case 'forza':
                        sourceIcon = Icons.local_shipping_rounded;
                        sourceName = 'Forza';
                        break;
                      default:
                        sourceIcon = Icons.account_balance_wallet_rounded;
                        sourceName = source;
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM,
                        vertical: AppTheme.spacingS,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.blue.withOpacity(0.1),
                        child: Icon(sourceIcon, color: AppTheme.blue, size: 20),
                      ),
                      title: Row(
                        children: [
                          Text(sourceName, style: AppTheme.bodyLarge),
                          const SizedBox(width: AppTheme.spacingS),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingS,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${saleIds.length} venta${saleIds.length != 1 ? 's' : ''}',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.success,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (depositedAt != null)
                            Text(
                              _dateFormat.format(depositedAt.toDate()),
                              style: AppTheme.bodySmall
                                  .copyWith(color: AppTheme.mediumGray),
                            ),
                          if (notes != null && notes.isNotEmpty)
                            Text(
                              notes,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.mediumGray,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currencyFormat.format(amount),
                                style: AppTheme.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.success,
                                ),
                              ),
                              if (comprobanteUrl != null) ...[
                                const SizedBox(height: 4),
                                TextButton(
                                  onPressed: () =>
                                      _showComprobanteDialog(comprobanteUrl),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingS,
                                      vertical: 2,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    foregroundColor: AppTheme.blue,
                                  ),
                                  child: const Text('Ver',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 20),
                            color: AppTheme.danger,
                            tooltip: 'Eliminar Depósito',
                            onPressed: () =>
                                _confirmDeleteDeposit(doc.id, saleIds),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isSelected = _selectedSource == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSource = value;
          });
        },
        borderRadius: AppTheme.borderRadiusSmall,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.blue : AppTheme.backgroundGray,
            borderRadius: AppTheme.borderRadiusSmall,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppTheme.white : AppTheme.darkGray,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Flexible(
                child: Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(
                    color: isSelected ? AppTheme.white : AppTheme.darkGray,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteDeposit(
      String depositId, List<String> saleIds) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Depósito'),
        content: Text(
          '¿Estás seguro de eliminar este depósito? Esto restaurará el efectivo pendiente para ${saleIds.length} venta${saleIds.length != 1 ? 's' : ''}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: AppTheme.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final depositDoc =
          await _firestore.collection('deposits').doc(depositId).get();
      if (!depositDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Depósito no encontrado'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
        return;
      }

      final depositData = depositDoc.data()!;
      final source = depositData['source'] as String;
      final amount = depositData['amount'] as double;
      final linkedSaleIds = List<String>.from(depositData['saleIds'] ?? []);

      final batch = _firestore.batch();

      // Remove depositId from all linked sales (only if they exist)
      final existingSaleIds = <String>[];
      for (final saleId in linkedSaleIds) {
        final saleRef = _firestore.collection('sales').doc(saleId);
        final saleDoc = await saleRef.get();
        if (saleDoc.exists) {
          batch.update(saleRef, {
            'depositId': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          existingSaleIds.add(saleId);
        }
      }

      // Restore or create pending cash (only for sales that still exist)
      final pendingCashRef = _firestore.collection('pendingCash').doc(source);
      final pendingCashDoc = await pendingCashRef.get();

      if (pendingCashDoc.exists) {
        // Add amount back to existing pending cash
        final existingData = pendingCashDoc.data()!;
        final existingAmount = existingData['amount'] as double;
        final existingPendingSaleIds =
            List<String>.from(existingData['saleIds'] ?? []);

        batch.update(pendingCashRef, {
          'amount': existingAmount + amount,
          'saleIds': [...existingPendingSaleIds, ...existingSaleIds],
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new pending cash entry
        batch.set(pendingCashRef, {
          'source': source,
          'amount': amount,
          'saleIds': existingSaleIds,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Delete the deposit
      batch.delete(depositDoc.reference);

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppTheme.white),
                SizedBox(width: AppTheme.spacingM),
                Expanded(child: Text('Depósito eliminado correctamente')),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );

        // Refresh the screen
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar depósito: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  void _showComprobanteDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: const BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: AppTheme.blue),
                  const SizedBox(width: AppTheme.spacingM),
                  Text('Comprobante de Depósito', style: AppTheme.heading3),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.spacingXXL),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Padding(
                    padding: EdgeInsets.all(AppTheme.spacingXXL),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 48, color: AppTheme.danger),
                        SizedBox(height: AppTheme.spacingM),
                        Text('Error al cargar imagen'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
