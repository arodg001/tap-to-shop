import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopapp/models/affiliate_link_model.dart';
import 'package:shopapp/models/match_result_model.dart';
import 'package:url_launcher/url_launcher.dart';

// TODO: Replace with actual data fetching (e.g., from VisionService or a dedicated ResultsService)

// Simulated combined result data model for now
class DisplayResult {
  final MatchResultModel match;
  final AffiliateLinkModel? link;
  final String productImageUrl; // Placeholder for image URL from Vision Product Search

  DisplayResult({
    required this.match,
    this.link,
    required this.productImageUrl,
  });
}

// Provider to simulate fetching results for a session
final resultsProvider = FutureProvider.family<List<DisplayResult>, String>((ref, sessionId) async {
  print('Fetching results for session: $sessionId');
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 1500));

  // TODO: Replace with actual call to backend/service
  // final resultsData = await ref.read(visionServiceProvider).getResults(sessionId);

  // --- Mock Data --- 
  if (sessionId.contains('error')) { // Simulate error case
      throw Exception('Failed to fetch results from backend.');
  }
  final mockMatch1 = MatchResultModel(resultId: 'res1', sessionId: sessionId, productId: 'prod123', score: 0.85, timestamp: DateTime.now());
  final mockLink1 = AffiliateLinkModel(linkId: 'aff1', productId: 'prod123', retailer: 'ExampleRetailer', urlTemplate: 'https://example.com/product/{productId}?tag=taptoshop', commission: 0.05);

   final mockMatch2 = MatchResultModel(resultId: 'res2', sessionId: sessionId, productId: 'prod456', score: 0.72, timestamp: DateTime.now().subtract(const Duration(seconds: 1)));
   // Simulate a match with no corresponding affiliate link

  return [
    DisplayResult(match: mockMatch1, link: mockLink1, productImageUrl: 'https://via.placeholder.com/150/92c952'), // Placeholder image
    DisplayResult(match: mockMatch2, link: null, productImageUrl: 'https://via.placeholder.com/150/771796'), // Placeholder image
  ];
  // --- End Mock Data ---
});

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key, required this.sessionId});

  final String sessionId;
  static const String routeName = '/results';

  // Helper to launch URL
  Future<void> _launchAffiliateUrl(BuildContext context, AffiliateLinkModel link) async {
    // Construct the final URL (simple substitution for this example)
    final urlString = link.urlTemplate.replaceAll('{productId}', link.productId);
    final uri = Uri.parse(urlString);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $urlString');
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Could not open link for ${link.retailer}')),
         );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsState = ref.watch(resultsProvider(sessionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: resultsState.when(
        data: (results) {
          if (results.isEmpty) {
            return const Center(child: Text('No products identified in this image.'));
          }
          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(
                         result.productImageUrl,
                         width: 80, height: 80, fit: BoxFit.cover,
                         errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 80),
                         loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const SizedBox(width: 80, height: 80, child: Center(child: CircularProgressIndicator()));
                         }
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Product ID: ${result.match.productId}', style: Theme.of(context).textTheme.titleMedium),
                            Text('Confidence: ${(result.match.score * 100).toStringAsFixed(1)}%'),
                            const SizedBox(height: 8),
                            if (result.link != null)
                              ElevatedButton.icon(
                                icon: const Icon(Icons.shopping_cart),
                                label: Text('Shop at ${result.link!.retailer}'),
                                onPressed: () => _launchAffiliateUrl(context, result.link!),
                              )
                            else
                              const Text('No affiliate link found.', style: TextStyle(fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading results: $error')),
      ),
    );
  }
} 