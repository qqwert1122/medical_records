import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('설정', style: AppTextStyle.title), backgroundColor: AppColors.background),
      body: Container(
        decoration: BoxDecoration(color: AppColors.background),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('메인 컬러', style: AppTextStyle.subTitle),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      title: const Text('빨강'),
                      trailing: Container(width: 30, height: 30, color: Colors.red),
                      onTap: () {
                        setState(() {
                          AppColors.changeTheme(Colors.red, Colors.redAccent);
                        });
                      },
                    ),
                    ListTile(
                      title: const Text('파랑'),
                      trailing: Container(width: 30, height: 30, color: Colors.blue),
                      onTap: () {
                        setState(() {
                          AppColors.changeTheme(Colors.blue, Colors.blueAccent);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
