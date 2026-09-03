import '../models/daily_publication.dart';

class ArchiveAccess {
  const ArchiveAccess._();

  static const freePublicationLimit = 5;

  static Set<String> accessiblePublicationIds(
    Iterable<DailyPublication> publications, {
    required bool isPro,
  }) {
    final datedPublications =
        publications
            .where(
              (publication) =>
                  publication.id != null && publication.publicationDate != null,
            )
            .toList()
          ..sort((a, b) => b.publicationDate!.compareTo(a.publicationDate!));

    final accessible = isPro
        ? datedPublications
        : datedPublications.take(freePublicationLimit);
    return Set<String>.unmodifiable(
      accessible.map((publication) => publication.id!),
    );
  }

  static bool isAccessible(
    DailyPublication publication,
    Iterable<DailyPublication> publications, {
    required bool isPro,
  }) {
    final id = publication.id;
    return id != null &&
        accessiblePublicationIds(publications, isPro: isPro).contains(id);
  }
}
