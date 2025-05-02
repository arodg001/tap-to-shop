import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img; // Use prefix
import 'package:shopapp/models/match_result_model.dart';

// --- Configuration --- 
// IMPORTANT: Replace with your actual API key. DO NOT commit this key to Git.
// Consider using flutter_dotenv or similar for better key management.
const String _apiKey = 'YOUR_API_KEY'; 
const String _apiEndpoint = 'https://vision.googleapis.com/v1/images:annotate';

// IMPORTANT: Replace with your Product Search configuration
const String _gcpProjectId = 'YOUR_GCP_PROJECT_ID';
const String _gcpLocation = 'YOUR_GCP_LOCATION'; // e.g., 'us-west1'
const String _productSetId = 'YOUR_PRODUCT_SET_ID';
// --- End Configuration ---

class VisionService {

  // Calls Cloud Vision Product Search API
  Future<List<MatchResultModel>> identifyProducts(String imagePath) async {
    print('[VisionService] Identifying products for image: $imagePath');
    if (_apiKey == 'YOUR_API_KEY') {
       throw Exception('API Key not set in VisionService. Please replace YOUR_API_KEY.');
    }
    if (_gcpProjectId == 'YOUR_GCP_PROJECT_ID' || _gcpLocation == 'YOUR_GCP_LOCATION' || _productSetId == 'YOUR_PRODUCT_SET_ID') {
       throw Exception('GCP Product Search configuration not set in VisionService.');
    }

    try {
      // 1. Read image bytes
      final File imageFile = File(imagePath);
      Uint8List imageBytes = await imageFile.readAsBytes();

      // Optional: Resize image if it's too large for the API (e.g., > 20MB)
      // Or handle potential Vision API size limits
      // final image = img.decodeImage(imageBytes);
      // if (image != null && image.width > 1024) { // Example resize condition
      //   final resized = img.copyResize(image, width: 1024);
      //   imageBytes = Uint8List.fromList(img.encodeJpg(resized));
      // }

      // 2. Encode image to base64
      String base64Image = base64Encode(imageBytes);

      // 3. Construct the request body
      final Map<String, dynamic> requestBody = {
        'requests': [
          {
            'image': {
              'content': base64Image,
            },
            'features': [
              {
                'type': 'PRODUCT_SEARCH',
                'maxResults': 10, // Adjust as needed
              }
            ],
            'imageContext': {
              'productSearchParams': {
                'productSet': 'projects/$_gcpProjectId/locations/$_gcpLocation/productSets/$_productSetId',
                // Add product categories or filters if needed
                // 'productCategories': ['apparel'],
                // 'filter': 'style=womens'
              }
            }
          }
        ]
      };

      // 4. Make the HTTP POST request
      final response = await http.post(
        Uri.parse('$_apiEndpoint?key=$_apiKey'), // Send API key as query param
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // 5. Process the response
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print('[VisionService] Raw API Response: $responseData');

        final List<dynamic> responses = responseData['responses'] ?? [];
        if (responses.isNotEmpty) {
           final productSearchResults = responses[0]['productSearchResults'];
           if (productSearchResults != null && productSearchResults['results'] != null) {
              final List<dynamic> results = productSearchResults['results'];
              final List<MatchResultModel> matches = results.map((result) {
                  final product = result['product'];
                  // Extract product ID - format is projects/.../products/PRODUCT_ID
                  final String fullProductId = product['name'] ?? '';
                  final String productId = fullProductId.split('/').last;

                  return MatchResultModel(
                    // Generate a client-side result ID or use backend-generated one later
                    resultId: 'client_${productId}_${result['score']?.toStringAsFixed(4) ?? '0'}',
                    sessionId: 'client-session-${DateTime.now().millisecondsSinceEpoch}', // Use a dummy session ID for now
                    productId: productId,
                    score: (result['score'] as num?)?.toDouble() ?? 0.0,
                    timestamp: DateTime.now(), // Timestamp of client-side result processing
                  );
              }).toList();

              // Sort by score descending (optional)
              matches.sort((a, b) => b.score.compareTo(a.score));
              print('[VisionService] Found ${matches.length} product matches.');
              return matches;
           }
        }
        print('[VisionService] No product results found in API response.');
        return []; // No results found
      } else {
        print('[VisionService] API Error: ${response.statusCode}\n${response.body}');
        throw Exception('Failed to identify products (Status ${response.statusCode})');
      }
    } catch (e, stackTrace) {
      print('[VisionService] Error identifying products: $e\n$stackTrace');
      throw Exception('An error occurred during product identification: $e');
    }
  }

  // Note: Original identifyObjectsAndProducts returning sessionId is removed
  // as we now return results directly from the client-side call.
}

// Provider for VisionService
final visionServiceProvider = Provider<VisionService>((ref) {
  return VisionService();
}); 