import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class StripeService {
  static const String familyPlanPriceId = 'price_1SSVmTGWGIcBRuzmDh4N9pn7';
  static const String proPlanPriceId = 'price_1SSVfGGWGIcBRuzmjhJBUAMV';
  static const String additionalUserPriceId = 'price_1SSVpiGWGIcBRuzmknvlmRtd';

  static const double familyPlanBasePrice = 4.99;
  static const double proPlanPrice = 1.99;
  static const double pricePerAdditionalUser = 0.99;

  static const int familyBaseUsersIncluded = 5; // First 5 users included
  static const int proMaxUsers = 1; // Pro is only 1 user

  /// Calculate total monthly cost based on member count and tier
  static double calculateMonthlyCost(int memberCount, String tier) {
    if (tier == 'pro') {
      return proPlanPrice; // Always $1.99 for 1 user
    }

    if (tier == 'family') {
      if (memberCount <= familyBaseUsersIncluded) {
        // Up to 5 users: just base price
        return familyPlanBasePrice;
      }

      // More than 5 users: base + additional
      final additionalUsers = memberCount - familyBaseUsersIncluded;
      return familyPlanBasePrice + (additionalUsers * pricePerAdditionalUser);
    }

    return 0; // Free tier
  }

  /// Get pricing breakdown as a string
  static String getPricingBreakdown(int memberCount, String tier) {
    if (tier == 'pro') {
      return '\$${proPlanPrice.toStringAsFixed(2)}/month (1 user)';
    }

    if (tier == 'family') {
      if (memberCount <= familyBaseUsersIncluded) {
        return '\$${familyPlanBasePrice.toStringAsFixed(2)}/month (up to $familyBaseUsersIncluded users)';
      }

      final additionalUsers = memberCount - familyBaseUsersIncluded;
      final additionalCost = additionalUsers * pricePerAdditionalUser;
      final total = familyPlanBasePrice + additionalCost;

      return '\$${familyPlanBasePrice.toStringAsFixed(2)} base + \$${additionalCost.toStringAsFixed(2)} for $additionalUsers additional user${additionalUsers > 1 ? 's' : ''} = \$${total.toStringAsFixed(2)}/month';
    }

    return 'Free';
  }

  /// Create checkout session and redirect to Stripe
  static Future<void> createCheckoutSession({
    required String tier,
    required String familyId,
    required String userId,
    required BuildContext context,
  }) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'create-checkout-session',
        body: {'tier': tier, 'family_id': familyId, 'user_id': userId},
      );

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;
        final sessionId = data['sessionId'] as String;

        final url = Uri.parse('https://checkout.stripe.com/c/pay/$sessionId');

        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not launch checkout');
        }
      } else {
        throw Exception('Failed to create checkout session: ${response.data}');
      }
    } catch (e) {
      print('Error creating checkout session: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
      rethrow;
    }
  }

  /// Open customer portal for managing subscription
  static Future<void> openCustomerPortal({
    required String customerId,
    required BuildContext context,
  }) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'create-customer-portal',
        body: {'customerId': customerId},
      );

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;
        final portalUrl = Uri.parse(data['url'] as String);

        if (await canLaunchUrl(portalUrl)) {
          await launchUrl(portalUrl, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not launch portal');
        }
      } else {
        throw Exception('Failed to create portal session: ${response.data}');
      }
    } catch (e) {
      print('Error opening customer portal: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
      rethrow;
    }
  }

  /// Update subscription quantity when members are added/removed
  /// Only applies to family plan (Pro is fixed at 1 user)
  static Future<Map<String, dynamic>> updateSubscriptionQuantity({
    required String subscriptionId,
    required int memberCount,
  }) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'update-subscription-quantity',
        body: {'subscriptionId': subscriptionId, 'memberCount': memberCount},
      );

      if (response.status == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to update subscription: ${response.data}');
      }
    } catch (e) {
      print('Error updating subscription: $e');
      rethrow;
    }
  }

  /// Get subscription details from your database
  static Future<Map<String, dynamic>?> getSubscription(String familyId) async {
    try {
      final response =
          await Supabase.instance.client
              .from('subscriptions')
              .select()
              .eq('family_id', familyId)
              .maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching subscription: $e');
      return null;
    }
  }

  /// Check if family can add more members
  static Future<bool> canAddMember(String familyId) async {
    try {
      final subscription = await getSubscription(familyId);

      if (subscription == null) return false;

      final tier = subscription['tier'] as String;

      // Pro plan can't add members
      if (tier == 'pro') return false;

      // Free tier can't add members
      if (tier == 'free') return false;

      // Family plan - check current vs max
      final currentMembers = subscription['current_members'] as int? ?? 1;
      final maxMembers =
          subscription['max_members'] as int? ?? familyBaseUsersIncluded;

      // Family plan has unlimited members (you pay per additional user after 5)
      // So technically always true, but you might want to set a hard limit
      return true; // or: currentMembers < maxMembers if you have a hard limit
    } catch (e) {
      print('Error checking member limit: $e');
      return false;
    }
  }

  /// Validate if a tier allows a certain number of members
  static bool validateMemberCount(int memberCount, String tier) {
    if (tier == 'pro' && memberCount > proMaxUsers) {
      return false;
    }

    // Family plan can have unlimited members (with additional charges)
    if (tier == 'family') {
      return true;
    }

    // Free tier is 1 user
    if (tier == 'free' && memberCount > 1) {
      return false;
    }

    return true;
  }
}
