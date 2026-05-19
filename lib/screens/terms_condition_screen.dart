import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

class TermsConditionScreen extends StatelessWidget {
  final String appName;
  final String supportEmail;
  const TermsConditionScreen({
    super.key,
    this.appName = 'BTC Reward',
    this.supportEmail = 'bitcoincloudminingformobile@gmail.com',
  });

  @override
  Widget build(BuildContext context) {
    final String dynamicLastUpdated =
        DateFormat('MMMM yyyy').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1A237E), // Deep blue
                Color(0xFF0D47A1), // Darker blue
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A237E), // Deep blue
              Color(0xFF0D47A1), // Darker blue
            ],
          ),
        ),
        child: Container(
          color: Colors.black.withAlpha(128),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: MarkdownBody(
              data: """
⚠️ **Important Notice:** This is a reward-based simulation game. BTC shown in the app is a in-game currency earned through gameplay and watching ads. Users who meet the minimum threshold may submit a redemption request, which is reviewed and fulfilled at our discretion as a goodwill reward.

**Terms & Conditions** 
_Last Updated: ${dynamicLastUpdated}_

Welcome to **$appName**. By using our app, you agree to the following terms and conditions. Please read them carefully before using the service.

## 1. Acceptance of Terms 
By accessing or using **$appName**, you confirm that you have read, understood, and agreed to these Terms & Conditions. If you do not agree, please do not use the app.

## 2. About This App 
- **$appName** is a **reward-based simulation game** that simulates BTC Reward gameplay for entertainment purposes.
- All BTC balances shown in the app are **in-game currency** and do not represent real cryptocurrency.
- The app is **not a financial product**, cryptocurrency exchange, or investment platform.
- Users can earn BTC by engaging with the app, completing tasks, and watching rewarded advertisements.

## 3. Eligibility 
- You must be at least **18 years old** or the age of majority in your jurisdiction. 
- By using the app, you confirm that you are legally allowed to use entertainment and reward-based applications in your region.

## 4. How Rewards Work 
- Users earn **BTC** (in-game points) by watching rewarded ads, completing tasks, and daily check-ins.
- BTC has **no real monetary value** by itself.
- Once a user accumulates a minimum of **0.00005 BTC**, they may submit a **redemption request** through the app.
- Redemption requests are **manually reviewed** by our team. Approved requests are fulfilled as a goodwill reward (via Bitcoin, PayPal, or Paytm) at our sole discretion.
- Redemption is **not guaranteed** and may be declined if fraudulent activity, bot usage, or abuse is detected.
- Approved redemptions are typically processed within **48–72 hours** after verification.
- **No fees** are charged for redemption requests.

## 5. Currency Policy 
- BTC earned in this app **cannot be traded, sold, or transferred** between users.
- BTC has no cash value unless specifically fulfilled through our voluntary redemption program.
- We reserve the right to modify, reset, or discontinue currency balances at any time.

## 6. Prohibited Activities 
You agree **not** to: 
- Use bots, automation, scripts, or emulators to manipulate in-game rewards or currency.
- Create multiple accounts to abuse the reward system.
- Engage in hacking, fraudulent activities, or exploits.
- Violate any applicable laws or regulations.

## 7. Advertisements & Monetization 
- The app displays advertisements powered by **Google AdMob**, including rewarded video ads that grant in-game BTC.
- Ad-blocking tools may restrict access to certain app features.
- We do not control the content of third-party advertisements.

## 8. Account Suspension & Termination 
We reserve the right to suspend or terminate accounts that: 
- Violate these Terms & Conditions.
- Use fraudulent methods to inflate balances.
- Abuse the redemption request system.
- Remain inactive for an extended period.

## 9. No Guarantees & Liability Disclaimer 
- We do **not guarantee** any specific earnings, rewards, or redemption payouts.
- The app is provided "as-is." We are **not responsible** for any financial loss or damages.
- Bitcoin price estimates shown are for informational and entertainment purposes only.
- This app is **not an investment product**. Do not make financial decisions based on in-app balances.

## 10. Privacy 
- We collect basic account information (email, wallet address for redemption) to provide our services.
- We use **Google AdMob** for advertising, which may collect device and usage data per Google's Privacy Policy.
- We do not sell your personal data to third parties.
- For full details, see our Privacy Policy below.

## 11. Changes to Terms 
We may update these Terms & Conditions at any time. Continued use of the app after updates constitutes acceptance of the revised terms.

## 12. Contact Us 
If you have any questions, please contact us at **$supportEmail**.

---
By using **$appName**, you acknowledge that this is a **simulation game**, not a financial service, and you agree to these Terms & Conditions.

Privacy Policy: https://doc-hosting.flycricket.io/bitcoin-cloud-mining-privacy-policy/140d10f0-13a2-42a0-a93a-ec68298f58db/privacy
Terms & Conditions: https://doc-hosting.flycricket.io/bitcoin-cloud-mining-terms-of-use/8c21ec3c-9f18-4255-8ec1-9c8a4c98bf95/terms
""",
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 16, color: Colors.white),
                strong: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white),
                em: const TextStyle(
                    fontStyle: FontStyle.italic, color: Colors.white),
                h2: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1A237E),
                Color(0xFF0D47A1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF0D47A1),
            ],
          ),
        ),
        child: Container(
          color: Colors.black.withAlpha(128),
          padding: const EdgeInsets.all(16),
          child: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '⚠️ This is a reward-based simulation game. All BTC shown is in-game currency. Redemptions are enabled only when minimum thresholds are reached and verified by our team.',
                  style: TextStyle(fontSize: 15, color: Colors.amber),
                ),
                SizedBox(height: 16),
                Text(
                  '1. Information We Collect\n\n'
                  '• Account Info: Email address and username when you register.\n'
                  '• Wallet/Payment Info: Bitcoin address, PayPal email, or Paytm number — only when you submit a redemption request.\n'
                  '• Usage Data: App activity, BTC earned, and redemption history.\n'
                  '• Device Info: Device type, OS version, and app version for troubleshooting.\n\n'
                  '2. Advertising (Google AdMob)\n\n'
                  'This app uses Google AdMob to display rewarded video ads. AdMob may collect:\n'
                  '• Advertising ID (GAID)\n'
                  '• Device information and IP address\n'
                  '• App usage and interaction data\n\n'
                  'AdMob data is governed by Google\'s Privacy Policy: https://policies.google.com/privacy\n\n'
                  '3. How We Use Your Information\n\n'
                  '• To process redemption requests and verify eligibility.\n'
                  '• To prevent fraud, abuse, and multiple account creation.\n'
                  '• To improve app performance and user experience.\n'
                  '• To send important app notifications (with your permission).\n\n'
                  '4. Data Sharing\n\n'
                  'We do NOT sell your personal data. We only share data:\n'
                  '• With payment processors (PayPal/Paytm) when processing approved redemptions.\n'
                  '• With Google AdMob for ad delivery.\n'
                  '• When required by law.\n\n'
                  '5. Data Retention\n\n'
                  'We retain your data as long as your account is active. You may request account and data deletion by emailing us.\n\n'
                  '6. Your Rights\n\n'
                  'You may request to:\n'
                  '• Access your personal data.\n'
                  '• Correct inaccurate data.\n'
                  '• Delete your account and data.\n\n'
                  '7. Children\'s Privacy\n\n'
                  'This app is intended for users 18 years and older. We do not knowingly collect data from children under 13.\n\n'
                  '8. Changes to This Policy\n\n'
                  'We may update this Privacy Policy periodically. Continued use of the app constitutes acceptance of any changes.\n\n'
                  '9. Contact Us\n\n'
                  'For privacy questions or data deletion requests:\n'
                  'Email: bitcoincloudminingformobile@gmail.com\n\n'
                  'Full Privacy Policy:\n'
                  'https://doc-hosting.flycricket.io/bitcoin-cloud-mining-privacy-policy/140d10f0-13a2-42a0-a93a-ec68298f58db/privacy',
                  style: TextStyle(
                      fontSize: 15, color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
