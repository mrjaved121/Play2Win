abstract class RecentlyPlayedRepository {
  List<String> load();
  Future<void> save(List<String> gameIds);
}
