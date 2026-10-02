class GetDashboardDetailsModel {
  final String? status;
  final String? message;
  final Summary? summary;
  final YearlyStatistics? yearlyStatistics;

  GetDashboardDetailsModel({
    this.status,
    this.message,
    this.summary,
    this.yearlyStatistics,
  });

  factory GetDashboardDetailsModel.fromJson(Map<String, dynamic> json) {
    return GetDashboardDetailsModel(
      status: json['status'] as String?,
      message: json['message'] as String?,
      summary: json['summary'] != null
          ? Summary.fromJson(json['summary'])
          : null,
      yearlyStatistics: json['yearly_statistics'] != null && json['yearly_statistics'] is Map<String, dynamic>
          ? YearlyStatistics.fromJson(json['yearly_statistics'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'summary': summary?.toJson(),
      'yearly_statistics': yearlyStatistics?.toJson(),
    };
  }
}

class Summary {
  final String? todayTotal;
  final int? todayCount;
  final String? monthTotal;
  final int? monthCount;
  final String? pendingTotal;
  final int? pendingCount;
  final String? missedTotal;
  final int? missedCount;
  final String? completedTotal;
  final int? completedCount;
  final int? gbcoins;

  Summary({
    this.todayTotal,
    this.todayCount,
    this.monthTotal,
    this.monthCount,
    this.pendingTotal,
    this.pendingCount,
    this.missedTotal,
    this.missedCount,
    this.completedTotal,
    this.completedCount,
    this.gbcoins,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      todayTotal: json['today_total'] as String?,
      todayCount: json['today_count'] as int?,
      monthTotal: json['month_total'] as String?,
      monthCount: json['month_count'] as int?,
      pendingTotal: json['pending_total'] as String?,
      pendingCount: json['pending_count'] as int?,
      missedTotal: json['missed_total'] as String?,
      missedCount: json['missed_count'] as int?,
      completedTotal: json['completed_total'] as String?,
      completedCount: json['completed_count'] as int?,
      gbcoins: json['gbcoins'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'today_total': todayTotal,
      'today_count': todayCount,
      'month_total': monthTotal,
      'month_count': monthCount,
      'pending_total': pendingTotal,
      'pending_count': pendingCount,
      'missed_total': missedTotal,
      'missed_count': missedCount,
      'completed_total': completedTotal,
      'completed_count': completedCount,
      'gbcoins': gbcoins,
    };
  }
}

class YearlyStatistics {
  final String? year;
  final String? totalAmount;
  final List<MonthStat> months;

  YearlyStatistics({
    this.year,
    this.totalAmount,
    this.months = const [],
  });

  factory YearlyStatistics.fromJson(Map<String, dynamic> json) {
    return YearlyStatistics(
      year: json['year']?.toString(),
      totalAmount: json['total_amount']?.toString(),
      months: (json['months'] as List<dynamic>?)
              ?.map((item) => MonthStat.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'total_amount': totalAmount,
      'months': months.map((m) => m.toJson()).toList(),
    };
  }
}

class MonthStat {
  final String? year;
  final String? month;
  final String? monthShort;
  final String? monthNumber;
  final String? amount;
  final int? orderCount;

  MonthStat({
    this.year,
    this.month,
    this.monthShort,
    this.monthNumber,
    this.amount,
    this.orderCount,
  });

  factory MonthStat.fromJson(Map<String, dynamic> json) {
    return MonthStat(
      year: json['year']?.toString(),
      month: json['month']?.toString(),
      monthShort: json['month_short']?.toString(),
      monthNumber: json['month_number']?.toString(),
      amount: json['amount']?.toString(),
      orderCount: json['order_count'] is int
          ? json['order_count'] as int
          : int.tryParse(json['order_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'month_short': monthShort,
      'month_number': monthNumber,
      'amount': amount,
      'order_count': orderCount,
    };
  }
}