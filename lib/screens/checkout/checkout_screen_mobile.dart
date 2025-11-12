import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/platform_service.dart';

class CheckoutScreenMobile extends StatelessWidget {
  final String tier;
  final String familyId;

  const CheckoutScreenMobile({
    super.key,
    required this.tier,
    required this.familyId,
  });

  Future<void> _openWebCheckout() async {
    final url = PlatformService.getCheckoutUrl(tier, familyId);
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Opens in browser
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscribe')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.public, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Continue in Browser',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'To subscribe, you\'ll be redirected to our secure\npayment page in your browser.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openWebCheckout,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Continue to Payment'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
