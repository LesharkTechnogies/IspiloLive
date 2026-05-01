import 'package:flutter/material.dart';
import '../presentation/product_detail/product_detail.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/marketplace/marketplace.dart';
import '../presentation/education_hub/education_hub.dart';
import '../presentation/home_feed/home_feed.dart';
import '../presentation/settings/settings.dart';
import '../presentation/settings/edit_profile.dart';
import '../presentation/messages/messages.dart';
import '../presentation/chat/chat_page.dart';
import '../presentation/marketplace/shop_registration_step1_page.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/auth/register_screen.dart';
import '../presentation/auth/forgot_password_screen.dart';
import '../presentation/home_feed/post_comments_page.dart';
import '../presentation/home_feed/post_content_page.dart';
import '../presentation/home_feed/discover_page.dart';
import '../presentation/notifications/notifications_page.dart';
import '../presentation/marketplace/seller_profile_page.dart';
import '../presentation/profile/user_profile_page.dart';
import '../presentation/settings/create_group_page.dart';
import '../presentation/profile/group_profile_page.dart' hide Text;
import '../presentation/marketplace/create_product_page.dart';

class AppRoutes {
  static const String initial = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String productDetail = '/product-detail';
  static const String splash = '/splash-screen';
  static const String marketplace = '/marketplace';
  static const String educationHub = '/education-hub';
  static const String homeFeed = '/home-feed';
  static const String settings = '/settings';
  static const String editProfile = '/edit-profile';
  static const String messages = '/messages';
  static const String chat = '/chat';
  static const String shopRegistrationStep1 = '/shop-registration-step1';
  static const String postComments = '/post-comments';
  static const String postContent = '/post-content';
  static const String discover = '/discover';
  static const String notifications = '/notifications';
  static const String sellerProfile = '/seller-profile';
  static const String profile = '/profile';
  static const String createGroup = '/create-group';
  static const String groupProfile = '/group-profile';
  static const String sellSomething = '/sell-something';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    productDetail: (context) => const ProductDetail(),
    splash: (context) => const SplashScreen(),
    marketplace: (context) => const Marketplace(),
    educationHub: (context) => const EducationHub(),
    homeFeed: (context) => const HomeFeed(),
    settings: (context) => const Settings(),
    editProfile: (context) => const EditProfile(),
    messages: (context) => const MessagesPage(),
    chat: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return ChatPage(conversation: args ?? {});
    },
    postComments: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args == null) {
        return  const Scaffold(body: Center(child: Text('No post data')));
      }
      return PostCommentsPage(postJson: args);
    },
    postContent: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args == null) {
        return const Scaffold(body: Center(child: Text('No post data')));
      }
      return PostContentPage(postData: args);
    },
    discover: (context) => const DiscoverPage(),
    shopRegistrationStep1: (context) => const ShopRegistrationStep1Page(),
    notifications: (context) => const NotificationsPage(),
    sellerProfile: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final sellerId = args?['sellerId'] as String? ?? '';
      return SellerProfilePage(sellerId: sellerId);
    },
    profile: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final userId = args?['userId']?.toString() ?? '';
      return UserProfilePage(userId: userId);
    },
    createGroup: (context) => const CreateGroupPage(),
    groupProfile: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final groupId = args?['groupId']?.toString() ?? '';
      final groupName = args?['groupName']?.toString() ?? 'Group';
      return GroupProfilePage(groupId: groupId, groupName: groupName);
    },
    sellSomething: (context) => const CreateProductPage(),
  };
}
