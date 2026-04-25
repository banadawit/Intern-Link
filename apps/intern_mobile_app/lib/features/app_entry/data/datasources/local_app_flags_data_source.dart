import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/storage_keys.dart';

class LocalAppFlagsDataSource {
  Future<bool> isFirstLaunchCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.firstLaunchCompleted) ?? false;
  }

  Future<void> setFirstLaunchCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.firstLaunchCompleted, value);
  }
}
