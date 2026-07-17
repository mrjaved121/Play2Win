/// Admin-editable "How to Buy Credits" text — plain display content, not
/// a payment system. Null anywhere it's consumed means nothing has been
/// published yet (or it's currently turned off), not an error.
class PurchaseInfo {
  const PurchaseInfo({required this.title, required this.content});

  final String title;
  final String content;

  factory PurchaseInfo.fromJson(Map<String, dynamic> json) {
    return PurchaseInfo(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }
}
