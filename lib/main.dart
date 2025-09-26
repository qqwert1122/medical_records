import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:medical_records/features/analysis/screens/analysis_page.dart';
import 'package:medical_records/features/calendar/screens/calendar_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:medical_records/features/images/screens/images_page.dart';
import 'package:medical_records/features/home/screens/home_page.dart';
import 'package:medical_records/features/records/screens/list_page.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/features/security/components/security_lock_overlay.dart';
import 'package:medical_records/features/security/services/security_service.dart';
import 'package:medical_records/components/custom_toggle_navigation.dart';

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
  int selectedIndex = 0; // 홈 페이지를 기본값으로 설정
  int _previousIndex = 0; // 캘린더 진입 전 페이지 인덱스 추적
  late PageController pageController;
  bool _showNavBar =
      true; // Calendar Page의 Bottom Sheet hegiht에 따라 Nav Bar show
  bool _isInCalendarMode = false; // Calendar 페이지 내부 네비게이션 모드

  // 보안 서비스
  final SecurityService _securityService = SecurityService();

  List<Widget> get pages => [
    HomePage(
      onNavigateToTab: (tabIndex) {
        if (mounted) {
          setState(() {
            selectedIndex = tabIndex;
          });
          pageController.jumpToPage(tabIndex);
        }
      },
    ),
    CalendarPage(
      onBottomSheetHeightChanged: (height) {
        if (mounted) {
          setState(() {
            _showNavBar = height == 0 && !_isInCalendarMode;
          });
        }
      },
      onCalendarModeChanged: (isInCalendarMode) {
        if (mounted) {
          setState(() {
            _isInCalendarMode = isInCalendarMode;
            _showNavBar = !isInCalendarMode;
          });
        }
      },
      onBackPressed: () {
        if (mounted) {
          setState(() {
            selectedIndex = _previousIndex;
            _isInCalendarMode = false;
            _showNavBar = true;
          });
          pageController.jumpToPage(_previousIndex);
        }
      },
    ),
    ListPage(),
    ImagesPage(),
    AnalysisPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    pageController = PageController(initialPage: 0);
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
            if (mounted &&
                _securityService.locked &&
                !_securityService.authInProgress) {
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
    await _securityService.authenticate(context);
    if (mounted) setState(() {});
  }

  void onNavTap(int index) {
    HapticFeedback.lightImpact();

    if (mounted) {
      setState(() {
        // 캘린더로 이동할 때 이전 인덱스 저장 (캘린더는 여전히 인덱스 1)
        if (index == 1 && selectedIndex != 1) {
          _previousIndex = selectedIndex;
        }
        selectedIndex = index;
      });
    }

    pageController.jumpToPage(index);
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
            physics: NeverScrollableScrollPhysics(),
            children: pages,
          ),
          _buildLockOverlay(),
          // 메인 바텀 네비게이션
          if (_showNavBar)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 16,
                    top: 8,
                    left: 24,
                    right: 24,
                  ),
                  child: CustomToggleNavigation(
                    items: [
                      ToggleNavigationItem(
                        icon: FontAwesomeIcons.house,
                        selectedIcon: FontAwesomeIcons.house,
                        label: '홈',
                      ),
                      ToggleNavigationItem(
                        icon: FontAwesomeIcons.calendar,
                        selectedIcon: FontAwesomeIcons.solidCalendar,
                        label: '캘린더',
                      ),
                      ToggleNavigationItem(
                        icon: FontAwesomeIcons.list,
                        selectedIcon: FontAwesomeIcons.list,
                        label: '리스트',
                      ),
                      ToggleNavigationItem(
                        icon: FontAwesomeIcons.image,
                        selectedIcon: FontAwesomeIcons.solidImage,
                        label: '이미지',
                      ),
                      ToggleNavigationItem(
                        icon: FontAwesomeIcons.chartPie,
                        selectedIcon: FontAwesomeIcons.chartPie,
                        label: '통계',
                      ),
                    ],
                    currentIndex: selectedIndex,
                    onTap: onNavTap,
                    height: 56,
                    iconSize: 20,
                    fontSize: 11,
                    margin: EdgeInsets.zero,
                    selectedColor: AppColors.textPrimary,
                    unselectedColor: AppColors.textSecondary,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
