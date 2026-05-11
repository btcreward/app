import 'package:flutter/material.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Data')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(onPressed: () {}, child: const Text('Export Users')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Export Wallets'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Export Transactions'),
            ),
          ],
        ),
      ),
    );
  }
}
