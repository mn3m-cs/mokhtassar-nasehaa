import 'package:alazkar/src/core/storage/kv_storage.dart';
import 'package:hive_ce/hive.dart';

class HiveKVStorage implements KVStorage {
  final Box _box;

  HiveKVStorage(this._box);

  @override
  T? read<T>(String key) {
    return _box.get(key) as T?;
  }

  @override
  Future<void> write(String key, dynamic value) async {
    await _box.put(key, value);
  }

  @override
  bool hasData(String key) {
    return _box.containsKey(key);
  }

  @override
  Future<void> remove(String key) async {
    await _box.delete(key);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }

  @override
  Iterable<String> get keys => _box.keys.cast<String>();
}
