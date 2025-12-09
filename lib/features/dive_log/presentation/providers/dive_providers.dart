import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/dive_repository_impl.dart';
import '../../domain/entities/dive.dart' as domain;

/// Repository provider
final diveRepositoryProvider = Provider<DiveRepository>((ref) {
  return DiveRepository();
});

/// All dives list provider
final divesProvider = FutureProvider<List<domain.Dive>>((ref) async {
  final repository = ref.watch(diveRepositoryProvider);
  return repository.getAllDives();
});

/// Single dive provider
final diveProvider = FutureProvider.family<domain.Dive?, String>((ref, id) async {
  final repository = ref.watch(diveRepositoryProvider);
  return repository.getDiveById(id);
});

/// Statistics provider
final diveStatisticsProvider = FutureProvider<DiveStatistics>((ref) async {
  final repository = ref.watch(diveRepositoryProvider);
  return repository.getStatistics();
});

/// Next dive number provider
final nextDiveNumberProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(diveRepositoryProvider);
  return repository.getNextDiveNumber();
});

/// Search results provider
final diveSearchProvider = FutureProvider.family<List<domain.Dive>, String>((ref, query) async {
  if (query.isEmpty) {
    return ref.watch(divesProvider).value ?? [];
  }
  final repository = ref.watch(diveRepositoryProvider);
  return repository.searchDives(query);
});

/// Dive list notifier for mutations
class DiveListNotifier extends StateNotifier<AsyncValue<List<domain.Dive>>> {
  final DiveRepository _repository;
  final Ref _ref;

  DiveListNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    _loadDives();
  }

  Future<void> _loadDives() async {
    state = const AsyncValue.loading();
    try {
      final dives = await _repository.getAllDives();
      state = AsyncValue.data(dives);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await _loadDives();
  }

  Future<domain.Dive> addDive(domain.Dive dive) async {
    final newDive = await _repository.createDive(dive);
    await _loadDives();
    _ref.invalidate(diveStatisticsProvider);
    return newDive;
  }

  Future<void> updateDive(domain.Dive dive) async {
    await _repository.updateDive(dive);
    await _loadDives();
    _ref.invalidate(diveStatisticsProvider);
  }

  Future<void> deleteDive(String id) async {
    await _repository.deleteDive(id);
    await _loadDives();
    _ref.invalidate(diveStatisticsProvider);
  }
}

final diveListNotifierProvider =
    StateNotifierProvider<DiveListNotifier, AsyncValue<List<domain.Dive>>>((ref) {
  final repository = ref.watch(diveRepositoryProvider);
  return DiveListNotifier(repository, ref);
});
