/// A single Help & Support text entry, managed from the admin dashboard and
/// shown to players — e.g. FAQ answers or "this is a demo" disclaimers.
class SupportEntry {
  const SupportEntry({required this.id, required this.title, required this.content});

  final String id;
  final String title;
  final String content;

  factory SupportEntry.fromJson(Map<String, dynamic> json) {
    return SupportEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
    );
  }
}
