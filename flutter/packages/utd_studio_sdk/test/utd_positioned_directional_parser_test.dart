import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utd_studio_sdk/src/parsers/utd_positioned_directional_parser.dart';

/// A1 — the UTD Studio editor emits `utdPositionedDirectional` for RTL-aware
/// `Positioned` nodes. Without this parser the whole screen blew up with
/// "Widget type not found — utdPositionedDirectional" (the profile / Me tab).
void main() {
  const parser = StacUtdPositionedDirectionalParser();

  test('registered type matches the Studio widget type', () {
    expect(parser.type, 'utdPositionedDirectional');
  });

  test('getModel parses directional offsets and size', () {
    final model = parser.getModel(const {
      'type': 'utdPositionedDirectional',
      'start': 4,
      'top': 8,
      'end': 12,
      'bottom': 16,
      'width': 100,
      'height': 40,
    });

    expect(model.start, 4);
    expect(model.top, 8);
    expect(model.end, 12);
    expect(model.bottom, 16);
    expect(model.width, 100);
    expect(model.height, 40);
    expect(model.child, isNull);
  });

  testWidgets('renders a PositionedDirectional inside a Stack without error',
      (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Builder(
          builder: (context) {
            final model = parser.getModel(const {
              'type': 'utdPositionedDirectional',
              'start': 0,
              'top': 0,
            });
            return Stack(children: [parser.parse(context, model)]);
          },
        ),
      ),
    );

    expect(find.byType(PositionedDirectional), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
