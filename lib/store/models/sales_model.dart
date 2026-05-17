class Sales {
  final double price;
  final String menu;
  final DateTime date; // ←ここ変更

  Sales({
    required this.price,
    required this.menu,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    "price": price,
    "menu": menu,
    "date": date.toIso8601String(),
  };

  factory Sales.fromJson(Map<String, dynamic> json) {
    return Sales(
      price: json["price"],
      menu: json["menu"],
      date: DateTime.parse(json["date"]),
    );
  }
}