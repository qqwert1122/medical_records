import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/calendar/screens/calendar_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:medical_records/records/screens/setting_page.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';

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
    return MaterialApp(title: '건강 로그', home: MainNavigation());
  }
}

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // Bottom Navigation Bar
  int selectedIndex = 0;
  late PageController pageController;
  bool isMonthlyView = true; // Monthly Calendar || Yearly Calendar
  bool _showNavBar =
      true; // Calendar Page의 Bottom Sheet hegiht에 따라 Nav Bar show

  // Bottom navigation bar circle animation
  double _circleWidth = 30;
  double _circleHeight = 30;

  List<Widget> get pages => [
    CalendarPage(
      isMonthlyView: isMonthlyView,
      onBottomSheetHeightChanged: (height) {
        setState(() {
          _showNavBar = height == 0;
        });
      },
    ),
    SearchPage(),
    AnalyticsPage(),
    SettingPage(),
  ];

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void _animateCircle(int index) {
    setState(() {
      // 애니메이션 상태 변경
      _circleWidth = 30;
      _circleHeight = 2;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      setState(() {
        _circleWidth = 30;
        _circleHeight = 30;
        selectedIndex = index;
      });
    });
  }

  void onNavTap(int index) {
    HapticFeedback.lightImpact();

    // 캘린더 아이콘 클릭 시
    if (index == 0 && selectedIndex == 0) {
      setState(() {
        isMonthlyView = !isMonthlyView;
      });
      return;
    }

    // 다른 탭에서 캘린더 탭으로 돌아올 때는 월간 뷰로 초기화
    if (index == 0 && selectedIndex != 0) {
      setState(() {
        isMonthlyView = true;
      });
    }

    _animateCircle(index);
    setState(() => selectedIndex = index);
    pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = selectedIndex == index;
    if (index == 0) {
      return Expanded(
        child: GestureDetector(
          onTap: () => onNavTap(index),
          child: Container(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 연간 캘린더 아이콘
                AnimatedScale(
                  duration: Duration(milliseconds: 300),
                  scale: isMonthlyView ? 0.0 : 1.0,
                  child: AnimatedRotation(
                    duration: Duration(milliseconds: 300),
                    turns: isMonthlyView ? 0.25 : 0.0,
                    child: Icon(
                      Icons.calendar_month, // 연간 뷰 아이콘
                      size: 20,
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
                // 월간 캘린더 아이콘
                AnimatedScale(
                  duration: Duration(milliseconds: 300),
                  scale: isMonthlyView ? 1.0 : 0.0,
                  child: AnimatedRotation(
                    duration: Duration(milliseconds: 300),
                    turns: isMonthlyView ? 0.0 : -0.25,
                    child: Icon(
                      Icons.calendar_today, // 월간 뷰 아이콘
                      size: 20,
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
                if (index == 0 && isSelected) ...[
                  Positioned(
                    bottom: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          width: isMonthlyView ? 10 : 5,
                          height: 4,
                          decoration: BoxDecoration(
                            color:
                                isMonthlyView
                                    ? Colors.redAccent
                                    : Colors.redAccent.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        SizedBox(width: 2),
                        AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: isMonthlyView ? 5 : 10,
                          height: 4,
                          decoration: BoxDecoration(
                            color:
                                isMonthlyView
                                    ? Colors.redAccent.withValues(alpha: 0.4)
                                    : Colors.redAccent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // 다른 아이콘들은 기존 방식대로
    return Expanded(
      child: GestureDetector(
        onTap: () => onNavTap(index),
        child: Container(
          height: 48,
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: pageController,
            physics: NeverScrollableScrollPhysics(), // 스와이프 비활성화
            children: pages,
          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _showNavBar ? 16 : -64,
            left: context.wp(20),
            right: context.wp(20),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 배경 원 애니메이션
                  AnimatedPositioned(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    top: (48 - _circleHeight) / 2,
                    left: context.wp(60) / 4 * selectedIndex + 15,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: _circleWidth,
                      height: _circleHeight,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                  // 아이콘들
                  Row(
                    children: [
                      _buildNavItem(LucideIcons.calendar, 0),
                      _buildNavItem(LucideIcons.image, 1),
                      _buildNavItem(LucideIcons.lineChart, 2),
                      _buildNavItem(LucideIcons.settings, 3),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 임시 페이지들
class SearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('검색'), backgroundColor: AppColors.background),
      body: Center(child: Text('검색 페이지')),
    );
  }
}

class AnalyticsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('분석'), backgroundColor: AppColors.background),
      body: Center(child: Text('분석 페이지')),
    );
  }
}
