import 'package:flutter/material.dart';
import 'package:medical_records/screens/add_page.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 기록', style: AppTextStyle.title), backgroundColor: AppColors.surface),
      body: Container(
        decoration: BoxDecoration(color: AppColors.surface),
        child: ListView.builder(
          itemCount: 10, // 임시 데이터
          itemBuilder: (context, index) {
            return ListTile(
              title: Text('기록 ${index + 1}', style: AppTextStyle.subTitle),
              subtitle: Text('2024-${(index % 12 + 1).toString().padLeft(2, '0')}-01', style: AppTextStyle.body),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,

        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPage()));
        },
        child: Icon(Icons.add, size: AppSize.xl),
        tooltip: '기록 추가',
      ),
    );
  }
}
