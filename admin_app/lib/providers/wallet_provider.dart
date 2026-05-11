import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class WalletProvider extends ChangeNotifier {
  // Wallet data
  Map<String, dynamic>? _walletData;
  List<Map<String, dynamic>> _transactions = [];

  final ApiService _apiService = ApiService();

  // Getters
  Map<String, dynamic>? get walletData => _walletData;
  List<Map<String, dynamic>> get transactions => _transactions;
  ApiService get apiService => _apiService;

  // Transaction volume (total amount)
  double get transactionVolume {
    double total = 0;
    for (var tx in _transactions) {
      if (tx['amount'] != null) {
        total += double.tryParse(tx['amount'].toString()) ?? 0;
      }
    }
    return total;
  }

  // Transaction count
  int get transactionCount => _transactions.length;

  // Load wallet data (with transactions)
  Future<void> loadWalletData(String userId) async {
    try {
      final wallet = await _apiService.fetchUserWallet(userId);
      developer.log(
        'Wallet API response: $wallet',
        level: 800,
        name: 'WalletProvider',
      );
      developer.log(
        'Transactions from API: ${wallet['transactions']?.toString() ?? 'null'}',
        level: 800,
        name: 'WalletProvider',
      );
      _walletData = wallet;
      _transactions = List<Map<String, dynamic>>.from(
        wallet['transactions'] ?? [],
      );
      developer.log(
        'Transactions in provider: $_transactions',
        level: 800,
        name: 'WalletProvider',
      );
    } catch (e) {
      _walletData = null;
      _transactions = [];
    }
    notifyListeners();
  }

  // Refresh all data (for a user)
  Future<void> refresh(String userId) async {
    await loadWalletData(userId);
  }
}
