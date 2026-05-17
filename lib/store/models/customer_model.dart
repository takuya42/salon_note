import 'sales_model.dart';

class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final List<Sales> sales;
  final String memo;

  /// 🔥施術写真
  final List<String>? imageUrls;

  Customer({
    required this.id,
    required this.name,
    this.email = "",
    this.phone = "",
    List<Sales>? sales,
    this.memo = "",

    /// 🔥追加
    this.imageUrls,
  }) : sales = sales ?? [];

  /// 来店回数
  int get visitCount => sales.length;

  Customer copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    List<Sales>? sales,
    String? memo,

    /// 🔥追加
    List<String>? imageUrls,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      sales: sales ?? this.sales,
      memo: memo ?? this.memo,

      /// 🔥追加
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  factory Customer.fromJson(
      Map<String, dynamic> json,
      ) {
    return Customer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',

      sales: (json['sales'] as List?)
          ?.map((e) => Sales.fromJson(e))
          .toList() ??
          [],

      memo: json["memo"] ?? "",

      /// 🔥追加
      imageUrls:
      (json['imageUrls'] as List?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,

      'sales':
      sales.map((e) => e.toJson()).toList(),

      'memo': memo,

      /// 🔥追加
      'imageUrls': imageUrls,
    };
  }
}