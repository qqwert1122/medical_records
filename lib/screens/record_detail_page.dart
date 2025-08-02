import 'package:flutter/material.dart';

class RecordDetailPage extends StatefulWidget {
  const RecordDetailPage({super.key});

  @override
  State<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends State<RecordDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('기록')),
      body: Column(
        children: [
          // 사진
          Container(height: 200, width: double.infinity, color: Colors.grey[300], child: const Icon(Icons.photo, size: 50)),
          // 사진목록
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(width: 80, margin: const EdgeInsets.all(4), color: Colors.grey[300], child: const Icon(Icons.photo));
              },
            ),
          ),
          // 뱃지
          Chip(label: Text('뱃지')),
          // 날짜
          Text('2025-08-01'),
          // 메모
          Expanded(child: Container(width: double.infinity, padding: const EdgeInsets.all(16), child: const Text('메모 내용'))),
        ],
      ),
    );
  }
}
