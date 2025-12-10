import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/equipment_repository_impl.dart';
import '../../domain/entities/equipment_item.dart';

/// Repository provider
final equipmentRepositoryProvider = Provider<EquipmentRepository>((ref) {
  return EquipmentRepository();
});

/// Active equipment provider
final activeEquipmentProvider = FutureProvider<List<EquipmentItem>>((ref) async {
  final repository = ref.watch(equipmentRepositoryProvider);
  return repository.getActiveEquipment();
});

/// Retired equipment provider
final retiredEquipmentProvider = FutureProvider<List<EquipmentItem>>((ref) async {
  final repository = ref.watch(equipmentRepositoryProvider);
  return repository.getRetiredEquipment();
});

/// All equipment provider
final allEquipmentProvider = FutureProvider<List<EquipmentItem>>((ref) async {
  final repository = ref.watch(equipmentRepositoryProvider);
  return repository.getAllEquipment();
});

/// Single equipment item provider
final equipmentItemProvider = FutureProvider.family<EquipmentItem?, String>((ref, id) async {
  final repository = ref.watch(equipmentRepositoryProvider);
  return repository.getEquipmentById(id);
});

/// Equipment with service due provider
final serviceDueEquipmentProvider = FutureProvider<List<EquipmentItem>>((ref) async {
  final repository = ref.watch(equipmentRepositoryProvider);
  return repository.getEquipmentWithServiceDue();
});

/// Equipment search provider
final equipmentSearchProvider = FutureProvider.family<List<EquipmentItem>, String>((ref, query) async {
  if (query.isEmpty) {
    return ref.watch(allEquipmentProvider).value ?? [];
  }
  final repository = ref.watch(equipmentRepositoryProvider);
  return repository.searchEquipment(query);
});

/// Equipment list notifier for mutations
class EquipmentListNotifier extends StateNotifier<AsyncValue<List<EquipmentItem>>> {
  final EquipmentRepository _repository;
  final Ref _ref;

  EquipmentListNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    _loadEquipment();
  }

  Future<void> _loadEquipment() async {
    state = const AsyncValue.loading();
    try {
      final equipment = await _repository.getActiveEquipment();
      state = AsyncValue.data(equipment);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await _loadEquipment();
    _ref.invalidate(retiredEquipmentProvider);
    _ref.invalidate(serviceDueEquipmentProvider);
  }

  Future<EquipmentItem> addEquipment(EquipmentItem equipment) async {
    final newEquipment = await _repository.createEquipment(equipment);
    await refresh();
    return newEquipment;
  }

  Future<void> updateEquipment(EquipmentItem equipment) async {
    await _repository.updateEquipment(equipment);
    await refresh();
  }

  Future<void> deleteEquipment(String id) async {
    await _repository.deleteEquipment(id);
    await refresh();
  }

  Future<void> markAsServiced(String id) async {
    await _repository.markAsServiced(id);
    await refresh();
  }

  Future<void> retireEquipment(String id) async {
    await _repository.retireEquipment(id);
    await refresh();
  }

  Future<void> reactivateEquipment(String id) async {
    await _repository.reactivateEquipment(id);
    await refresh();
  }
}

final equipmentListNotifierProvider =
    StateNotifierProvider<EquipmentListNotifier, AsyncValue<List<EquipmentItem>>>((ref) {
  final repository = ref.watch(equipmentRepositoryProvider);
  return EquipmentListNotifier(repository, ref);
});
