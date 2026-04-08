class AppAlert {
  AppAlert({
    required this.title,
    required this.subtitle,
    required this.time,
    this.isUnread = true,
  });

  final String title;
  final String subtitle;
  final DateTime time;
  final bool isUnread;
}
