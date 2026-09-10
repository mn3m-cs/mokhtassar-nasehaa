import 'package:alazkar/src/core/constants/const.dart';
import 'package:alazkar/src/core/storage/kv_storage.dart';
import 'package:alazkar/src/core/utils/app_print.dart';
import 'package:get_storage/get_storage.dart';

class StorageMigrationService {
  final KVStorage hiveStorage;

  StorageMigrationService(this.hiveStorage);

  static const String _migrationCompletedKey =
      'migration_completed_from_get_storage';

  Future<void> migrate() async {
    if (hiveStorage.read<bool>(_migrationCompletedKey) == true) {
      appPrint("Storage migration already completed.");
      return;
    }

    appPrint("Starting storage migration from GetStorage to Hive...");

    try {
      // Initialize GetStorage one last time
      await GetStorage.init(kGetStorageName);
      final getStorage = GetStorage(kGetStorageName);

      final dynamic rawKeys = getStorage.getKeys();
      final List<String> keys = (rawKeys as Iterable).cast<String>().toList();

      if (keys.isEmpty) {
        appPrint("No data found in GetStorage to migrate.");
      } else {
        appPrint("Migrating ${keys.length} keys...");
        for (final String key in keys) {
          final dynamic value = getStorage.read(key);
          await hiveStorage.write(key, value);
          appPrint("Migrated key: $key");
        }
      }

      // Mark migration as completed
      await hiveStorage.write(_migrationCompletedKey, true);
      appPrint("Storage migration completed successfully.");
    } catch (e) {
      appPrint("Error during storage migration: $e");
      // We don't mark as completed so we can try again next time if it failed
    }
  }
}
