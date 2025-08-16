import 'package:flutter/material.dart';
import 'package:medical_records/calendar/screens/calendar_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:medical_records/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  await DatabaseService().ensureSeeded();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: '건강 로그', home: CalendarPage());
  }
}
