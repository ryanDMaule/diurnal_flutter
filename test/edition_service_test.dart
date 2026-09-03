import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/models/daily_publication.dart';
import 'package:diurnul/models/edition.dart';
import 'package:diurnul/models/edition_access_policy.dart';
import 'package:diurnul/models/subscription_tier.dart';
import 'package:diurnul/screens/saved_publication_screen.dart';
import 'package:diurnul/services/bookmark_service.dart';
import 'package:diurnul/services/edition_service.dart';
import 'package:diurnul/services/entitlement_service.dart';
import 'package:diurnul/widgets/entitlement_scope.dart';
import 'package:diurnul/widgets/publication_view.dart';
import 'package:diurnul/widgets/edition_background.dart';

void main() {
  test('Library is the canonical default', () async {
    final service = EditionService(storage: _MemoryEditionStorage());
    expect(await service.loadSelectedEdition(), same(Editions.library));
    expect(Editions.all.first, same(Editions.library));
    expect(Editions.all, hasLength(6));
  });

  test('Edition access policy applies the Free and Pro matrix', () {
    for (final edition in [
      Editions.library,
      Editions.evergreen,
      Editions.midnight,
    ]) {
      expect(EditionAccessPolicy.requiresPro(edition), isFalse);
      expect(
        EditionAccessPolicy.effectiveFor(edition, isPro: false),
        same(edition),
      );
    }
    for (final edition in [
      Editions.atrium,
      Editions.archive,
      Editions.gallery,
    ]) {
      expect(EditionAccessPolicy.requiresPro(edition), isTrue);
      expect(
        EditionAccessPolicy.effectiveFor(edition, isPro: false),
        same(Editions.library),
      );
    }
    for (final edition in Editions.all) {
      expect(
        EditionAccessPolicy.effectiveFor(edition, isPro: true),
        same(edition),
      );
    }
  });

  test(
    'Evergreen has a stable id and persists through EditionService',
    () async {
      final storage = _MemoryEditionStorage();
      final service = EditionService(storage: storage);

      expect(Editions.evergreen.id, 'evergreen');
      expect(Editions.evergreen.backgroundAsset, isNull);
      expect(Editions.evergreen.backgroundColor, const Color(0xFF032C23));
      expect(Editions.evergreen.tintOpacity, 0);
      expect(Editions.evergreen.gradientColors, isEmpty);
      expect(Editions.evergreen.primaryTextColor, const Color(0xFFF3EBDD));
      expect(Editions.evergreen.accentColor, const Color(0xFFC8A363));
      await service.selectEdition(Editions.evergreen);

      expect(
        await EditionService(storage: storage).loadSelectedEdition(),
        same(Editions.evergreen),
      );
    },
  );

  test('selection persists and restores in a fresh service instance', () async {
    final storage = _MemoryEditionStorage();
    await EditionService(storage: storage).selectEdition(Editions.atrium);

    final restored = await EditionService(
      storage: storage,
    ).loadSelectedEdition();
    expect(restored, same(Editions.atrium));
  });

  test('invalid selection safely falls back to Library', () async {
    final storage = _MemoryEditionStorage()..value = 'removed-edition';
    final restored = await EditionService(
      storage: storage,
    ).loadSelectedEdition();
    expect(restored, same(Editions.library));
  });

  test('legacy Original Library selection migrates to Library', () async {
    final storage = _MemoryEditionStorage()..value = 'original-library';
    final restored = await EditionService(
      storage: storage,
    ).loadSelectedEdition();
    expect(restored, same(Editions.library));
    expect(storage.value, Editions.library.id);
  });

  test(
    'runtime treatment keeps tint and gradient independently configurable',
    () {
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
    await editionService.selectEdition(Editions.evergreen);
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
    expect(view.edition, same(Editions.evergreen));
    expect(view.publication, same(_publication));
    expect(
      tester.widget<EditionBackground>(find.byType(EditionBackground)).edition,
      same(Editions.evergreen),
    );
  });

  testWidgets('saved publication renders the entitlement-effective Edition', (
    tester,
  ) async {
    final editionStorage = _MemoryEditionStorage();
    final editionService = EditionService(storage: editionStorage);
    await editionService.selectEdition(Editions.gallery);
    final bookmarkService = BookmarkService(storage: _MemoryBookmarkStorage());
    final controller = EntitlementController(
      EntitlementService(storage: _MemoryEntitlementStorage()),
    );
    await tester.binding.setSurfaceSize(const Size(700, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      EntitlementScope(
        notifier: controller,
        child: MaterialApp(
          home: SavedPublicationScreen(
            publication: _publication,
            bookmarkService: bookmarkService,
            editionService: editionService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<PublicationView>(find.byType(PublicationView)).edition,
      same(Editions.library),
    );

    await controller.update(SubscriptionTier.pro);
    await tester.pumpAndSettle();
    expect(
      tester.widget<PublicationView>(find.byType(PublicationView)).edition,
      same(Editions.gallery),
    );
    expect(await editionService.loadSelectedEdition(), same(Editions.gallery));
  });

  testWidgets('PublicationView renders Evergreen as a solid Edition', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PublicationView(
          publication: _publication,
          edition: Editions.evergreen,
          isBookmarked: false,
          onBookmarkToggle: null,
        ),
      ),
    );

    final background = tester.widget<EditionBackground>(
      find.byType(EditionBackground),
    );
    expect(background.edition, same(Editions.evergreen));
    expect(find.byType(Image), findsNothing);
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

class _MemoryEntitlementStorage implements EntitlementStorage {
  String? value;

  @override
  Future<String?> readTier() async => value;

  @override
  Future<void> writeTier(String tier) async => value = tier;
}
