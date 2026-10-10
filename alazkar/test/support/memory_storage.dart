import 'package:alazkar/src/core/storage/kv_storage.dart';

class MemoryStorage implements KVStorage {
  final Map<String, dynamic> _data = {};

  @override
  T? read<T>(String key) => _data[key] as T?;

  @override
  Future<void> write(String key, dynamic value) async => _data[key] = value;

  @override
  bool hasData(String key) => _data.containsKey(key);

  @override
  Future<void> remove(String key) async => _data.remove(key);

  @override
  Future<void> clear() async => _data.clear();

  @override
  Iterable<String> get keys => _data.keys;
}
