import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_records/screens/record_foam_page.dart';
import 'package:medical_records/styles/app_text_style.dart';

class Record extends StatefulWidget {
  final Map<String, dynamic> recordData;
  final VoidCallback? onRecordUpdated;

  const Record({super.key, required this.recordData, this.onRecordUpdated});

  @override
  State<Record> createState() => _RecordState();
}

class _RecordState extends State<Record> {
  @override
  Widget build(BuildContext context) {
    final record = widget.recordData;
    final date = DateTime.parse(record['date']);
    final formattedDate =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return ListTile(
      title: Text(record['spot_name'] ?? '기록', style: AppTextStyle.subTitle),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(formattedDate, style: AppTextStyle.body),
          if (record['memo'] != null && record['memo'].isNotEmpty)
            Text(
              record['memo'],
              style: AppTextStyle.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecordFoamPage(recordData: record),
          ),
        );
        widget.onRecordUpdated?.call();
      },
    );
  }
}
