import 'user_model.dart';

class ExpenseShare {
  final String id;
  final String expenseId;
  final String userId;
  final double amount;
  final UserModel? user;

  ExpenseShare({
    required this.id,
    required this.expenseId,
    required this.userId,
    required this.amount,
    this.user,
  });

  factory ExpenseShare.fromJson(Map<String, dynamic> json) {
    return ExpenseShare(
      id: json['id'],
      expenseId: json['expenseId'] ?? json['expense_id'],
      userId: json['userId'] ?? json['user_id'],
      amount: (json['amount'] as num).toDouble(),
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense_id': expenseId,
      'user_id': userId,
      'amount': amount,
    };
  }
}

class ExpenseModel {
  final String id;
  final String groupId;
  final String title;
  final double amount;
  final String paidBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ExpenseShare>? shares;
  final UserModel? paidByUser;

  ExpenseModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.createdAt,
    required this.updatedAt,
    this.shares,
    this.paidByUser,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    List<ExpenseShare>? sharesList;

    if (json['expense_shares'] != null) {
      sharesList =
          (json['expense_shares'] as List)
              .map((share) => ExpenseShare.fromJson(share))
              .toList();
    } else if (json['shares'] != null) {
      sharesList =
          (json['shares'] as List)
              .map((share) => ExpenseShare.fromJson(share))
              .toList();
    }

    return ExpenseModel(
      id: json['id'],
      groupId: json['groupId'] ?? json['group_id'],
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      paidBy: json['paidBy'] ?? json['paid_by'],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : (json['created_at'] != null
                  ? DateTime.parse(json['created_at'])
                  : DateTime.now()),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : (json['updated_at'] != null
                  ? DateTime.parse(json['updated_at'])
                  : DateTime.now()),
      shares: sharesList,
      paidByUser:
          json['paid_by_user'] != null
              ? UserModel.fromJson(json['paid_by_user'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'title': title,
      'amount': amount,
      'paid_by': paidBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create an updated copy
  ExpenseModel copyWith({
    String? id,
    String? groupId,
    String? title,
    double? amount,
    String? paidBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ExpenseShare>? shares,
    UserModel? paidByUser,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      paidBy: paidBy ?? this.paidBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shares: shares ?? this.shares,
      paidByUser: paidByUser ?? this.paidByUser,
    );
  }
}
