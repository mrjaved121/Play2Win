abstract class FavoritesRepository {
  List<String> load();
  Future<void> save(List<String> gameIds);
}
