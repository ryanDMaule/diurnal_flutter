import 'edition.dart';

abstract final class EditionAccessPolicy {
  static const _proEditionIds = {'atrium', 'archive', 'gallery'};

  static bool requiresPro(Edition edition) =>
      _proEditionIds.contains(edition.id);

  static bool canSelect(Edition edition, {required bool isPro}) =>
      isPro || !requiresPro(edition);

  static Edition effectiveFor(Edition stored, {required bool isPro}) =>
      canSelect(stored, isPro: isPro) ? stored : Editions.library;
}
