import 'package:employee_time_tracking/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<BuildContext> _pumpResponsiveHarness(
  WidgetTester tester, {
  required Size size,
}) async {
  late BuildContext capturedContext;

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );

  return capturedContext;
}

void main() {
  group('ResponsiveUtils', () {
    testWidgets('erkennt kleine Geraete und passende Padding-Werte', (tester) async {
      final context = await _pumpResponsiveHarness(
        tester,
        size: const Size(320, 640),
      );

      expect(ResponsiveUtils.isSmallDevice(context), isTrue);
      expect(ResponsiveUtils.isMediumDevice(context), isFalse);
      expect(ResponsiveUtils.isLargeDevice(context), isFalse);
      expect(ResponsiveUtils.getResponsivePadding(context), const EdgeInsets.all(8));
      expect(ResponsiveUtils.getResponsiveHeight(context, 0.5), 320);
      expect(ResponsiveUtils.getResponsiveWidth(context, 0.5), 160);
    });

    testWidgets('erkennt mittlere Geraete und nutzt schmale Button-Breite', (tester) async {
      final context = await _pumpResponsiveHarness(
        tester,
        size: const Size(400, 800),
      );

      expect(ResponsiveUtils.isSmallDevice(context), isFalse);
      expect(ResponsiveUtils.isMediumDevice(context), isTrue);
      expect(ResponsiveUtils.isLargeDevice(context), isFalse);
      expect(ResponsiveUtils.getResponsivePadding(context), const EdgeInsets.all(12));
      expect(ResponsiveUtils.getResponsiveButtonWidth(context), 150);
      expect(ResponsiveUtils.getResponsiveFontSize(context, 20), 20);
    });

    testWidgets('erkennt grosse Geraete und nutzt grosses Padding', (tester) async {
      final context = await _pumpResponsiveHarness(
        tester,
        size: const Size(900, 1200),
      );

      expect(ResponsiveUtils.isSmallDevice(context), isFalse);
      expect(ResponsiveUtils.isMediumDevice(context), isFalse);
      expect(ResponsiveUtils.isLargeDevice(context), isTrue);
      expect(ResponsiveUtils.getResponsivePadding(context), const EdgeInsets.all(16));
      expect(ResponsiveUtils.getResponsiveButtonWidth(context), 290);
      expect(ResponsiveUtils.getResponsiveSize(context, 24), 24);
    });
  });
}

