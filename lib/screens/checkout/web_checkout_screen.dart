// This screen only works on Flutter Web

import 'package:flutter/material.dart';
import 'package:my_grocery_list/models/subscription.dart';
import 'dart:html' as html;
import 'dart:js' as js;

class WebCheckoutScreen extends StatefulWidget {
  final SubscriptionTier tier;
  final String familyId;
  final String userId;

  const WebCheckoutScreen({
    Key? key,
    required this.tier,
    required this.familyId,
    required this.userId,
  }) : super(key: key);

  @override
  State<WebCheckoutScreen> createState() => _WebCheckoutScreenState();
}

class _WebCheckoutScreenState extends State<WebCheckoutScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStripe();
  }

  void _loadStripe() {
    // Load Stripe.js
    final script =
        html.ScriptElement()
          ..src = 'https://js.stripe.com/v3/'
          ..async = true;
    html.document.head!.append(script);
  }

  Future<void> _checkout() async {
    setState(() => _isLoading = true);

    try {
      // Call your backend to create checkout session
      final response = await _createCheckoutSession();

      if (response['sessionId'] != null) {
        // Redirect to Stripe Checkout
        final stripe = js.context['Stripe']?.callMethod('call', [
          js.context,
          'YOUR_STRIPE_PUBLISHABLE_KEY',
        ]);

        await stripe?.callMethod('redirectToCheckout', [
          js.JsObject.jsify({'sessionId': response['sessionId']}),
        ]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _createCheckoutSession() async {
    // TODO: Call Supabase Edge Function to create Stripe Checkout Session
    // This keeps your Stripe secret key secure on the backend

    // Example:
    // final response = await supabase.functions.invoke(
    //   'create-checkout-session',
    //   body: {
    //     'tier': widget.tier.name,
    //     'family_id': widget.familyId,
    //     'user_id': widget.userId,
    //   },
    // );

    return {'sessionId': 'cs_test_xxx'};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Center(
        child:
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _checkout,
                  child: const Text('Proceed to Payment'),
                ),
      ),
    );
  }
}
