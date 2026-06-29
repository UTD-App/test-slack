/// A page of feed items plus whether the server says more pages exist.
///
/// [hasMore] is `null` when the response carried no pagination `meta` (e.g. a
/// non-paginated/legacy endpoint), letting callers fall back to inferring it
/// from an empty page.
class MomentPage<T> {
  final List<T> items;
  final bool? hasMore;
  const MomentPage(this.items, {this.hasMore});

  /// Returns a new page with [items] mapped through [transform], keeping [hasMore].
  MomentPage<R> map<R>(List<R> Function(List<T>) transform) =>
      MomentPage<R>(transform(items), hasMore: hasMore);
}
