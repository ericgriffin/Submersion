import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/gear_repository_impl.dart';
import '../../domain/entities/gear_item.dart';

/// Repository provider
final gearRepositoryProvider = Provider<GearRepository>((ref) {
  return GearRepository();
});

/// Active gear provider
final activeGearProvider = FutureProvider<List<GearItem>>((ref) async {
  final repository = ref.watch(gearRepositoryProvider);
  return repository.getActiveGear();
});

/// Retired gear provider
final retiredGearProvider = FutureProvider<List<GearItem>>((ref) async {
  final repository = ref.watch(gearRepositoryProvider);
  return repository.getRetiredGear();
});

/// All gear provider
final allGearProvider = FutureProvider<List<GearItem>>((ref) async {
  final repository = ref.watch(gearRepositoryProvider);
  return repository.getAllGear();
});

/// Single gear item provider
final gearItemProvider = FutureProvider.family<GearItem?, String>((ref, id) async {
  final repository = ref.watch(gearRepositoryProvider);
  return repository.getGearById(id);
});

/// Gear with service due provider
final serviceDueGearProvider = FutureProvider<List<GearItem>>((ref) async {
  final repository = ref.watch(gearRepositoryProvider);
  return repository.getGearWithServiceDue();
});

/// Gear list notifier for mutations
class GearListNotifier extends StateNotifier<AsyncValue<List<GearItem>>> {
  final GearRepository _repository;
  final Ref _ref;

  GearListNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    _loadGear();
  }

  Future<void> _loadGear() async {
    state = const AsyncValue.loading();
    try {
      final gear = await _repository.getActiveGear();
      state = AsyncValue.data(gear);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await _loadGear();
    _ref.invalidate(retiredGearProvider);
    _ref.invalidate(serviceDueGearProvider);
  }

  Future<GearItem> addGear(GearItem gear) async {
    final newGear = await _repository.createGear(gear);
    await refresh();
    return newGear;
  }

  Future<void> updateGear(GearItem gear) async {
    await _repository.updateGear(gear);
    await refresh();
  }

  Future<void> deleteGear(String id) async {
    await _repository.deleteGear(id);
    await refresh();
  }

  Future<void> markAsServiced(String id) async {
    await _repository.markAsServiced(id);
    await refresh();
  }

  Future<void> retireGear(String id) async {
    await _repository.retireGear(id);
    await refresh();
  }

  Future<void> reactivateGear(String id) async {
    await _repository.reactivateGear(id);
    await refresh();
  }
}

final gearListNotifierProvider =
    StateNotifierProvider<GearListNotifier, AsyncValue<List<GearItem>>>((ref) {
  final repository = ref.watch(gearRepositoryProvider);
  return GearListNotifier(repository, ref);
});
