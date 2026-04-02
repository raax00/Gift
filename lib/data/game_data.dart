import '../models/game_product.dart';

final List<GameProduct> ucPackages = [
  GameProduct(id: 'uc1', name: '60 UC', type: 'uc', amount: 60, price: 75),
  GameProduct(id: 'uc2', name: '325 UC', type: 'uc', amount: 325, price: 380, bonus: '+25 Bonus'),
  GameProduct(id: 'uc3', name: '660 UC', type: 'uc', amount: 660, price: 750, bonus: '+60 Bonus'),
  GameProduct(id: 'uc4', name: '1800 UC', type: 'uc', amount: 1800, price: 1900, bonus: '+300 Bonus'),
  GameProduct(id: 'uc5', name: '3850 UC', type: 'uc', amount: 3850, price: 3800, bonus: '+850 Bonus'),
  GameProduct(id: 'uc6', name: '8100 UC', type: 'uc', amount: 8100, price: 7500, bonus: '+2100 Bonus'),
];

final List<GameProduct> popularityPackages = [
  GameProduct(id: 'pop1', name: '100 Popularity', type: 'popularity', amount: 100, price: 150),
  GameProduct(id: 'pop2', name: '200 Popularity', type: 'popularity', amount: 200, price: 280),
  GameProduct(id: 'pop3', name: '500 Popularity', type: 'popularity', amount: 500, price: 650),
  GameProduct(id: 'pop4', name: '1000 Popularity', type: 'popularity', amount: 1000, price: 1200),
  GameProduct(id: 'pop5', name: '2000 Popularity', type: 'popularity', amount: 2000, price: 2300),
];