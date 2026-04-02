class GameProduct {
  final String id;
  final String name;
  final String type; // 'uc' or 'popularity'
  final int amount;
  final int price;
  final String? bonus;

  GameProduct({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.price,
    this.bonus,
  });
}