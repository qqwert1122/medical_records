import 'package:shared_preferences/shared_preferences.dart';

class PrefService {
  static const String _keyGenderIsMale = 'bodymap_gender_is_male';

  // Singleton pattern
  static final PrefService _instance = PrefService._internal();
  factory PrefService() => _instance;
  PrefService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Gender (true: 남자, false: 여자)
  Future<void> setGenderIsMale(bool isMale) async {
    await init();
    await _prefs!.setBool(_keyGenderIsMale, isMale);
  }

  bool getGenderIsMale() {
    return _prefs?.getBool(_keyGenderIsMale) ?? true; // 기본값: 남자
  }
}
