abstract class KVStorage {
  T? read<T>(String key);
  Future<void> write(String key, dynamic value);
  bool hasData(String key);
  Future<void> remove(String key);
  Future<void> clear();
  
  /// Returns all keys in the storage.
  /// This is used for migration.
  Iterable<String> get keys;
}
