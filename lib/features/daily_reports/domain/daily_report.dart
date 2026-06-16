class DailyReport {
  final String id;
  final String staffId;
  final DateTime reportDate;
  final String whatIdid;
  final String plansForWeek;
  final DateTime? createdAt;

  DailyReport({
    required this.id,
    required this.staffId,
    required this.reportDate,
    required this.whatIdid,
    required this.plansForWeek,
    this.createdAt,
  });
}
