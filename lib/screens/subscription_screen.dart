// lib/screens/subscription_screen.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_grocery_list/services/stripe_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/subscription.dart';
import '../services/supabase_service.dart';

class SubscriptionScreen extends StatefulWidget {
  final String? familyId;

  const SubscriptionScreen({super.key, this.familyId});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool get _canShowSubscription {
    if (kIsWeb) return true;
    try {
      return !Platform.isIOS;
    } catch (e) {
      return true;
    }
  }

  bool _isLoading = true;
  String? _error;
  Subscription? _currentSubscription;
  List<PricingConfig> _pricingOptions = [];
  SubscriptionTier? _selectedTier;

  @override
  void initState() {
    super.initState();
    print('SubscriptionScreen - initState called');
    print('Family ID: ${widget.familyId}');
    _loadData();
  }

  Future<void> _loadData() async {
    print('SubscriptionScreen - Loading data...');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _pricingOptions = [
        PricingConfig(
          tier: SubscriptionTier.free,
          basePrice: 0.00,
          maxBaseUsers: 1,
          maxLists: 1,
          effectiveFrom: DateTime.utc(2027, 1, 1),
        ),
        PricingConfig(
          tier: SubscriptionTier.pro,
          basePrice: 1.99,
          maxBaseUsers: 1,
          maxLists: null,
          effectiveFrom: DateTime.utc(2027, 1, 1),
        ),
        PricingConfig(
          tier: SubscriptionTier.family,
          basePrice: 4.99,
          perAdditionalUserPrice: 0.99,
          maxBaseUsers: 5,
          maxLists: null,
          effectiveFrom: DateTime.utc(2027, 1, 1),
        ),
      ];

      print(
        'SubscriptionScreen - Pricing options loaded: ${_pricingOptions.length}',
      );

      setState(() {
        _isLoading = false;
      });

      print('SubscriptionScreen - Data loaded successfully');
    } catch (e, stackTrace) {
      print('SubscriptionScreen - Error loading data: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _subscribe(SubscriptionTier tier) async {
    print('SubscriptionScreen - Subscribe called for tier: ${tier.name}');

    if (widget.familyId == null) {
      print('SubscriptionScreen - Error: No family ID');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No family selected'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      print('SubscriptionScreen - Calling Supabase function...');

      final response = await Supabase.instance.client.functions.invoke(
        'create-checkout-session',
        body: {
          'tier': tier.name,
          'family_id': widget.familyId ?? '',
          'user_id': Supabase.instance.client.auth.currentUser?.id,
        },
      );

      print('SubscriptionScreen - Response status: ${response.status}');
      print('SubscriptionScreen - Response data: ${response.data}');
      print(
        'SubscriptionScreen - Response data type: ${response.data.runtimeType}',
      );

      if (response.status != 200) {
        throw Exception(
          'Function returned status ${response.status}: ${response.data}',
        );
      }

      // Handle both 'url' and 'sessionId' response formats
      String? checkoutUrl;

      if (response.data != null) {
        print(
          'SubscriptionScreen - Checking response data keys: ${response.data is Map ? (response.data as Map).keys : "Not a map"}',
        );

        if (response.data['url'] != null) {
          // Direct URL provided
          checkoutUrl = response.data['url'];
          print('SubscriptionScreen - Found URL in response: $checkoutUrl');
        } else if (response.data['sessionId'] != null) {
          // Session ID provided, construct URL
          final sessionId = response.data['sessionId'];
          checkoutUrl = 'https://checkout.stripe.com/c/pay/$sessionId';
          print(
            'SubscriptionScreen - Constructed URL from sessionId: $checkoutUrl',
          );
        } else if (response.data['id'] != null) {
          // Sometimes Stripe returns just 'id' instead of 'sessionId'
          final sessionId = response.data['id'];
          checkoutUrl = 'https://checkout.stripe.com/c/pay/$sessionId';
          print('SubscriptionScreen - Constructed URL from id: $checkoutUrl');
        }
      }

      if (checkoutUrl == null) {
        throw Exception(
          'No checkout URL or session ID in response. Keys: ${response.data is Map ? (response.data as Map).keys : response.data}',
        );
      }

      // Validate URL has a scheme
      if (!checkoutUrl.startsWith('http://') &&
          !checkoutUrl.startsWith('https://')) {
        throw Exception('Invalid URL format (missing https://): $checkoutUrl');
      }

      print('SubscriptionScreen - Opening URL: $checkoutUrl');

      final url = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(url)) {
        final launched = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          throw Exception('Failed to launch URL');
        }
        print('SubscriptionScreen - URL launched successfully');
      } else {
        throw Exception('Cannot launch URL: $checkoutUrl');
      }
    } catch (e, stackTrace) {
      print('SubscriptionScreen - Error subscribing: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Error Details'),
                        content: SingleChildScrollView(
                          child: Text(e.toString()),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                );
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('SubscriptionScreen - Building UI');
    print('Loading: $_isLoading, Error: $_error');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        backgroundColor: Colors.green,
      ),
      body:
          _error != null
              ? _buildError()
              : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Select the plan that fits your needs',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Early adopter pricing - lock in these rates forever!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green[700],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          ..._pricingOptions.map((pricing) => _buildPricingCard(pricing)),

          const SizedBox(height: 32),

          Card(
            color: Colors.amber[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[700]),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Early Adopter Benefit',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Subscribe now and lock in these prices forever! '
                    'Prices will increase for new users after one year, '
                    'but your rate stays the same as long as you remain subscribed.',
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(PricingConfig pricing) {
    final isCurrentPlan = _currentSubscription?.tier == pricing.tier;
    final isFree = pricing.tier == SubscriptionTier.free;

    return Card(
      elevation: isCurrentPlan ? 8 : 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            isCurrentPlan
                ? const BorderSide(color: Colors.green, width: 2)
                : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pricing.tier.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Current',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFree ? 'Free' : '\$${pricing.basePrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (!isFree)
                  const Padding(
                    padding: EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      '/month',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            _buildFeature(
              pricing.maxLists == null
                  ? 'Unlimited lists'
                  : '${pricing.maxLists} list',
            ),
            _buildFeature(
              pricing.tier == SubscriptionTier.family
                  ? 'Up to ${pricing.maxBaseUsers} users'
                  : '${pricing.maxBaseUsers} user',
            ),
            if (pricing.tier == SubscriptionTier.family)
              _buildFeature(
                '\$${pricing.perAdditionalUserPrice!.toStringAsFixed(2)}/month per additional user',
              ),
            _buildFeature('Real-time sync'),
            _buildFeature('All features'),

            const SizedBox(height: 24),

            if (!isCurrentPlan && _canShowSubscription)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isFree ? null : () => _subscribe(pricing.tier),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: isFree ? Colors.grey : Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isFree
                        ? 'Current Plan'
                        : 'Upgrade to ${pricing.tier.displayName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
