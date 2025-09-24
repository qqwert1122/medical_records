import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/features/analysis/screens/analysis_page.dart';
import 'package:medical_records/features/calendar/screens/calendar_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:medical_records/features/images/screens/images_page.dart';
import 'package:medical_records/features/settings/screens/setting_page.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/features/security/components/security_lock_overlay.dart';
import 'package:medical_records/features/security/services/security_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  await DatabaseService().ensureSeeded();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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

class _MainNavigationState extends State<MainNavigation>
    with WidgetsBindingObserver {
  // Bottom Navigation Bar
  int selectedIndex = 0;
  late PageController pageController;
  bool isMonthlyView = true; // Monthly Calendar || Yearly Calendar
  bool _showNavBar =
      true; // Calendar Page의 Bottom Sheet hegiht에 따라 Nav Bar show

  // Bottom navigation bar circle animation
  double _circleWidth = 30;
  double _circleHeight = 30;

  // 보안 서비스
  final SecurityService _securityService = SecurityService();

  List<Widget> get pages => [
    CalendarPage(
      isMonthlyView: isMonthlyView,
      onBottomSheetHeightChanged: (height) {
        if (mounted) {
          setState(() {
            _showNavBar = height == 0;
          });
        }
      },
    ),
    ImagesPage(),
    AnalysisPage(),
    SettingPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    pageController = PageController();
    _initSecurity();
  }

  Future<void> _initSecurity() async {
    await _securityService.initialize();
    await _securityService.bootstrapLock();
    if (_securityService.securityEnabled && mounted) {
      setState(() {});
      // 프레임 이후 인증 호출
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _authenticate();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    await _securityService.handleAppLifecycleChange(state);
    if (mounted) setState(() {});

    // 포그라운드로 돌아왔을 때 인증 시도
    if (state == AppLifecycleState.resumed) {
      if (_securityService.locked && !_securityService.authInProgress) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted && _securityService.locked && !_securityService.authInProgress) {
              _authenticate();
            }
          });
        });
      }
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _authenticate() async {
    final success = await _securityService.authenticate(context);
    if (mounted) setState(() {});
  }

  void _animateCircle(int index) {
    if (mounted) {
      setState(() {
        _circleWidth = 30;
        _circleHeight = 2;
      });
    }

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _circleWidth = 30;
          _circleHeight = 30;
          selectedIndex = index;
        });
      }
    });
  }

  void onNavTap(int index) {
    HapticFeedback.lightImpact();

    // 캘린더 아이콘 클릭 시
    if (index == 0 && selectedIndex == 0 && mounted) {
      setState(() {
        isMonthlyView = !isMonthlyView;
      });
      return;
    }

    // 다른 탭에서 캘린더 탭으로 돌아올 때는 월간 뷰로 초기화
    if (index == 0 && selectedIndex != 0 && mounted) {
      setState(() {
        isMonthlyView = true;
      });
    }

    _animateCircle(index);
    if (mounted) {
      setState(() => selectedIndex = index);
    }
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
          behavior: HitTestBehavior.opaque,
          onTap: () => onNavTap(index),
          child: SizedBox(
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
                                    ? AppColors.primary
                                    : AppColors.primary.withValues(alpha: 0.4),
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
                                    ? AppColors.primary.withValues(alpha: 0.4)
                                    : AppColors.primary,
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
        behavior: HitTestBehavior.opaque,
        onTap: () => onNavTap(index),
        child: SizedBox(
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

  Widget _buildLockOverlay() {
    return SecurityLockOverlay(
      securityEnabled: _securityService.securityEnabled,
      locked: _securityService.locked,
      authInProgress: _securityService.authInProgress,
      onUnlock: _authenticate,
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
            bottom: _showNavBar ? 24 : -64,
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
                    left:
                        context.wp(60) / 4 * selectedIndex +
                        (context.wp(60) / 8 - _circleHeight / 2),
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
          _buildLockOverlay(),
        ],
      ),
    );
  }
}
