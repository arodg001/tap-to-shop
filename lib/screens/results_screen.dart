import 'package:flutter/material.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.sessionId}); // Example: pass session ID

  final String sessionId; // ID to fetch results

  static const String routeName = '/results';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: Center(
        child: Text('Results Screen Placeholder for session: $sessionId'),
        // TODO: Fetch and display MatchResultModel and AffiliateLinkModel data
      ),
    );
  }
} 