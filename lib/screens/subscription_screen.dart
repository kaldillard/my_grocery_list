// lib/screens/subscription_screen.dart

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
  bool _isLoading = true;
  Subscription? _currentSubscription;
  List<PricingConfig> _pricingOptions = [];
  SubscriptionTier? _selectedTier;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load current subscription if exists
      // if (widget.familyId != null) {
      //   final sub = await supabaseService.getSubscription(widget.familyId!);
      //   _currentSubscription = sub != null ? Subscription.fromJson(sub) : null;
      // }

      // Load current pricing
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
          maxLists: null, // unlimited
          effectiveFrom: DateTime.utc(2027, 1, 1),
        ),
        PricingConfig(
          tier: SubscriptionTier.family,
          basePrice: 4.99,
          perAdditionalUserPrice: 0.99,
          maxBaseUsers: 5,
          maxLists: null, // unlimited
          effectiveFrom: DateTime.utc(2027, 1, 1),
        ),
      ];
    } catch (e) {
      print('Error loading subscription data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _subscribe(SubscriptionTier tier) async {
    setState(() => _isLoading = true);

    try {
      // Call Supabase Edge Function
      final response = await Supabase.instance.client.functions.invoke(
        'create-checkout-session',
        body: {
          'tier': tier.name,
          'family_id': widget.familyId ?? '',
          'user_id': Supabase.instance.client.auth.currentUser?.id,
        },
      );

      if (response.data != null && response.data['url'] != null) {
        // Open Stripe Checkout in browser
        final url = Uri.parse(response.data['url']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Plan')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    const Text(
                      'Select the plan that fits your needs',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
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

                    // Pricing cards
                    ..._pricingOptions.map(
                      (pricing) => _buildPricingCard(pricing),
                    ),

                    const SizedBox(height: 32),

                    // Grandfather clause info
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
            // Tier name and badge
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

            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFree ? 'Free' : '\${pricing.basePrice.toStringAsFixed(2)}',
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

            // Features
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
            if (pricing.tier == SubscriptionTier.family) ...[
              _buildFeature(
                '\${pricing.perAdditionalUserPrice!.toStringAsFixed(2)}/month per additional user',
              ),
            ],
            _buildFeature('Real-time sync'),
            _buildFeature('All features'),

            const SizedBox(height: 24),

            // Action button
            if (!isCurrentPlan)
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

//   @override
//   void initState() {
//     super.initState();
//     _loadSubscription();
//   }

//   Future<void> _loadSubscription() async {
//     setState(() => _isLoading = true);

//     // TODO: Load subscription from Supabase
//     // final sub = await supabaseService.getSubscription(widget.familyId);

//     setState(() {
//       // _subscription = sub;
//       _isLoading = false;
//     });
//   }

//   Future<void> _startSubscription() async {
//     setState(() => _isLoading = true);

//     try {
//       // 1. Create Stripe customer
//       final customer = await StripeService.createCustomer(
//         email: 'user@example.com', // Get from auth
//         name: 'Family Name', // Get from family
//       );

//       // 2. Create payment intent
//       final paymentIntent = await StripeService.createPaymentIntent(
//         memberCount: widget.memberCount,
//         customerId: customer['id'],
//       );

//       // 3. Initialize payment sheet
//       await StripeService.initPaymentSheet(
//         paymentIntentClientSecret: paymentIntent['client_secret'],
//         customerId: customer['id'],
//         ephemeralKey: customer['ephemeral_key'],
//       );

//       // 4. Present payment sheet
//       await StripeService.presentPaymentSheet();

//       // 5. Create subscription
//       final subscription = await StripeService.createSubscription(
//         customerId: customer['id'],
//         memberCount: widget.memberCount,
//       );

//       // 6. Save subscription to Supabase
//       // await supabaseService.saveSubscription(widget.familyId, subscription);

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Subscription activated!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//         Navigator.pop(context);
//       }
//     } on StripeException catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Payment failed: ${e.error.localizedMessage}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final monthlyCost = StripeService.calculateMonthlyCost(widget.memberCount);
//     final hasAdditionalUsers =
//         widget.memberCount > StripeService.maxBasePlanUsers;
//     final additionalUsers =
//         hasAdditionalUsers
//             ? widget.memberCount - StripeService.maxBasePlanUsers
//             : 0;

//     return Scaffold(
//       appBar: AppBar(title: const Text('Subscription')),
//       body:
//           _isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : SingleChildScrollView(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     // Pricing Card
//                     Card(
//                       elevation: 4,
//                       child: Padding(
//                         padding: const EdgeInsets.all(24),
//                         child: Column(
//                           children: [
//                             const Icon(
//                               Icons.family_restroom,
//                               size: 64,
//                               color: Colors.green,
//                             ),
//                             const SizedBox(height: 16),
//                             const Text(
//                               'Family Plan',
//                               style: TextStyle(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Text(
//                               '\$${monthlyCost.toStringAsFixed(2)}/month',
//                               style: const TextStyle(
//                                 fontSize: 36,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.green,
//                               ),
//                             ),
//                             const SizedBox(height: 24),
//                             const Divider(),
//                             const SizedBox(height: 16),

//                             // Pricing breakdown
//                             _buildPriceRow(
//                               'Base plan (up to 5 users)',
//                               '\$${StripeService.familyPlanPrice.toStringAsFixed(2)}',
//                             ),
//                             if (hasAdditionalUsers) ...[
//                               const SizedBox(height: 8),
//                               _buildPriceRow(
//                                 '$additionalUsers additional user${additionalUsers > 1 ? 's' : ''}',
//                                 '\$${(additionalUsers * StripeService.additionalUserPrice).toStringAsFixed(2)}',
//                               ),
//                             ],
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 24),

//                     // Features
//                     Card(
//                       child: Padding(
//                         padding: const EdgeInsets.all(16),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'What\'s included:',
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             const SizedBox(height: 16),
//                             _buildFeature('Unlimited grocery lists'),
//                             _buildFeature('Real-time sync across all devices'),
//                             _buildFeature('Share lists with family members'),
//                             _buildFeature('Up to ${widget.memberCount} users'),
//                             _buildFeature('Priority support'),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 24),

//                     // Subscribe button
//                     if (_subscription == null)
//                       ElevatedButton(
//                         onPressed: _isLoading ? null : _startSubscription,
//                         style: ElevatedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           backgroundColor: Colors.green,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                         child: const Text(
//                           'Subscribe Now',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),

//                     const SizedBox(height: 16),

//                     // Fine print
//                     Text(
//                       'Cancel anytime. \$${StripeService.familyPlanPrice.toStringAsFixed(2)}/month for up to 5 users, plus \$${StripeService.additionalUserPrice.toStringAsFixed(2)}/month for each additional user.',
//                       style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//     );
//   }

//   Widget _buildPriceRow(String label, String price) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(label),
//         Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
//       ],
//     );
//   }

//   Widget _buildFeature(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Row(
//         children: [
//           const Icon(Icons.check_circle, color: Colors.green, size: 20),
//           const SizedBox(width: 12),
//           Expanded(child: Text(text)),
//         ],
//       ),
//     );
//   }
// }
