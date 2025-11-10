class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  /// Family member avatar colors
  static const List<String> familyColors = [
    '#FF6B6B',
    '#4ECDC4',
    '#45B7D1',
    '#FFA07A',
    '#98D8C8',
    '#F7DC6F',
    '#BB8FCE',
    '#85C1E2',
  ];

  /// App name
  static const String appName = 'Family Grocery List';

  /// Section headers
  static const String toBuyHeader = 'TO BUY';
  static const String completedHeader = 'COMPLETED';

  /// Hints and messages
  static const String addItemHint = 'Add grocery item...';
  static const String addMemberHint = 'Add family member...';
  static const String shoppingAsLabel = 'Shopping as:';
  static const String emptyListMessage =
      'No items yet.\nAdd your first grocery item!';
}
