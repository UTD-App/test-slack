import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/core/enums.dart';
import 'package:utd_app/shared/widgets/handling_data_widget.dart';

import '../../support/widget_harness.dart';

/// Builds a [HandlingDataWidget] with sensible defaults so each test only
/// supplies the parts it cares about.
Widget _build({
  required RequestState reqState,
  Widget child = const Text('LOADED-CHILD'),
  Widget? childEmpty,
  bool? isNeedLoadingWidget,
  bool? isLoadingCenter,
}) {
  return HandlingDataWidget(
    reqState: reqState,
    title: 'title',
    subTitle: 'subTitle',
    childEmpty: childEmpty,
    isNeedLoadingWidget: isNeedLoadingWidget,
    isLoadingCenter: isLoadingCenter,
    child: child,
  );
}

void main() {
  group('HandlingDataWidget', () {
    testWidgets('loaded state renders the child', (tester) async {
      await pumpApp(tester, _build(reqState: RequestState.loaded));

      expect(find.text('LOADED-CHILD'), findsOneWidget);
    });

    testWidgets('idle state also falls through to the child', (tester) async {
      // idle is not loading/error/offline/ban/empty, so it hits the else branch.
      await pumpApp(tester, _build(reqState: RequestState.idle));

      expect(find.text('LOADED-CHILD'), findsOneWidget);
    });

    testWidgets('loading state shows a LoadingView animation', (tester) async {
      await pumpApp(tester, _build(reqState: RequestState.loading));

      // LoadingView wraps loading_animation_widget's StaggeredDotsWave (a
      // private factory output, not a public widget type), so we assert on
      // LoadingView + the absence of the loaded child instead.
      expect(find.byType(LoadingView), findsOneWidget);
      expect(find.text('LOADED-CHILD'), findsNothing);
    });

    testWidgets(
        'loading state renders the child when isNeedLoadingWidget is false',
        (tester) async {
      await pumpApp(
        tester,
        _build(
          reqState: RequestState.loading,
          isNeedLoadingWidget: false,
        ),
      );

      expect(find.byType(LoadingView), findsNothing);
      expect(find.text('LOADED-CHILD'), findsOneWidget);
    });

    testWidgets('loading with isLoadingCenter true still shows the animation',
        (tester) async {
      await pumpApp(
        tester,
        _build(reqState: RequestState.loading, isLoadingCenter: true),
      );

      expect(find.byType(LoadingView), findsOneWidget);
      // isLoadingCenter true yields a fixed-height SizedBox wrapper.
      expect(
        find.descendant(
          of: find.byType(LoadingView),
          matching: find.byType(SizedBox),
        ),
        findsWidgets,
      );
    });

    testWidgets('empty state renders provided childEmpty', (tester) async {
      // A custom childEmpty avoids EmptyView's Lottie asset + context.tr usage.
      await pumpApp(
        tester,
        _build(
          reqState: RequestState.empty,
          childEmpty: const Text('EMPTY-CHILD'),
        ),
      );

      expect(find.text('EMPTY-CHILD'), findsOneWidget);
      expect(find.text('LOADED-CHILD'), findsNothing);
    });

    testWidgets('banUser state renders BanUserWidget with title text',
        (tester) async {
      // BanUserWidget uses constructor title/subTitle (no context.tr) and an
      // Image.asset (which builds fine in tests even if the asset is absent).
      await pumpApp(tester, _build(reqState: RequestState.banUser));

      expect(find.byType(BanUserWidget), findsOneWidget);
      expect(find.text('title'), findsOneWidget);
    });

    // SKIPPED branches (documented):
    // - RequestState.error  -> ErrorView calls context.tr('app.error')
    // - RequestState.offline -> _OfflineView calls context.tr(...)
    //   Both require a Localizations<AppTranslations> delegate which the test
    //   harness does not install; AppTranslations.of(context)! would throw.
    // - EmptyView default (no childEmpty) loads Lottie.asset(...) which throws
    //   on a missing asset in the test environment. Covered via childEmpty.
  });
}
