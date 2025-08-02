import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_text_style.dart';

class Record extends StatefulWidget {
  final Map<String, dynamic> recordData;

  const Record({super.key, required this.recordData});

  @override
  State<Record> createState() => _RecordState();
}

class _RecordState extends State<Record> {
  @override
  Widget build(BuildContext context) {
    final record = widget.recordData;
    final createdAt = DateTime.parse(record['created_at']);
    final formattedDate =
        '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';

    return ListTile(
      title: Text(
        record['category_name'] ?? '기록',
        style: AppTextStyle.subTitle,
      ),
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
      onTap: () {},
    );
  }
}
