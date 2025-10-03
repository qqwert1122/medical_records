import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_records/features/bodymap/screens/mouth_detail_page.dart';
import 'package:medical_records/features/bodymap/screens/head_detail_page.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/services/pref_service.dart';

class BodyMapPage extends StatefulWidget {
  const BodyMapPage({super.key});

  @override
  State<BodyMapPage> createState() => _BodyMapPageState();
}

class _BodyMapPageState extends State<BodyMapPage> {
  final PrefService _prefService = PrefService();
  bool isMale = true;

  @override
  void initState() {
    super.initState();
    _loadGenderPreference();
  }

  Future<void> _loadGenderPreference() async {
    await _prefService.init();
    if (mounted) {
      setState(() {
        isMale = _prefService.getGenderIsMale();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bodyParts = [
      {
        'name': '얼굴',
        'image':
            isMale
                ? 'assets/images/bodymap/face.png'
                : 'assets/images/bodymap/face_woman.png',
        'heroTag': 'body_part_face',
        'page': HeadDetailPage(initialIsMale: isMale),
      },
      {
        'name': '입',
        'image': 'assets/images/bodymap/mouth.png',
        'heroTag': 'body_part_mouth',
        'page': const MouthDetailPage(),
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          '바디맵',
          style: AppTextStyle.title.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: bodyParts.length,
          itemBuilder: (context, index) {
            final part = bodyParts[index];
            return GestureDetector(
              onTap: () async {
                HapticFeedback.mediumImpact();
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => part['page'] as Widget,
                  ),
                );
                // 돌아왔을 때 성별 다시 로드
                _loadGenderPreference();
              },
              child: Card(
                elevation: 1,
                color: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        part['name'] as String,
                        style: AppTextStyle.title.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: Hero(
                          tag: part['heroTag'] as String,
                          child: Image.asset(
                            part['image'] as String,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
