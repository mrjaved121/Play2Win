/// One "How to Buy Credits" entry (e.g. one payment method, or an FAQ
/// item), managed from the admin dashboard's How to Buy CMS — plain
/// display content, not a payment system. The public feed this is loaded
/// from already filters to active entries and sorts by admin-configured
/// display order, so neither concept needs to travel to the client.
class PurchaseGuideEntry {
  const PurchaseGuideEntry({required this.id, required this.title, required this.content});

  final String id;
  final String title;
  final String content;

  factory PurchaseGuideEntry.fromJson(Map<String, dynamic> json) {
    return PurchaseGuideEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
    );
  }
}
