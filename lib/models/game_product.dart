class GameProduct {
  final String id;
  final String name;
  final String type; // 'uc' or 'popularity'
  final int amount;  // UC amount or popularity points
  final int price;
  final String? bonus; // optional bonus text

  GameProduct({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.price,
    this.bonus,
  });
}