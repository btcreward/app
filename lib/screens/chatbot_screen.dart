import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../providers/wallet_provider.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  ChatBotScreenState createState() => ChatBotScreenState();
}

class ChatBotScreenState extends State<ChatBotScreen> {
  final List<Map<String, String>> messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;
  UserProfile? userProfile;
  final Random _random = Random();
  StreamSubscription? _balanceSubscription;
  late WalletProvider _walletProvider;

  final Map<String, List<String>> quickRepliesCategories = {
    'Wallet & Transactions': [
      'Check balance',
      'Recent transactions',
      'rewards',
    ],
    'Redemptions': [
      'Start redemption',
      'Check status',
      'Redemption history',
    ],
    'Mining': [
      'Mining speed',
      'Power-ups',
      'Boost mining',
    ],
    'Help': [
      'How it works',
      'Support',
      'FAQ',
    ],
  };

  final List<String> acknowledgements = [
    'I understand.',
    'Got it!',
    'I see.',
    'Alright!',
    'Sure thing!',
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _initializeUserProfile();
    await _loadChatHistory();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _setupBalanceListener();
  }

  void _setupBalanceListener() {
    if (_balanceSubscription != null) {
      _balanceSubscription!.cancel();
    }

    // Update user profile when wallet balance changes
    _balanceSubscription =
        Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (mounted && userProfile != null) {
        setState(() {
          userProfile!.walletBalance = _walletProvider.btcBalance;
          userProfile!.totalMined = _walletProvider.totalEarned;
          userProfile!.totalRedeemed = _walletProvider.totalRedeemed;
          userProfile!.miningRate =
              _calculateMiningRate(userProfile!.totalMined);
          _saveUserProfile();
        });
      }
    });
  }

  @override
  void dispose() {
    _balanceSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  double _calculateMiningRate(double totalMined) {
    final days = userProfile?.getDaysActive() ?? 1;
    if (days <= 0) return 0.00001;
    return totalMined / (days * 24); // BTC per hour
  }

  String _formatBTC(double amount) {
    return amount.toStringAsFixed(18);
  }

  Future<void> _saveUserProfile() async {
    if (userProfile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile', jsonEncode(userProfile!.toJson()));
    }
  }

  Future<void> _loadChatHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('chat_history') ?? [];
    setState(() {
      messages.clear();
      for (var entry in history) {
        final parts = entry.split('::');
        if (parts.length == 2) {
          messages.add({'sender': parts[0], 'text': parts[1]});
        }
      }
    });
  }

  Future<void> _saveChatHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final history =
        messages.map((m) => "${m['sender']}::${m['text']}").toList();
    await prefs.setStringList('chat_history', history);
  }

  void _setTypingStatus(bool isTyping) {
    if (mounted) {
      setState(() {
        _isTyping = isTyping;
      });
    }
  }

  Future<String> _getBotResponse(String userInput) async {
    if (userProfile == null) return 'Still initializing...';

    _setTypingStatus(true);
    userInput = userInput.toLowerCase();
    final name = userProfile!.getDisplayName();

    // Add a random delay to simulate thinking
    final delay = Duration(milliseconds: _random.nextInt(500) + 500);
    await Future.delayed(delay);
    _setTypingStatus(false);

    if (_isGreeting(userInput)) {
      final greetings = _getContextualGreeting();
      return '${greetings[_random.nextInt(greetings.length)]}\n\n'
          '${_getWalletSummary()}';
    }

    if (_isBalanceQuery(userInput)) {
      return 'Hey $name! Here\'s your up-to-date mining status:\n\n'
          '${_getWalletSummary()}\n\n'
          'Would you like some tips on increasing your mining speed?';
    }

    if (_isTransactionQuery(userInput)) {
      return _handleTransactionQuery(userInput);
    }

    if (_isRedemptionQuery(userInput)) {
      return _handleRedemptionQuery(userInput);
    }

    return '${acknowledgements[_random.nextInt(acknowledgements.length)]} '
        'I\'m here to help with your mining journey, $name!\n\n'
        'You can ask me about:\n'
        '• Your rewards and current balance\n'
        '• Redemption options and tracking\n'
        '• Boosting your mining speed\n'
        '• Transaction history and stats\n\n'
        'What would you like to know?';
  }

  String _getWalletSummary() {
    if (userProfile == null) return '';

    final btcPrice = _walletProvider.btcPrice;
    final usdBalance = userProfile!.walletBalance * btcPrice;

    return 'Your Mining Stats 📊\n\n'
        '• Current Balance: ${_formatBTC(userProfile!.walletBalance)} BTC '
        '(≈\$${usdBalance.toStringAsFixed(2)})\n'
        '• Total Mined: ${_formatBTC(userProfile!.totalMined)} BTC\n'
        '• Total Redeemed: ${_formatBTC(userProfile!.totalRedeemed)} BTC\n'
        '• Mining Rate: ${_formatBTC(userProfile!.miningRate)} BTC/hour\n'
        '• Days Mining: ${userProfile!.getDaysActive()} days\n\n'
        '${_getProgressMessage()}';
  }

  String _getProgressMessage() {
    if (userProfile == null) return '';
    final progress = userProfile!.walletBalance / 0.000000000000000001 * 100;
    if (progress < 25) {
      return 'Keep playing! You\'re making steady progress. 🌱';
    } else if (progress < 50) {
      return 'You\'re getting there! Keep up the great work! 🚀';
    } else if (progress < 75) {
      return 'Almost halfway to your first redemption! 💪';
    } else if (progress < 100) {
      return 'You\'re so close to reaching the redemption threshold! 🎯';
    } else {
      return 'Congratulations! You can request reward redemption now! 🎉';
    }
  }

  List<String> _getContextualGreeting() {
    if (userProfile == null) return ['Hello!'];

    final hour = DateTime.now().hour;
    final name = userProfile!.getDisplayName();

    if (hour < 12) {
      return [
        'Good morning, $name! How can I help you today?',
        'Morning, $name! Ready to check your mining progress?',
        'Rise and shine, $name! How\'s the mining going?'
      ];
    } else if (hour < 17) {
      return [
        'Good afternoon, $name! Need help with anything?',
        'Hey $name! How\'s your mining journey going?',
        'Afternoon, $name! Ready to check your rewards?'
      ];
    } else {
      return [
        'Good evening, $name! How can I assist you?',
        'Evening, $name! Let\'s check your mining progress!',
        'Hi $name! Need help with your evening mining?'
      ];
    }
  }

  bool _isGreeting(String input) {
    final greetingWords = ['hi', 'hello', 'hey', 'greetings', 'good'];
    return greetingWords.any((word) => input.contains(word));
  }

  bool _isBalanceQuery(String input) {
    final balanceWords = ['balance', 'wallet', 'amount', 'how much'];
    return balanceWords.any((word) => input.contains(word));
  }

  bool _isTransactionQuery(String input) {
    final transactionWords = ['transaction', 'history', 'recent', 'activity'];
    return transactionWords.any((word) => input.contains(word));
  }

  bool _isRedemptionQuery(String input) {
    final redemptionWords = [
      'redeem',
      'redemption',
      'track#',
      'status#',
      'track redemption',
      'redemption status',
      'payment',
      'request redemption',
      'pending redemptions',
      'redemption history',
      'cancel redemption',
      'redemption limit',
      'redemption fee',
      'redemption address',
      'redemption info',
      'all redemptions'
    ];
    return redemptionWords
        .any((word) => input.toLowerCase().contains(word.toLowerCase()));
  }

  String _handleTransactionQuery(String input) {
    if (userProfile == null) return 'Still initializing...';
    final name = userProfile!.getDisplayName();

    final transactions = _walletProvider.transactions;
    if (transactions.isEmpty) {
      return 'Hey $name! I see you\'re new to mining!\n\n'
          'Start your journey by letting your miner run, and you\'ll see your earnings appear here.\n\n'
          'Need help getting started?';
    }

    final recentTransactions = transactions.take(5);
    var response = 'Here are your recent mining activities, $name:\n\n';

    for (var tx in recentTransactions) {
      response += '${tx.type.toUpperCase()}\n'
          '• Amount: ${_formatBTC(tx.amount.abs())} BTC\n'
          '• When: ${DateFormat('MMM dd, HH:mm').format(tx.timestamp)}\n'
          '• ${tx.description}\n\n';
    }

    response +=
        '${_getProgressMessage()}\n\nNeed help optimizing your mining, $name?';

    return response;
  }

  Future<String> _handleRedemptionQuery(String userInput) async {
    if (userProfile == null) return 'Still initializing...';
    final name = userProfile!.getDisplayName();
    final balance = _walletProvider.btcBalance;

    // Check if this is a status check query
    if (userInput.toLowerCase().contains('status#') ||
        userInput.toLowerCase().contains('track#')) {
      // Extract redemption ID number
      final idMatch = RegExp(r'#(\d+)').firstMatch(userInput);
      if (idMatch != null) {
        final redemptionId = idMatch.group(1);
        return _getRedemptionStatus(redemptionId!, name);
      }
    }

    if (userInput.toLowerCase().contains('track redemption') ||
        userInput.toLowerCase().contains('redemption status')) {
      return 'To check your redemption status, please provide your redemption ID in this format:\n'
          'status#123 or track#123\n\n'
          'For example: "status#1" to check redemption #1';
    }

    if (userInput.toLowerCase().startsWith('redeem')) {
      if (balance < 0.000000000000000001) {
        return 'I\'m sorry, $name. Your balance is below the minimum redemption amount.\n\n'
            'Minimum needed: 0.000000000000000001 BTC\n'
            'Your balance: ${_formatBTC(balance)} BTC\n\n'
            '${_getProgressMessage()}\n'
            'Keep collecting rewards to reach the minimum redemption request amount! 💪';
      }

      // Generate a new redemption ID
      final redemptionId = _generateRedemptionId();
      _saveRedemptionRequest(redemptionId);

      return 'Great news, $name! I\'ve initiated your redemption request.\n\n'
          '• Amount: ${_formatBTC(balance)} BTC\n'
          '• Redemption ID: #$redemptionId\n\n'
          'Your redemption is now processing. This typically takes up to 48 hours.\n'
          'You can check the status anytime by sending:\n'
          'status#$redemptionId\n\n'
          'Need anything else?';
    }
    if (userInput.toLowerCase().contains('redemption history') ||
        userInput.toLowerCase().contains('all redemptions')) {
      return _getRedemptionHistory(name);
    }

    if (userInput.toLowerCase().contains('pending redemptions')) {
      return _getPendingRedemptions(name);
    }

    if (userInput.toLowerCase().contains('redemption limit')) {
      return 'Here are the redemption limits, $name:\n\n'
          '• Minimum redemption: 0.000000000000000001 BTC\n'
          '• Maximum redemption: No limit\n'
          '• Daily redemption limit: No limit\n'
          '• Your available balance: ${_formatBTC(balance)} BTC\n\n'
          'Need help with making a redemption?';
    }

    if (userInput.toLowerCase().contains('redemption fee')) {
      return 'Good news, $name! We currently charge:\n\n'
          '• 0% redemption fee\n'
          '• No transaction fees\n'
          '• No hidden charges\n\n'
          'Would you like to make a redemption now?';
    }

    if (userInput.toLowerCase().contains('cancel redemption')) {
      return 'To cancel a redemption, please provide the redemption ID in this format:\n'
          'cancel#123\n\n'
          'Note: You can only cancel pending redemptions that are less than 1 hour old.';
    }

    if (userInput.toLowerCase().contains('redemption info') ||
        userInput.toLowerCase().contains('redemption address')) {
      return 'Here\'s what you need to know about redemptions, $name:\n\n'
          '• Minimum amount: 0.000000000000000001 BTC\n'
          '• Processing time: Up to 48 hours\n'
          '• Fee: 0%\n'
          '• Available balance: ${_formatBTC(balance)} BTC\n\n'
          'To redeem:\n'
          '1. Type "redeem" to start\n'
          '2. Enter your BTC address\n'
          '3. Confirm the transaction\n\n'
          'Would you like to start a redemption now?';
    }

    return 'Hi $name! How can I help you with redemptions?\n\n'
        '• Type "redeem" to start a new redemption\n'
        '• Type "status#ID" to check an existing redemption\n'
        '• Type "redemption history" to see all your redemptions\n'
        '• Type "pending redemptions" to see processing redemptions\n'
        '• Type "redemption info" for fees and limits\n'
        '• Type "cancel redemption" to cancel a pending redemption\n\n'
        'Your current balance: ${_formatBTC(balance)} BTC\n\n'
        '${_getProgressMessage()}';
  }

  Future<String> _getRedemptionStatus(String redemptionId, String name) async {
    final status = await _retrieveRedemptionStatus(redemptionId);
    if (status == null) {
      return 'I\'m sorry, $name. I couldn\'t find a redemption with ID #$redemptionId.\n'
          'Please make sure you\'ve entered the correct redemption ID.\n\n'
          'Need help with something else?';
    }

    final amount = double.tryParse(status['amount'] ?? '0') ?? 0.0;
    return 'Here\'s the status of your redemption #$redemptionId, $name:\n\n'
        '• Status: ${status['status']}\n'
        '• Amount: ${_formatBTC(amount)} BTC\n'
        '• Requested: ${status['timestamp']}\n\n'
        'Please allow up to 48 hours for processing.\n'
        'Need anything else?';
  }

  int _generateRedemptionId() {
    return DateTime.now().millisecondsSinceEpoch % 10000;
  }

  Future<void> _saveRedemptionRequest(int redemptionId) async {
    final prefs = await SharedPreferences.getInstance();
    final redemptions = prefs.getStringList('redemptions') ?? [];

    final redemption = {
      'id': redemptionId.toString(),
      'amount': _walletProvider.btcBalance.toString(),
      'status': 'Processing',
      'timestamp': DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())
    };

    redemptions.add(jsonEncode(redemption));
    await prefs.setStringList('redemptions', redemptions);
  }

  Future<Map<String, String>?> _retrieveRedemptionStatus(
      String redemptionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final redemptions = prefs.getStringList('redemptions') ?? [];

      for (var r in redemptions) {
        final redemption = jsonDecode(r) as Map<String, dynamic>;
        if (redemption['id'] == redemptionId) {
          return Map<String, String>.from(redemption);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleUserInput(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add({'sender': 'user', 'text': text});
      _controller.clear();
    });

    final response = await _getBotResponse(text);
    if (mounted) {
      setState(() {
        messages.add({'sender': 'bot', 'text': response});
      });
      await _saveChatHistory();
    }
  }

  Future<void> _initializeUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString('user_profile');

    if (profileJson != null) {
      setState(() {
        userProfile = UserProfile.fromJson(jsonDecode(profileJson));
      });
    } else {
      // Initialize with default values
      setState(() {
        userProfile = UserProfile(
          name: 'User',
          walletBalance: _walletProvider.btcBalance,
          totalMined: _walletProvider.totalEarned,
          totalRedeemed: _walletProvider.totalRedeemed,
          miningRate: 0.00001,
        );
      });
      await _saveUserProfile();
    }
  }

  Future<String> _getRedemptionHistory(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final redemptions = prefs.getStringList('redemptions') ?? [];

    if (redemptions.isEmpty) {
      return 'You haven\'t made any redemptions yet, $name.\n\n'
          'Your current balance: ${_formatBTC(_walletProvider.btcBalance)} BTC\n'
          'Would you like to make your first redemption?';
    }

    var response = 'Here\'s your redemption history, $name:\n\n';
    final sortedRedemptions = redemptions
        .map((r) => jsonDecode(r) as Map<String, dynamic>)
        .toList()
      ..sort((a, b) => DateTime.parse(b['timestamp'])
          .compareTo(DateTime.parse(a['timestamp'])));

    for (var redemption in sortedRedemptions.take(5)) {
      final amount = double.tryParse(redemption['amount'] ?? '0') ?? 0.0;
      response += '📤 Redemption #${redemption['id']}\n'
          '• Amount: ${_formatBTC(amount)} BTC\n'
          '• Status: ${redemption['status']}\n'
          '• Date: ${redemption['timestamp']}\n\n';
    }

    if (sortedRedemptions.length > 5) {
      response +=
          '... and ${sortedRedemptions.length - 5} more redemptions.\n\n';
    }

    response += 'Need help with anything else?';
    return response;
  }

  Future<String> _getPendingRedemptions(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final redemptions = prefs.getStringList('redemptions') ?? [];

    final pendingRedemptions = redemptions
        .map((r) => jsonDecode(r) as Map<String, dynamic>)
        .where((r) => r['status'].toString().toLowerCase() == 'processing')
        .toList();

    if (pendingRedemptions.isEmpty) {
      return 'You don\'t have any pending redemptions, $name.\n\n'
          'Your current balance: ${_formatBTC(_walletProvider.btcBalance)} BTC\n'
          'Would you like to make a redemption?';
    }

    var response = 'Here are your pending redemptions, $name:\n\n';

    for (var redemption in pendingRedemptions) {
      final amount = double.tryParse(redemption['amount'] ?? '0') ?? 0.0;
      final timestamp = DateTime.parse(redemption['timestamp']);
      final hoursAgo = DateTime.now().difference(timestamp).inHours;

      response += '⏳ Redemption #${redemption['id']}\n'
          '• Amount: ${_formatBTC(amount)} BTC\n'
          '• Requested: ${redemption['timestamp']}\n'
          '• Time in processing: $hoursAgo hours\n'
          '• Estimated completion: ${48 - hoursAgo} hours remaining\n\n';
    }

    response += 'Redemptions typically complete within 48 hours.\n'
        'You can check specific redemptions using status#ID\n\n'
        'Need anything else?';

    return response;
  }

  Future<void> _clearChat() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history');
    if (mounted) {
      setState(messages.clear);
      // Add welcome message after clearing
      _handleUserInput('hi');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mining Assistant'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Chat',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Chat History'),
                  content: const Text(
                      'Are you sure you want to clear all chat messages?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearChat();
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUser = message['sender'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message['text']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _handleUserInput,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _handleUserInput(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
