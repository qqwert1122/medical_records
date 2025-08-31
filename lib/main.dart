import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/analysis/screens/analysis_page.dart';
import 'package:medical_records/calendar/screens/calendar_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:medical_records/images/screens/images_page.dart';
import 'package:medical_records/records/screens/setting_page.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/widgets/pin_code_dialog.dart';

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

  // 보안 관련 변수
  static const _kSecurityEnabledKey = 'security_enabled';
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _securityEnabled = false; // 저장된 설정값
  bool _locked = false; // 오버레이 표시 여부
  bool _authInProgress = false; // 중복 인증 방지
  bool _pinDialogOpen = false;
  static const _kPinCodeKey = 'pin_code';

  List<Widget> get pages => [
    CalendarPage(
      isMonthlyView: isMonthlyView,
      onBottomSheetHeightChanged: (height) {
        setState(() {
          _showNavBar = height == 0;
        });
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
    _bootstrapLock();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (!_securityEnabled) return;
    // 백그라운드로 가면 잠금 (inactive는 인증창 떠도 발생하므로 건드리지 않음)
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (!_authInProgress && mounted) {
        setState(() => _locked = true);
      }
      return;
    }
    if (state == AppLifecycleState.inactive) return;

    if (state == AppLifecycleState.resumed) {
      // 잠겨 있고 인증 중이 아닐 때만 인증 시도
      if (_locked && !_authInProgress) {
        await _reloadSecurityFlag();
        if (!_securityEnabled) {
          if (mounted) setState(() => _locked = false);
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted && _locked && !_authInProgress) {
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

  Future<void> _bootstrapLock() async {
    await _reloadSecurityFlag();
    if (!mounted) return;

    if (_securityEnabled) {
      setState(() => _locked = true);
      // 프레임 이후 인증 호출 (UI가 뜬 뒤)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _authenticate();
      });
    }
  }

  Future<void> _reloadSecurityFlag() async {
    final v = await _storage.read(key: _kSecurityEnabledKey);
    _securityEnabled = v == 'true';
  }

  Future<void> _authenticate() async {
    if (!_locked || _authInProgress || !_securityEnabled) {
      return;
    } // 잠금 아님 / 진행중 / 비활성화면 바로 리턴

    _authInProgress = true;

    try {
      // 생체인증 가능 여부 확인
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();

      if (!canCheck || !supported) {
        // 생체 불가 → PIN 폴백
        _authInProgress = false; // 다음 호출 허용
        await _showPinDialog(); // await로 중복 방지
        return;
      }

      final ok = await _auth.authenticate(
        localizedReason: '건강 로그 잠금 해제',
        options: const AuthenticationOptions(
          biometricOnly: false, // OS 패스코드까지 허용
          useErrorDialogs: true,
          stickyAuth: true, // 루프 발생 시 false로도 테스트 가능
        ),
      );
      if (!mounted) return;
      setState(() => _locked = !ok);
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable' || e.code == 'NotEnrolled') {
        _authInProgress = false;
        await _showPinDialog();
        return;
      }
      if (!mounted) return;
      setState(() => _locked = true);
    } finally {
      _authInProgress = false;
    }
  }

  Future<void> _showPinDialog() async {
    if (_pinDialogOpen) return; // 이미 떠있으면 재진입 금지
    _pinDialogOpen = true;
    final stored = await _storage.read(key: _kPinCodeKey);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => PinCodeDialog(
            isSetup: stored == null,
            onSubmit: (pin) async {
              if (stored == null) {
                await _storage.write(key: _kPinCodeKey, value: pin);
                setState(() => _locked = false);
                _pinDialogOpen = false;
                Navigator.pop(context);
              } else if (stored == pin) {
                setState(() => _locked = false);
                _pinDialogOpen = false;
                Navigator.pop(context);
              } else {
                // 잘못된 PIN → 다이얼로그 유지
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('잘못된 PIN입니다')));
              }
            },
            expectedPin: stored,
          ),
    );

    // 혹시 다른 경로로 닫혔을 때도 안전하게 리셋
    _pinDialogOpen = false;
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

  Widget _buildLockOverlay() {
    if (!_securityEnabled || !_locked) return const SizedBox.shrink();

    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: AppColors.background,
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.lock, size: 30, color: AppColors.primary),
                  const SizedBox(height: 12),
                  Text(
                    '잠김',
                    style: AppTextStyle.title.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '잠금을 해제하세요',
                    style: AppTextStyle.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _authInProgress ? null : _authenticate,
                    label: const Text('잠금 해제'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
          _buildLockOverlay(),
        ],
      ),
    );
  }
}
