import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_text_style.dart';

class Record extends StatefulWidget {
  const Record({super.key});

  @override
  State<Record> createState() => _RecordState();
}

class _RecordState extends State<Record> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('기록', style: AppTextStyle.subTitle),
      subtitle: Text('2025-08-01', style: AppTextStyle.body),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {},
    );
  }
}
