import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../localization/app_strings.dart';
import '../../models/user_profile.dart';
import '../../state/reader_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/user_avatar.dart';

class AccountSettingsView extends StatefulWidget {
  const AccountSettingsView({
    super.key,
    required this.controller,
    required this.wideLayout,
  });

  final ReaderController controller;
  final bool wideLayout;

  @override
  State<AccountSettingsView> createState() => _AccountSettingsViewState();
}

class _AccountSettingsViewState extends State<AccountSettingsView> {
  final TextEditingController _identityCodeController = TextEditingController();
  bool _showManualCodeInput = false;

  ReaderController get controller => widget.controller;

  @override
  void dispose() {
    _identityCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller.isSignedIn && _showManualCodeInput) {
      _showManualCodeInput = false;
      _identityCodeController.clear();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (controller.isSignedIn)
          _buildSignedInView(context)
        else
          _buildSignedOutView(context),
      ],
    );
  }

  Widget _buildSignedOutView(BuildContext context) {
    final AppStrings strings = context.strings;
    final bool cloudReady = controller.isOfficialCloudConfigured;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _AccountCard(
          wideLayout: widget.wideLayout,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                strings.accountPageTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.accountSignedOutHintCloud,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.paletteOf(context).secondaryText,
                    ),
              ),
              if (!cloudReady) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  strings.accountCloudUnavailable,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ],
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: controller.isBusy || !cloudReady
                        ? null
                        : () => controller.generateIdentityAndSignIn(),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(strings.accountGenerateCode),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.isBusy || !cloudReady
                        ? null
                        : () {
                            setState(() {
                              _showManualCodeInput = !_showManualCodeInput;
                            });
                          },
                    icon: const Icon(Icons.password_rounded),
                    label: Text(strings.accountEnterCode),
                  ),
                ],
              ),
              if (_showManualCodeInput) ...<Widget>[
                const SizedBox(height: 18),
                TextField(
                  controller: _identityCodeController,
                  autofocus: true,
                  maxLength: kIdentityCodeLength,
                  decoration: InputDecoration(
                    labelText: strings.accountIdentityCodeLabel,
                    hintText: strings.accountIdentityCodeHint,
                    errorText: _identityErrorText(context),
                    counterText: '',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton(
                        onPressed: _canSubmitIdentityCode && cloudReady
                            ? () async {
                                await controller.signInWithIdentityCode(
                                  _identityCodeController.text,
                                );
                                if (mounted && controller.isSignedIn) {
                                  setState(() {
                                    _showManualCodeInput = false;
                                  });
                                  _identityCodeController.clear();
                                }
                              }
                            : null,
                        child: Text(strings.accountApplyIdentityCode),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showManualCodeInput = false;
                        });
                        _identityCodeController.clear();
                      },
                      child: Text(strings.cancel),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignedInView(BuildContext context) {
    final AppStrings strings = context.strings;
    final UserProfile profile = controller.currentUser!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildAccountHeader(context, profile),
        const SizedBox(height: 18),
        _AccountInfoCard(
          wideLayout: widget.wideLayout,
          icon: Icons.badge_outlined,
          iconColor: const Color(0xFF0F9D58),
          iconBackground: const Color(0xFFD7F2E3),
          title: strings.accountPersonalInfoTitle,
          subtitle: strings.accountPersonalInfoHint,
          child: Column(
            children: <Widget>[
              _AccountInfoRow(
                label: strings.accountDisplayNameLabel,
                value: controller.currentUserDisplayName,
                trailing: TextButton(
                  onPressed: controller.isOfficialCloudConfigured
                      ? _showEditDisplayNameDialog
                      : null,
                  child: Text(strings.accountEditDisplayName),
                ),
              ),
              _AccountInfoRow(
                label: strings.accountAvatarLabel,
                value: strings.accountAvatarHint,
                trailing: OutlinedButton(
                  onPressed: controller.isBusy
                      ? null
                      : () => controller.pickAndSaveUserAvatar(),
                  child: Text(strings.accountChangeAvatar),
                ),
              ),
              _AccountInfoRow(
                label: strings.accountIdentityCodeLabel,
                value: controller.currentIdentityCodeDisplay,
                trailing: IconButton(
                  tooltip: strings.accountCopyIdentityCode,
                  onPressed: () => _copyIdentityCode(context),
                  icon: const Icon(Icons.copy_rounded),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _AccountInfoCard(
          wideLayout: widget.wideLayout,
          icon: Icons.cloud_outlined,
          iconColor: const Color(0xFF4285F4),
          iconBackground: const Color(0xFFDCE8FF),
          title: strings.accountCloudServiceTitle,
          subtitle: null,
          headerTrailing: Tooltip(
            message: _cloudServiceSwitchLabel(context),
            child: Switch(
              value: controller.cloudServiceEnabled,
              onChanged: controller.isBusy
                  ? null
                  : (bool value) => controller.setCloudServiceEnabled(value),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.paletteOf(context)
                      .panelMutedBackground
                      .withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.paletteOf(context).border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      controller.isContentCloudConfigured
                          ? _cloudConnectionLabel(context)
                          : strings.accountCloudUnavailable,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: controller.isContentCloudConfigured
                                ? null
                                : Theme.of(context).colorScheme.error,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _cloudStatusText(context),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.paletteOf(context).secondaryText,
                          ),
                    ),
                    if (controller.currentCloudSyncAt != null) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        strings.accountCloudLastSync(
                          _formatSyncTime(controller.currentCloudSyncAt!),
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.paletteOf(context).secondaryText,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (controller.cloudServiceEnabled)
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: controller.isBusy ||
                              !controller.isContentCloudConfigured
                          ? null
                          : () => controller.uploadCurrentUserToOfficialCloud(),
                      icon: const Icon(Icons.cloud_upload_rounded),
                      label: Text(strings.accountCloudUploadAction),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.isBusy ||
                              !controller.isContentCloudConfigured
                          ? null
                          : () =>
                              controller.downloadCurrentUserFromOfficialCloud(),
                      icon: const Icon(Icons.cloud_download_rounded),
                      label: Text(strings.accountCloudDownloadAction),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => controller.signOutUser(),
            icon: const Icon(Icons.logout_rounded),
            label: Text(strings.accountSignOut),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountHeader(BuildContext context, UserProfile profile) {
    final AppStrings strings = context.strings;
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final double avatarSize = widget.wideLayout ? 88 : 92;

    return _AccountCard(
      wideLayout: widget.wideLayout,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            strings.accountPageTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              UserAvatar(
                size: avatarSize,
                avatarPath: profile.avatarPath,
                displayName: controller.currentUserDisplayName,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      controller.currentUserDisplayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            controller.currentIdentityCodeDisplay,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: palette.secondaryText,
                                    ),
                          ),
                        ),
                        IconButton(
                          tooltip: strings.accountCopyIdentityCode,
                          onPressed: () => _copyIdentityCode(context),
                          icon: const Icon(Icons.copy_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copyIdentityCode(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(text: controller.currentIdentityCodeDisplay),
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.strings.accountIdentityCodeCopied)),
    );
  }

  Future<void> _showEditDisplayNameDialog() async {
    final AppStrings strings = context.strings;
    final TextEditingController displayNameController = TextEditingController(
      text: controller.currentUser?.displayName ?? '',
    );

    final String? nextValue = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(strings.accountEditDisplayName),
          content: TextField(
            controller: displayNameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: strings.accountDisplayNameLabel,
              hintText: strings.accountDisplayNameHint,
            ),
            maxLength: 32,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(displayNameController.text);
              },
              child: Text(strings.save),
            ),
          ],
        );
      },
    );

    displayNameController.dispose();
    if (nextValue == null) {
      return;
    }
    await controller.updateUserDisplayName(nextValue);
  }

  bool get _canSubmitIdentityCode {
    return isValidIdentityCode(_identityCodeController.text.trim());
  }

  String? _identityErrorText(BuildContext context) {
    final String value = _identityCodeController.text.trim();
    if (value.isEmpty || _canSubmitIdentityCode) {
      return null;
    }
    return context.strings.accountIdentityCodeInvalid;
  }

  String _cloudStatusText(BuildContext context) {
    final AppStrings strings = context.strings;
    final String? detail = controller.currentCloudSyncMessage;
    final String baseText;
    switch (controller.currentCloudSyncStatus) {
      case CloudSyncStatus.idle:
        baseText = strings.accountCloudStatusIdle;
        break;
      case CloudSyncStatus.synced:
        baseText = strings.accountCloudStatusSynced;
        break;
      case CloudSyncStatus.failed:
        baseText = strings.accountCloudStatusFailed;
        break;
    }
    if (detail == null || detail.trim().isEmpty) {
      return baseText;
    }
    return '$baseText · $detail';
  }

  String _formatSyncTime(DateTime value) {
    final DateTime local = value.toLocal();
    String twoDigits(int part) => part.toString().padLeft(2, '0');
    return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  String _cloudConnectionLabel(BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    switch (locale.languageCode) {
      case 'zh':
        return locale.scriptCode == 'Hant' || locale.countryCode == 'TW'
            ? '目前連線：摺紙雲（由 CzWorks 提供服務）'
            : '当前连接：折纸云（由 CzWorks 提供服务）';
      default:
        return 'Current connection: Origami Cloud (provided by CzWorks)';
    }
  }

  String _cloudServiceSwitchLabel(BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    switch (locale.languageCode) {
      case 'zh':
        return locale.scriptCode == 'Hant' || locale.countryCode == 'TW'
            ? '啟用雲服務'
            : '启用云服务';
      default:
        return 'Enable Cloud Services';
    }
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.wideLayout,
    required this.child,
  });

  final bool wideLayout;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(wideLayout ? 24 : 20),
      decoration: BoxDecoration(
        color: palette.panelBackground,
        borderRadius: BorderRadius.circular(wideLayout ? 26 : 24),
        border: Border.all(color: palette.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  const _AccountInfoCard({
    required this.wideLayout,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.child,
    this.headerTrailing,
  });

  final bool wideLayout;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? headerTrailing;

  @override
  Widget build(BuildContext context) {
    return _AccountCard(
      wideLayout: wideLayout,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (subtitle != null &&
                        subtitle!.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.paletteOf(context).secondaryText,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (headerTrailing != null) ...<Widget>[
                const SizedBox(width: 12),
                headerTrailing!,
              ],
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _AccountInfoRow extends StatelessWidget {
  const _AccountInfoRow({
    required this.label,
    required this.value,
    required this.trailing,
  });

  final String label;
  final String value;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: palette.panelMutedBackground.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: palette.secondaryText,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }
}
