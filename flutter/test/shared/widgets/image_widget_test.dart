import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/widgets/image_widget.dart';

import '../../support/widget_harness.dart';

/// Runs [body] while swallowing the *expected* async asset-load / SVG-parse
/// errors that occur when a test references an asset path that has no real
/// bundled bytes. We only need to assert the widget *type* is built, not that
/// the asset decodes. Any other error is re-thrown so genuine failures surface.
Future<void> _ignoringAssetErrors(Future<void> Function() body) async {
  final previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exceptionAsString();
    if (msg.contains('Unable to load asset') ||
        msg.contains('Invalid SVG data') ||
        msg.contains('does not exist or has empty data')) {
      return; // expected in the test sandbox
    }
    previous?.call(details);
  };
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
}

void main() {
  group('ImageWidget', () {
    testWidgets('builds an Image.asset for a raster path', (tester) async {
      // Use a real bundled asset so the image decodes cleanly.
      await pumpApp(
        tester,
        const ImageWidget(
          image: 'assets/images/ban.png',
          height: 50,
          width: 50,
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(SvgPicture), findsNothing);

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.width, 50);
      expect(image.height, 50);
    });

    testWidgets('builds an SvgPicture for an .svg path', (tester) async {
      await _ignoringAssetErrors(() async {
        await pumpApp(
          tester,
          const ImageWidget(
            image: 'assets/icons/star.svg',
            height: 30,
            width: 30,
          ),
        );

        expect(find.byType(SvgPicture), findsOneWidget);
        expect(find.byType(Image), findsNothing);
      });
    });

    testWidgets('applies color and fit to a raster image', (tester) async {
      await pumpApp(
        tester,
        const ImageWidget(
          image: 'assets/images/ban.png',
          height: 50,
          width: 50,
          color: Colors.red,
          boxFit: BoxFit.cover,
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.color, Colors.red);
      expect(image.fit, BoxFit.cover);
    });
  });
}
