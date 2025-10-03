import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:medical_records/features/analysis/screens/analysis_page.dart';
import 'package:medical_records/features/records/screens/records_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:medical_records/features/images/screens/images_page.dart';
import 'package:medical_records/features/home/screens/home_page.dart';
import 'package:medical_records/features/form/screens/record_form_page.dart';
import 'package:medical_records/features/bodymap/screens/bodymap_page.dart';
import 'package:medical_records/services/review_service.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
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
    return MaterialApp(
      title: '마이델로지',
      theme: ThemeData(
        fontFamily: 'Pretendard',
        textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'Pretendard',
        ),
      ),
      home: MainNavigation(),
    );
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
  late PageController pageController;

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
    RecordsPage(),
    BodyMapPage(),
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
        selectedIndex = index;
      });
    }

    pageController.jumpToPage(index);
  }

  Future<void> _showAddRecordForm() async {
    HapticFeedback.mediumImpact();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: RecordFormPage(selectedDate: DateTime.now()),
          ),
    );

    if (result == true) {
      // 데이터 새로고침을 위해 현재 페이지 다시 빌드
      if (mounted) {
        setState(() {});
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ReviewService.requestReviewIfEligible(context);
      });
    }
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
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: onNavTap,
        selectedItemColor: AppColors.textPrimary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: Colors.white,
        elevation: 8,
        iconSize: 20,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.house),
            activeIcon: Icon(FontAwesomeIcons.house),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.calendar),
            activeIcon: Icon(FontAwesomeIcons.solidCalendar),
            label: '기록',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.personRays),
            activeIcon: Icon(FontAwesomeIcons.personRays),
            label: '바디맵',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.image),
            activeIcon: Icon(FontAwesomeIcons.solidImage),
            label: '이미지',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.chartLine),
            activeIcon: Icon(FontAwesomeIcons.chartLine),
            label: '통계',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecordForm,
        backgroundColor: AppColors.primary,
        shape: CircleBorder(),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
