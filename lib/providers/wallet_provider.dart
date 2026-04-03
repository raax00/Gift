import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletProvider extends ChangeNotifier {
  double _balance = 0.0;

  double get balance => _balance;

  WalletProvider() {
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    _balance = prefs.getDouble('wallet_balance') ?? 0.0;
    notifyListeners();
  }

  Future<void> addMoney(double amount) async {
    _balance += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('wallet_balance', _balance);
    notifyListeners();
  }

  Future<bool> deductMoney(double amount) async {
    if (_balance >= amount) {
      _balance -= amount;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('wallet_balance', _balance);
      notifyListeners();
      return true;
    }
    return false;
  }
}