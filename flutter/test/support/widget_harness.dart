import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared pump harness for widget tests.
///
/// Most reusable widgets read sizes via `flutter_screenutil` (`.w/.h/.sp`) and
/// colours from `ColorManager`, so they must be pumped inside a `ScreenUtilInit`
/// + `MaterialApp`. Use [pumpApp] to get a consistent, settled tree.
///
/// ```dart
/// await pumpApp(tester, const LoadingWidget());
/// expect(find.byType(CircularProgressIndicator), findsOneWidget);
/// ```
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  Size design = const Size(375, 812),
  ThemeData? theme,
  Locale? locale,
}) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: design,
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: locale,
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
  // ScreenUtilInit builds its child via a post-frame builder; settle it.
  await tester.pump();
}
