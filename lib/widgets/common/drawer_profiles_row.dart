import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/account_switch_provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_colors.dart';
import '../dialogs/account_switch_bottom_sheet.dart';

class DrawerProfilesRow extends StatelessWidget {
  const DrawerProfilesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AccountSwitchProvider, AuthProvider>(
      builder: (context, accountProvider, authProvider, child) {
        final currentUser = authProvider.currentUser;
        final otherAccounts = accountProvider.otherAccounts;
        
        return Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          child: Row(
            children: [
              // Current user profile (larger)
              GestureDetector(
                onTap: () => _showAccountSwitchBottomSheet(context),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: currentUser?.profileImageUrl != null
                        ? NetworkImage(currentUser!.profileImageUrl!)
                        : null,
                    child: currentUser?.profileImageUrl == null
                        ? Text(
                            currentUser?.displayName
                                    .substring(0, 1)
                                    .toUpperCase() ??
                                'U',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Other accounts (smaller)
              ...otherAccounts.take(3).map((account) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => _showAccountSwitchBottomSheet(context),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white70,
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundImage: account.user.profileImageUrl != null
                          ? NetworkImage(account.user.profileImageUrl!)
                          : null,
                      child: account.user.profileImageUrl == null
                          ? Text(
                              account.user.displayName
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              )),
              
              // Add more accounts indicator if space available
              if (accountProvider.canAddMoreAccounts && otherAccounts.length < 3)
                GestureDetector(
                  onTap: () => _showAccountSwitchBottomSheet(context),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white70,
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              
              const Spacer(),
              
              // More accounts indicator or settings
              GestureDetector(
                onTap: () => _showAccountSwitchBottomSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.more_horiz,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAccountSwitchBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AccountSwitchBottomSheet(),
    );
  }
}