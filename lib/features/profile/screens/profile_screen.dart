import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark || 
        (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? '';
    final photoUrl = user?.photoURL;
    final initials = displayName.isNotEmpty
        ? displayName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF0F2F4),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 16),

            // Avatar & Name
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryAmber, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryAmber.withAlpha(60),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: photoUrl != null && photoUrl.isNotEmpty
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, e, s) => _InitialsAvatar(initials: initials, isDark: isDark),
                            )
                          : _InitialsAvatar(initials: initials, isDark: isDark),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Member since badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryAmber.withAlpha(60)),
                    ),
                    child: Text(
                      'Member since ${_formatDate(user?.metadata.creationTime)}',
                      style: TextStyle(
                        color: AppTheme.primaryAmber,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Appearance Section
            _SectionTitle(title: 'APPEARANCE', isDark: isDark),
            const SizedBox(height: 8),
            _ProfileCard(
              isDark: isDark,
              children: [
                _ProfileTile(
                  icon: Icons.dark_mode_rounded,
                  title: 'Dark Mode',
                  isDark: isDark,
                  trailing: Switch.adaptive(
                    value: isDark,
                    activeTrackColor: AppTheme.primaryAmber,
                    activeThumbColor: Colors.white,
                    onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Account Section
            _SectionTitle(title: 'ACCOUNT', isDark: isDark),
            const SizedBox(height: 8),
            _ProfileCard(
              isDark: isDark,
              children: [
                _ProfileTile(
                  icon: Icons.person_rounded,
                  title: 'Edit Profile Name',
                  isDark: isDark,
                  onTap: () => _showEditNameDialog(context, user),
                ),
                _Divider(isDark: isDark),
                _ProfileTile(
                  icon: Icons.email_rounded,
                  title: 'Email',
                  subtitle: email,
                  isDark: isDark,
                ),
                _Divider(isDark: isDark),
                _ProfileTile(
                  icon: Icons.security_rounded,
                  title: 'Change Password',
                  isDark: isDark,
                  onTap: () => _showChangePasswordDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // App Section
            _SectionTitle(title: 'APP', isDark: isDark),
            const SizedBox(height: 8),
            _ProfileCard(
              isDark: isDark,
              children: [
                _ProfileTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About Grocery Vision',
                  isDark: isDark,
                  onTap: () => _showAboutDialog(context, isDark),
                ),
                _Divider(isDark: isDark),
                _ProfileTile(
                  icon: Icons.star_rounded,
                  title: 'Rate App',
                  isDark: isDark,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rate App — Coming soon!')),
                    );
                  },
                ),
                _Divider(isDark: isDark),
                _ProfileTile(
                  icon: Icons.share_rounded,
                  title: 'Share App',
                  isDark: isDark,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share — Coming soon!')),
                    );
                  },
                ),
                _Divider(isDark: isDark),
                _ProfileTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  isDark: isDark,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help & Support — Coming soon!')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Danger Zone
            _SectionTitle(title: 'DANGER ZONE', isDark: isDark, color: Colors.redAccent),
            const SizedBox(height: 8),
            _ProfileCard(
              isDark: isDark,
              borderColor: Colors.redAccent.withAlpha(40),
              children: [
                _ProfileTile(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  isDark: isDark,
                  iconColor: Colors.redAccent,
                  titleColor: Colors.redAccent,
                  onTap: () => _showSignOutDialog(context),
                ),
                _Divider(isDark: isDark),
                _ProfileTile(
                  icon: Icons.delete_forever_rounded,
                  title: 'Delete Account',
                  isDark: isDark,
                  iconColor: Colors.redAccent,
                  titleColor: Colors.redAccent,
                  onTap: () => _showDeleteAccountDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // App version
            Center(
              child: Text(
                'Grocery Vision v1.0.0',
                style: TextStyle(
                  color: isDark ? Colors.white24 : Colors.black26,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _showEditNameDialog(BuildContext context, User? user) {
    final controller = TextEditingController(text: user?.displayName ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Name', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: Colors.white.withAlpha(80)),
            filled: true,
            fillColor: Colors.white.withAlpha(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await user?.updateDisplayName(controller.text.trim());
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAmber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Google sign-in users can't change password
    final isGoogleUser = user.providerData.any((p) => p.providerId == 'google.com');
    if (isGoogleUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password change not available for Google Sign-In users.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Password', style: TextStyle(color: Colors.white)),
        content: const Text(
          'A password reset email will be sent to your registered email address.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (user.email != null) {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
              }
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password reset email sent!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAmber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Grocery Vision',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Grocery Vision uses Gemini AI to instantly identify grocery products by photo. '
          'Just point your camera, double-tap, and get detailed product information including '
          'nutrition facts, ingredients, and allergen warnings.\n\n'
          'Version 1.0.0\n'
          'Powered by Google Gemini 2.5 Flash',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            height: 1.5,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAmber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to sign out?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                // Go to login screen
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser?.delete();
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete account. Please re-authenticate and try again.'),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }
}

// --- Internal Widgets ---

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  final bool isDark;

  const _InitialsAvatar({required this.initials, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.primaryAmber : Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  final Color? color;

  const _SectionTitle({required this.title, required this.isDark, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          color: color ?? (isDark ? Colors.white38 : Colors.black38),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final bool isDark;
  final Color? borderColor;
  final List<Widget> children;

  const _ProfileCard({required this.isDark, this.borderColor, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(10) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? (isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(8)),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDark;
  final Color? iconColor;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.isDark,
    this.iconColor,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppTheme.primaryAmber).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppTheme.primaryAmber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor ?? (isDark ? Colors.white : Colors.black87),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  (onTap != null
                      ? Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? Colors.white24 : Colors.black26,
                          size: 22,
                        )
                      : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;

  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6),
      ),
    );
  }
}
