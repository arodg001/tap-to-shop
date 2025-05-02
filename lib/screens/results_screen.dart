import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopapp/features/capture/screens/capture_screen.dart'; // Import for visionResultsProvider
import 'package:shopapp/models/affiliate_link_model.dart';
import 'package:shopapp/models/match_result_model.dart';
import 'package:url_launcher/url_launcher.dart';

// TODO: Fetch actual AffiliateLinkModel data based on MatchResultModel.productId
// This likely requires a DatabaseService method and potentially another provider.

// Placeholder Affiliate Link fetcher (simulated)
final affiliateLinkProvider = FutureProvider.family<AffiliateLinkModel?, String>((ref, productId) async {
   print('Simulating fetch for affiliate link for product: $productId');
   await Future.delayed(const Duration(milliseconds: 200));
   // Simulate finding a link only for prod123
   if(productId == 'prod123') {
     return AffiliateLinkModel(linkId: 'aff1', productId: productId, retailer: 'ExampleRetailer', urlTemplate: 'https://example.com/product/{productId}?tag=taptoshop', commission: 0.05);
   }
   return null;
});

class ResultsScreen extends ConsumerWidget {
  // No longer takes sessionId in constructor
  const ResultsScreen({super.key}); 

  static const String routeName = '/results';

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
    // Read results directly from the provider populated by CaptureScreen
    final results = ref.watch(visionResultsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: _buildBody(context, results),
    );
  }

  Widget _buildBody(BuildContext context, List<MatchResultModel>? results) {
     if (results == null) {
       // Should ideally not happen if navigated correctly, but handle defensively
       return const Center(child: Text('No results data available.'));
     }
     if (results.isEmpty) {
       return const Center(child: Text('No products identified in this image.'));
     }

     // Display the list of MatchResultModel
     return ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final matchResult = results[index];
          return _buildResultCard(context, matchResult);
        },
     );
  }

  // Widget to build a card for a single MatchResultModel
  // It uses another Consumer to fetch the affiliate link for that specific product
  Widget _buildResultCard(BuildContext context, MatchResultModel matchResult) {
     return Consumer( // Use Consumer to watch the affiliateLinkProvider
       builder: (context, ref, child) {
         final affiliateLinkState = ref.watch(affiliateLinkProvider(matchResult.productId));

         return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   // TODO: Get actual product image URL (maybe from Product Search response or separate lookup)
                   Image.network(
                     'https://via.placeholder.com/80/0000FF/FFFFFF?text=${matchResult.productId.substring(0,3)}', // Placeholder Image
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
                         Text('Product ID: ${matchResult.productId}', style: Theme.of(context).textTheme.titleMedium),
                         Text('Confidence: ${(matchResult.score * 100).toStringAsFixed(1)}%'),
                         const SizedBox(height: 8),
                         // Display affiliate link based on its state
                         affiliateLinkState.when(
                           data: (link) {
                              if (link != null) {
                                 return ElevatedButton.icon(
                                    icon: const Icon(Icons.shopping_cart),
                                    label: Text('Shop at ${link.retailer}'),
                                    onPressed: () => _launchAffiliateUrl(context, link),
                                 );
                              } else {
                                 return const Text('No affiliate link found.', style: TextStyle(fontStyle: FontStyle.italic));
                              }
                           },
                           loading: () => const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                           error: (err, stack) => Text('Error loading link: $err', style: const TextStyle(color: Colors.red)),
                         ),
                       ],
                     ),
                   ),
                 ],
               ),
            ),
         );
       },
     );
  }

} 