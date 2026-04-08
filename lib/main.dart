import 'package:employee_time_tracking/app_colors.dart';
import 'package:employee_time_tracking/dayOverview/weekly_overview_vm.dart';
import 'package:employee_time_tracking/homePage/home_viewmodel.dart';
import 'package:employee_time_tracking/monthlyOverview/monthly_overview_vm.dart';
import 'package:employee_time_tracking/profile/profile_screen.dart';
import 'package:employee_time_tracking/services/holiday_cache_initializer.dart';
import 'package:employee_time_tracking/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'dayOverview/weekly_overview_screen.dart';
import 'homePage/home_page_screen.dart';
import 'monthlyOverview/monthly_overview_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('de_DE', null);

  // Benachrichtigungsdienst initialisieren (inkl. Berechtigungsanfrage)
  await NotificationService.instance.init();

  // Initialisiere Feiertag-Cache im Hintergrund
  HolidayCacheInitializer.initializeForState('BW');

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.brandPrimary),
      ),
      home: Pages(),
    );
  }
}

class Pages extends StatefulWidget {
  const Pages({super.key});

  @override
  State<Pages> createState() => _PagesState();
}

class _PagesState extends State<Pages> {
  int _selectedIndex = 0;

  void _reloadTab(int index) {
    final container = ProviderScope.containerOf(context, listen: false);

    if (index == 0) {
      container.read(homeViewModelProvider.notifier).loadToday();
    } else if (index == 1) {
      container.read(weeklyOverviewProvider.notifier).loadWeek();
    } else if (index == 2) {
      container.read(monthlyOverviewProvider.notifier).loadMonth();
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      _reloadTab(index);
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reloadTab(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePageScreen(),
      WeeklyOverviewScreen(),
      MonthlyOverviewScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: AppColors.navBackground,

        selectedItemColor: AppColors.navSelected,
        unselectedItemColor: AppColors.navUnselected,

        type: BottomNavigationBarType.fixed,

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Timer'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_view_week),
            label: 'Woche',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart),
            label: 'Monat',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
