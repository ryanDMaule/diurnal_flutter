import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/daily_publication.dart';
import 'package:diurnul/models/edition.dart';
import 'package:diurnul/screens/saved_publication_screen.dart';
import 'package:diurnul/services/bookmark_service.dart';
import 'package:diurnul/services/edition_service.dart';
import 'package:diurnul/widgets/publication_view.dart';

void main() {
  test('Original Library is the development default', () async {
    final service = EditionService(storage: _MemoryEditionStorage());
    expect(await service.loadSelectedEdition(), same(Editions.originalLibrary));
    expect(Editions.all.first, same(Editions.originalLibrary));
  });

  test('selection persists and restores in a fresh service instance', () async {
    final storage = _MemoryEditionStorage();
    await EditionService(storage: storage).selectEdition(Editions.atrium);

    final restored = await EditionService(
      storage: storage,
    ).loadSelectedEdition();
    expect(restored, same(Editions.atrium));
  });

  test('invalid selection safely falls back to Original Library', () async {
    final storage = _MemoryEditionStorage()..value = 'removed-edition';
    final restored = await EditionService(
      storage: storage,
    ).loadSelectedEdition();
    expect(restored, same(Editions.originalLibrary));
  });

  test(
    'runtime treatment keeps tint and gradient independently configurable',
    () {
      expect(Editions.library.usesLegacyTreatment, isFalse);
      expect(Editions.library.tintColor, const Color(0xFF000000));
      expect(Editions.library.tintOpacity, 0.48);
      expect(Editions.library.gradientColors, const [
        Color(0x10000000),
        Color(0xB5000000),
        Color(0xF2000000),
      ]);
      expect(Editions.library.gradientStops, [0, 0.55, 1]);
      expect(Editions.library.gradientBegin, Alignment.topCenter);
      expect(Editions.library.gradientEnd, Alignment.bottomCenter);

      expect(
        Editions.atrium.primaryTextColor.computeLuminance(),
        lessThan(0.1),
      );
      expect(Editions.atrium.systemUiIconBrightness, Brightness.dark);
      expect(
        Editions.library.primaryTextColor.computeLuminance(),
        greaterThan(0.7),
      );
      expect(
        Editions.archive.primaryTextColor.computeLuminance(),
        greaterThan(0.7),
      );
      expect(Editions.midnight.systemUiIconBrightness, Brightness.light);
      expect(Editions.gallery.accentColor, const Color(0xFFD8C66A));
    },
  );

  test(
    'PublicationView consumes an Edition without changing its publication',
    () {
      final publication = _publication;
      final view = PublicationView(
        publication: publication,
        edition: Editions.archive,
        isBookmarked: true,
        onBookmarkToggle: () {},
      );

      expect(view.publication, same(publication));
      expect(view.edition, same(Editions.archive));
    },
  );

  testWidgets('saved publication restores the persisted Edition', (
    tester,
  ) async {
    final editionStorage = _MemoryEditionStorage();
    final editionService = EditionService(storage: editionStorage);
    await editionService.selectEdition(Editions.atrium);
    final bookmarkService = BookmarkService(storage: _MemoryBookmarkStorage());
    await bookmarkService.save(_publication);

    await tester.binding.setSurfaceSize(const Size(700, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: SavedPublicationScreen(
          publication: _publication,
          bookmarkService: bookmarkService,
          editionService: editionService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final view = tester.widget<PublicationView>(find.byType(PublicationView));
    expect(view.edition, same(Editions.atrium));
    expect(view.publication, same(_publication));
  });
}

final _publication = DailyPublication(
  id: 'publication-1',
  sequence: 1,
  publicationDate: DateTime.utc(2026, 9, 1),
  word: 'Diurnal',
  type: 'Adjective',
  phonetic: 'diurnal',
  definition: 'Active during the daytime.',
  usage: 'A diurnal rhythm.',
  synonyms: const ['Daily'],
);

class _MemoryEditionStorage implements EditionStorage {
  String? value;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async {
    this.value = value;
  }
}

class _MemoryBookmarkStorage implements BookmarkStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
