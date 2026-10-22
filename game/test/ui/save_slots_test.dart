import 'package:cambric_game/save/save_data.dart';
import 'package:cambric_game/save/save_service.dart';
import 'package:cambric_game/ui/screens/save_slots_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/ui_harness.dart';

List<SaveSlotInfo> _slots({SaveSlot? filled, SaveData? data}) {
  return [
    for (final slot in SaveSlot.defaultSlots)
      SaveSlotInfo(
        slot: slot,
        data: filled != null && slot.id == filled.id ? data : null,
      ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(loadEnglish);
  tearDown(loadEnglish);

  testWidgets('lists filled and empty slots and starts the chosen one',
      (tester) async {
    await setSurface(tester, const Size(1280, 720));

    final data = SaveData.fresh('slot_1').copyWith(
      playtimeSeconds: 125,
      updatedAt: DateTime(2026, 1, 2, 3, 4),
    );
    final slots = _slots(filled: SaveSlot.slot1, data: data);

    SaveSlot? played;
    await tester.pumpWidget(
      wrapApp(
        SaveSlotsScreen(
          loadSlots: () async => slots,
          onPlay: (slot) => played = slot,
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Save Files'), findsOneWidget);
    expect(find.text('Slot 1'), findsOneWidget);
    expect(find.text('2m'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Empty'), findsNWidgets(3));
    expect(find.text('New Game'), findsNWidgets(3));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(played?.id, SaveSlot.slot1.id);
  });

  testWidgets('deleting a save asks first and refreshes the slot',
      (tester) async {
    await setSurface(tester, const Size(1280, 720));

    var slots = _slots(
      filled: SaveSlot.slot2,
      data: SaveData.fresh('slot_2').copyWith(playtimeSeconds: 60),
    );

    await tester.pumpWidget(
      wrapApp(
        SaveSlotsScreen(
          loadSlots: () async => slots,
          deleteSlot: (slot) async {
            slots = [
              for (final info in slots)
                info.slot.id == slot.id
                    ? SaveSlotInfo(slot: info.slot, data: null)
                    : info,
            ];
            return true;
          },
          onPlay: (_) {},
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Empty'), findsNWidgets(3));

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Delete this save?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete this save?'), findsNothing);
    expect(find.text('Empty'), findsNWidgets(4));
  });
}
