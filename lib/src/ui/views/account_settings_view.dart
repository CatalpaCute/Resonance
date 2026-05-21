import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m3e_buttons/m3e_buttons.dart';

import '../../localization/app_strings.dart';
import '../../models/reader_settings.dart';
import '../../models/user_profile.dart';
import '../../services/private_webdav_service.dart';
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
  static const List<IconData> _officialCloudUsageIcons = <IconData>[
    Icons.cloud_queue_rounded,
    Icons.auto_awesome_rounded,
    Icons.data_object_rounded,
    Icons.widgets_outlined,
    Icons.cloud_sync_outlined,
    Icons.blur_on_rounded,
  ];
  bool _showManualCodeInput = false;
  late final IconData _officialCloudUsageIcon = _officialCloudUsageIcons[
      Random().nextInt(_officialCloudUsageIcons.length)];

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
    final bool cloudReady = controller.isIdentityCloudConfigured;

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
                _signedOutHintText(context),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.paletteOf(context).secondaryText,
                    ),
              ),
              if (!cloudReady) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  _identityCloudUnavailableText(context),
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
                  if (controller.privateCloudEnabled ||
                      controller.usesPrivateIdentityCloud ||
                      controller.usesPrivateContentCloud)
                    OutlinedButton.icon(
                      onPressed: controller.isBusy
                          ? null
                          : () => _showPrivateCloudServerSheet(context),
                      icon: const Icon(Icons.settings_outlined),
                      label: Text(_configureServerActionLabel(context)),
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
          subtitle: null,
          centerHeaderContent: true,
          child: _AccountInfoGroup(
            children: <Widget>[
              _AccountInfoListRow(
                icon: Icons.person_outline_rounded,
                label: strings.accountDisplayNameLabel,
                value: controller.currentUserDisplayName,
                trailing: TextButton(
                  onPressed: controller.isIdentityCloudConfigured
                      ? _showEditDisplayNameDialog
                      : null,
                  child: Text(strings.accountEditDisplayName),
                ),
              ),
              _AccountInfoListRow(
                icon: Icons.photo_camera_outlined,
                label: strings.accountAvatarLabel,
                value: strings.accountAvatarHint,
                trailing: OutlinedButton(
                  onPressed: controller.isBusy
                      ? null
                      : () => controller.pickAndSaveUserAvatar(),
                  child: Text(strings.accountChangeAvatar),
                ),
              ),
              _AccountInfoListRow(
                icon: Icons.vpn_key_outlined,
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
          subtitleWidget: _CloudConnectionSelector(
            connectionLabel: _cloudConnectionLabel(context),
            optionLabel: _cloudServiceOptionLabel(
              context,
              controller.cloudContentMode,
            ),
            selectedMode: controller.cloudContentMode,
            onSelected: controller.isBusy
                ? null
                : (CloudContentMode mode) =>
                    controller.setCloudContentModeSelection(mode),
          ),
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
              if (controller.usesPrivateContentCloud)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AccountInfoRow(
                    label: _serverSectionTitle(context),
                    value: _serverSectionValue(context),
                    trailing: IconButton(
                      tooltip: _serverSettingsTooltip(context),
                      onPressed: controller.isBusy
                          ? null
                          : () => _showPrivateCloudServerSheet(context),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ),
                ),
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
                    if (!controller.usesPrivateContentCloud)
                      _buildOfficialCloudStatusPanel(context)
                    else
                      _buildCompactCloudStatusPanel(context, strings),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _cloudAutoSyncLabel(context),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Switch(
                    value: controller.cloudAutoSyncEnabled,
                    onChanged: controller.isBusy || !controller.cloudServiceEnabled
                        ? null
                        : (bool value) =>
                            controller.setCloudAutoSyncEnabled(value),
                  ),
                ],
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
                          : () => controller.uploadCurrentUserToCloud(),
                      icon: const Icon(Icons.cloud_upload_rounded),
                      label: Text(_cloudUploadActionLabel(context)),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.isBusy ||
                              !controller.isContentCloudConfigured
                          ? null
                          : () => controller.downloadCurrentUserFromCloud(),
                      icon: const Icon(Icons.cloud_download_rounded),
                      label: Text(_cloudDownloadActionLabel(context)),
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

  Future<void> _showPrivateCloudServerSheet(BuildContext context) async {
    final _PrivateCloudServerConfigResult? result =
        await showModalBottomSheet<_PrivateCloudServerConfigResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _PrivateCloudServerSheet(
          initialProtocol: controller.privateCloudProtocol,
          initialBaseUrl: controller.privateCloudBaseUrl,
          initialUsername: controller.privateCloudUsername,
          initialPassword: controller.privateCloudPassword,
          initialBasePath: controller.privateCloudBasePath,
          initialAdvancedModeEnabled: controller.advancedCloudModeEnabled,
        );
      },
    );

    if (result == null) {
      return;
    }

    await controller.setPrivateCloudProtocol(result.protocol);
    await controller.setPrivateCloudServerConfig(
      baseUrl: result.baseUrl,
      username: result.username,
      password: result.password,
      basePath: result.basePath,
    );
    await controller.setAdvancedCloudModeEnabled(
      result.advancedModeEnabled,
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

  String _signedOutHintText(BuildContext context) {
    if (controller.usesPrivateIdentityCloud) {
      return _localizedText(
        context,
        zhHans: '生成代码会直接注册到个人云。输入已有代码时，也会先从个人云校验身份是否存在。',
        zhHant: '產生代碼會直接註冊到個人雲。輸入既有代碼時，也會先從個人雲驗證身分是否存在。',
        en: 'Generating a code will register it with the personal cloud. Entering an existing code will first verify it in the personal cloud.',
      );
    }
    return context.strings.accountSignedOutHintCloud;
  }

  Widget _buildOfficialCloudStatusPanel(BuildContext context) {
    return FutureBuilder<int>(
      future: controller.estimateCurrentUserContentSyncBytes(),
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        final int bytes = snapshot.data ?? 0;
        final int percent =
            ((bytes / (20 * 1024 * 1024)) * 100).clamp(0, 100).round();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _OfficialCloudUsageVisual(
                icon: _officialCloudUsageIcon,
                percentText: '$percent%',
                tooltipText:
                    '${_formatStorageRatioText(context, percent / 100)} ${_formatMegabytes(bytes)} MB',
                palette: AppTheme.paletteOf(context),
                colorScheme: Theme.of(context).colorScheme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCloudStatusSummary(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactCloudStatusPanel(
    BuildContext context,
    AppStrings strings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _cloudStatusText(context),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: _cloudStatusTextColor(context),
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
    );
  }

  Widget _buildCloudStatusSummary(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final bool synced =
        controller.currentCloudSyncStatus == CloudSyncStatus.synced;
    final bool failed =
        controller.currentCloudSyncStatus == CloudSyncStatus.failed;
    final Color accent = failed
        ? Theme.of(context).colorScheme.error
        : (synced
            ? Theme.of(context).colorScheme.primary
            : palette.secondaryText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _localizedText(
                context,
                zhHans: '同步状态',
                zhHant: '同步狀態',
                en: 'Sync Status',
              ),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: palette.secondaryText,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _cloudStatusText(context),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.35,
                color: _cloudStatusTextColor(context),
              ),
        ),
        if (controller.currentCloudSyncAt != null) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            context.strings.accountCloudLastSync(
              _formatSyncTime(controller.currentCloudSyncAt!),
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.secondaryText,
                  height: 1.3,
                ),
          ),
        ],
      ],
    );
  }

  String _identityCloudUnavailableText(BuildContext context) {
    if (controller.usesPrivateIdentityCloud) {
      return _localizedText(
        context,
        zhHans: '个人云服务器尚未配置。先在云服务里设置 WebDAV 地址后，才能创建或登录身份。',
        zhHant: '個人雲伺服器尚未設定。請先在雲服務中設定 WebDAV 位址，才能建立或登入身分。',
        en: 'The personal cloud server is not configured yet. Set up the WebDAV server first before creating or signing in to an identity.',
      );
    }
    return context.strings.accountCloudUnavailable;
  }

  String _cloudStatusText(BuildContext context) {
    if (controller.usesPrivateContentCloud &&
        !controller.isContentCloudConfigured) {
      return _localizedText(
        context,
        zhHans: '个人云服务器尚未配置。',
        zhHant: '個人雲伺服器尚未設定。',
        en: 'The personal cloud server is not configured yet.',
      );
    }
    if (!controller.usesPrivateContentCloud &&
        !controller.isContentCloudConfigured) {
      return context.strings.accountCloudUnavailable;
    }

    final String? detail = controller.currentCloudSyncMessage?.trim();
    if (detail != null && detail.isNotEmpty) {
      return detail;
    }

    if (controller.usesPrivateContentCloud) {
      switch (controller.currentCloudSyncStatus) {
        case CloudSyncStatus.idle:
          return _localizedText(
            context,
            zhHans: '个人云已连接，等待同步。',
            zhHant: '個人雲已連線，等待同步。',
            en: 'The personal cloud is connected and waiting to sync.',
          );
        case CloudSyncStatus.synced:
          return controller.advancedCloudModeEnabled
              ? _localizedText(
                  context,
                  zhHans: '账号信息与内容已同步到个人云。',
                  zhHant: '帳號資訊與內容已同步到個人雲。',
                  en: 'Account details and content were synced to the personal cloud.',
                )
              : _localizedText(
                  context,
                  zhHans: '订阅、文章和头像已同步到个人云。',
                  zhHant: '訂閱、文章與頭像已同步到個人雲。',
                  en: 'Subscriptions, articles, and avatar were synced to the personal cloud.',
                );
        case CloudSyncStatus.failed:
          return _localizedText(
            context,
            zhHans: '个人云同步失败了。',
            zhHant: '個人雲同步失敗了。',
            en: 'Syncing with the personal cloud failed.',
          );
      }
    }

    switch (controller.currentCloudSyncStatus) {
      case CloudSyncStatus.idle:
        return context.strings.accountCloudStatusIdle;
      case CloudSyncStatus.synced:
        return context.strings.accountCloudStatusSynced;
      case CloudSyncStatus.failed:
        return context.strings.accountCloudStatusFailed;
    }
  }

  Color _cloudStatusTextColor(BuildContext context) {
    if (controller.isContentCloudConfigured) {
      return AppTheme.paletteOf(context).secondaryText;
    }
    return Theme.of(context).colorScheme.error;
  }

  String _formatSyncTime(DateTime value) {
    final DateTime local = value.toLocal();
    String twoDigits(int part) => part.toString().padLeft(2, '0');
    return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  String _cloudConnectionLabel(BuildContext context) {
    final bool usePrivateCloud = controller.usesPrivateContentCloud;
    return _localizedText(
      context,
      zhHans: usePrivateCloud ? '当前连接：个人云' : '当前连接：折纸云',
      zhHant: usePrivateCloud ? '目前連線：個人雲' : '目前連線：摺紙雲',
      en: usePrivateCloud
          ? 'Current connection: Personal Cloud'
          : 'Current connection: Origami Cloud',
    );
  }

  String _formatStorageRatioText(BuildContext context, double ratio) {
    final int percent = (ratio * 100).round();
    return _localizedText(
      context,
      zhHans: '按本地待同步内容估算，当前约 $percent%',
      zhHant: '按本地待同步內容估算，目前約 $percent%',
      en: 'Estimated from local pending content: $percent%',
    );
  }

  String _formatMegabytes(int bytes) {
    final double value = bytes / (1024 * 1024);
    if (value >= 10) {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(2);
  }

  String _cloudServiceOptionLabel(
    BuildContext context,
    CloudContentMode mode,
  ) {
    switch (mode) {
      case CloudContentMode.official:
        return _localizedText(
          context,
          zhHans: '折纸云',
          zhHant: '摺紙雲',
          en: 'Origami Cloud',
        );
      case CloudContentMode.privateCloud:
        return _localizedText(
          context,
          zhHans: '个人云',
          zhHant: '個人雲',
          en: 'Personal Cloud',
        );
    }
  }

  String _cloudUploadActionLabel(BuildContext context) {
    return controller.usesPrivateContentCloud
        ? _localizedText(
            context,
            zhHans: '上传到个人云',
            zhHant: '上傳到個人雲',
            en: 'Upload to Personal Cloud',
          )
        : context.strings.accountCloudUploadAction;
  }

  String _cloudDownloadActionLabel(BuildContext context) {
    return controller.usesPrivateContentCloud
        ? _localizedText(
            context,
            zhHans: '从个人云下载',
            zhHant: '從個人雲下載',
            en: 'Download from Personal Cloud',
          )
        : context.strings.accountCloudDownloadAction;
  }

  String _cloudServiceSwitchLabel(BuildContext context) {
    return _localizedText(
      context,
      zhHans: '启用云服务',
      zhHant: '啟用雲服務',
      en: 'Enable Cloud Services',
    );
  }

  String _cloudAutoSyncLabel(BuildContext context) {
    return _localizedText(
      context,
      zhHans: '自动同步',
      zhHant: '自動同步',
      en: 'Auto Sync',
    );
  }

  String _serverSectionTitle(BuildContext context) {
    return _localizedText(
      context,
      zhHans: '服务器',
      zhHant: '伺服器',
      en: 'Server',
    );
  }

  String _serverSectionValue(BuildContext context) {
    if (controller.privateCloudBaseUrl.trim().isEmpty) {
      return _localizedText(
        context,
        zhHans: '未配置',
        zhHant: '未設定',
        en: 'Not configured',
      );
    }
    final String host = Uri.tryParse(controller.privateCloudBaseUrl)?.host ??
        controller.privateCloudBaseUrl;
    return 'WebDAV · $host${controller.privateCloudBasePath}';
  }

  String _serverSettingsTooltip(BuildContext context) {
    return _localizedText(
      context,
      zhHans: '设置个人云服务器',
      zhHant: '設定個人雲伺服器',
      en: 'Configure personal cloud server',
    );
  }

  String _configureServerActionLabel(BuildContext context) {
    return _localizedText(
      context,
      zhHans: '设置服务器',
      zhHant: '設定伺服器',
      en: 'Configure Server',
    );
  }

  String _localizedText(
    BuildContext context, {
    required String zhHans,
    String? zhHant,
    required String en,
  }) {
    final Locale locale = Localizations.localeOf(context);
    if (locale.languageCode == 'zh') {
      final bool traditional =
          locale.scriptCode == 'Hant' || locale.countryCode == 'TW';
      return traditional ? (zhHant ?? zhHans) : zhHans;
    }
    return en;
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
    this.subtitleWidget,
    this.headerTrailing,
    this.centerHeaderContent = false,
  });

  final bool wideLayout;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? subtitleWidget;
  final Widget? headerTrailing;
  final bool centerHeaderContent;

  @override
  Widget build(BuildContext context) {
    return _AccountCard(
      wideLayout: wideLayout,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: centerHeaderContent
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
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
                  mainAxisAlignment: centerHeaderContent
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
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
                    if (subtitleWidget != null) ...<Widget>[
                      const SizedBox(height: 4),
                      subtitleWidget!,
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

class _AccountInfoGroup extends StatelessWidget {
  const _AccountInfoGroup({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.panelMutedBackground.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: <Widget>[
          for (int index = 0; index < children.length; index++) ...<Widget>[
            if (index > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 84,
                endIndent: 16,
                color: palette.border.withValues(alpha: 0.9),
              ),
            children[index],
          ],
        ],
      ),
    );
  }
}

class _AccountInfoListRow extends StatelessWidget {
  const _AccountInfoListRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 52,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Icon(
                icon,
                size: 24,
                color: palette.secondaryText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _CloudConnectionSelector extends StatelessWidget {
  const _CloudConnectionSelector({
    required this.connectionLabel,
    required this.optionLabel,
    required this.selectedMode,
    required this.onSelected,
  });

  final String connectionLabel;
  final String optionLabel;
  final CloudContentMode selectedMode;
  final ValueChanged<CloudContentMode>? onSelected;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);

    return SizedBox(
      height: 22,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Tooltip(
          message: optionLabel,
          child: _CloudModeMenuButton(
            connectionLabel: connectionLabel,
            selectedMode: selectedMode,
            onSelected: onSelected,
            textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.secondaryText,
                ),
          ),
        ),
      ),
    );
  }
}

class _OfficialCloudUsageVisual extends StatelessWidget {
  const _OfficialCloudUsageVisual({
    required this.icon,
    required this.percentText,
    required this.tooltipText,
    required this.palette,
    required this.colorScheme,
  });

  final IconData icon;
  final String percentText;
  final String tooltipText;
  final ReaderPalette palette;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Tooltip(
          message: tooltipText,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              _buildUsageButton(
                icon: icon,
                style: _UsageVisualStyle.filled,
                shape: M3EButtonShape.square,
                size:
                    M3EButtonSize.custom(width: 164, height: 132, hPadding: 22),
                background: colorScheme.primaryContainer,
                foreground: colorScheme.onPrimaryContainer,
              ),
              IgnorePointer(
                child: Text(
                  percentText,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        color: colorScheme.onPrimaryContainer,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsageButton({
    required IconData icon,
    required _UsageVisualStyle style,
    required M3EButtonShape shape,
    required M3EButtonSize size,
    required Color background,
    required Color foreground,
  }) {
    final M3EButtonDecoration decoration = M3EButtonDecoration.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      borderRadius: shape == M3EButtonShape.square ? 22 : 28,
      side: BorderSide(color: palette.border.withValues(alpha: 0.45)),
      haptic: M3EHapticFeedback.none,
    );

    final Widget buttonChild = Icon(icon);
    switch (style) {
      case _UsageVisualStyle.filled:
        return IgnorePointer(
          child: M3EFilledButton(
            onPressed: () {},
            shape: shape,
            size: size,
            decoration: decoration,
            child: buttonChild,
          ),
        );
      case _UsageVisualStyle.tonal:
        return IgnorePointer(
          child: M3EFilledButton.tonal(
            onPressed: () {},
            shape: shape,
            size: size,
            decoration: decoration,
            child: buttonChild,
          ),
        );
      case _UsageVisualStyle.elevated:
        return IgnorePointer(
          child: M3EElevatedButton(
            onPressed: () {},
            shape: shape,
            size: size,
            decoration: decoration,
            child: buttonChild,
          ),
        );
      case _UsageVisualStyle.outlined:
        return IgnorePointer(
          child: M3EOutlinedButton(
            onPressed: () {},
            shape: shape,
            size: size,
            decoration: decoration,
            child: buttonChild,
          ),
        );
    }
  }
}

class _CloudModeMenuButton extends StatelessWidget {
  const _CloudModeMenuButton({
    required this.connectionLabel,
    required this.selectedMode,
    required this.onSelected,
    required this.textStyle,
  });

  final String connectionLabel;
  final CloudContentMode selectedMode;
  final ValueChanged<CloudContentMode>? onSelected;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final String officialLabel = _localizedText(
      context,
      zhHans: '折纸云',
      zhHant: '摺紙雲',
      en: 'Origami Cloud',
    );
    final String privateLabel = _localizedText(
      context,
      zhHans: '个人云',
      zhHant: '個人雲',
      en: 'Personal Cloud',
    );

    return PopupMenuButton<CloudContentMode>(
      enabled: onSelected != null,
      tooltip: '',
      onSelected: onSelected,
      padding: EdgeInsets.zero,
      color: palette.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<CloudContentMode>>[
        PopupMenuItem<CloudContentMode>(
          value: CloudContentMode.official,
          child: _CloudModeMenuItem(
            label: officialLabel,
            selected: selectedMode == CloudContentMode.official,
          ),
        ),
        PopupMenuItem<CloudContentMode>(
          value: CloudContentMode.privateCloud,
          child: _CloudModeMenuItem(
            label: privateLabel,
            selected: selectedMode == CloudContentMode.privateCloud,
          ),
        ),
      ],
      child: Opacity(
        opacity: onSelected == null ? 0.55 : 1,
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: <Widget>[
            Text(
              connectionLabel,
              style: textStyle?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(
              Icons.unfold_more_rounded,
              size: 18,
              color: palette.secondaryText,
            ),
          ],
        ),
      ),
    );
  }

  String _localizedText(
    BuildContext context, {
    required String zhHans,
    String? zhHant,
    required String en,
  }) {
    final Locale locale = Localizations.localeOf(context);
    if (locale.languageCode == 'zh') {
      final bool traditional =
          locale.scriptCode == 'Hant' || locale.countryCode == 'TW';
      return traditional ? (zhHant ?? zhHans) : zhHans;
    }
    return en;
  }
}

class _CloudModeMenuItem extends StatelessWidget {
  const _CloudModeMenuItem({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = Theme.of(context).colorScheme.primary;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? selectedColor : null,
                ),
          ),
        ),
        if (selected)
          Icon(
            Icons.check_rounded,
            color: selectedColor,
            size: 20,
          ),
      ],
    );
  }
}

enum _UsageVisualStyle {
  filled,
  tonal,
  elevated,
  outlined,
}

class _PrivateCloudServerSheet extends StatefulWidget {
  const _PrivateCloudServerSheet({
    required this.initialProtocol,
    required this.initialBaseUrl,
    required this.initialUsername,
    required this.initialPassword,
    required this.initialBasePath,
    required this.initialAdvancedModeEnabled,
  });

  final PrivateCloudProtocol initialProtocol;
  final String initialBaseUrl;
  final String initialUsername;
  final String initialPassword;
  final String initialBasePath;
  final bool initialAdvancedModeEnabled;

  @override
  State<_PrivateCloudServerSheet> createState() =>
      _PrivateCloudServerSheetState();
}

class _PrivateCloudServerSheetState extends State<_PrivateCloudServerSheet> {
  late final TextEditingController _baseUrlController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _basePathController;
  late PrivateCloudProtocol _protocol;
  late bool _advancedModeEnabled;
  String? _baseUrlError;

  @override
  void initState() {
    super.initState();
    _protocol = widget.initialProtocol;
    _advancedModeEnabled = widget.initialAdvancedModeEnabled;
    _baseUrlController = TextEditingController(text: widget.initialBaseUrl);
    _usernameController = TextEditingController(text: widget.initialUsername);
    _passwordController = TextEditingController(text: widget.initialPassword);
    _basePathController = TextEditingController(
      text: widget.initialBasePath.isEmpty
          ? '/resonance/'
          : widget.initialBasePath,
    );
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _basePathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = AppTheme.paletteOf(context);
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.panelBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _localizedText(
                    context,
                    zhHans: '个人云服务器',
                    zhHant: '個人雲伺服器',
                    en: 'Personal Cloud Server',
                  ),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<PrivateCloudProtocol>(
                  initialValue: _protocol,
                  decoration: InputDecoration(
                    labelText: _localizedText(
                      context,
                      zhHans: '协议',
                      zhHant: '協定',
                      en: 'Protocol',
                    ),
                  ),
                  items: <DropdownMenuItem<PrivateCloudProtocol>>[
                    DropdownMenuItem<PrivateCloudProtocol>(
                      value: PrivateCloudProtocol.webdav,
                      child: const Text('WebDAV'),
                    ),
                  ],
                  onChanged: (PrivateCloudProtocol? value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _protocol = value;
                    });
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _baseUrlController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: _localizedText(
                      context,
                      zhHans: '地址',
                      zhHant: '位址',
                      en: 'Address',
                    ),
                    hintText: 'https://dav.example.com/webdav',
                    errorText: _baseUrlError,
                  ),
                  onChanged: (_) {
                    if (_baseUrlError != null) {
                      setState(() {
                        _baseUrlError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: _localizedText(
                      context,
                      zhHans: '用户名',
                      zhHant: '使用者名稱',
                      en: 'Username',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: _localizedText(
                      context,
                      zhHans: '密码',
                      zhHant: '密碼',
                      en: 'Password',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _basePathController,
                  decoration: InputDecoration(
                    labelText: _localizedText(
                      context,
                      zhHans: '路径',
                      zhHant: '路徑',
                      en: 'Path',
                    ),
                    hintText: '/resonance/',
                  ),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _advancedModeEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _advancedModeEnabled = value;
                    });
                  },
                  title: Text(
                    _localizedText(
                      context,
                      zhHans: '高级模式',
                      zhHant: '進階模式',
                      en: 'Advanced Mode',
                    ),
                  ),
                  subtitle: Text(
                    _localizedText(
                      context,
                      zhHans: '开启后，创建身份、输入身份代码、用户名和头像也都会走个人云。',
                      zhHant: '開啟後，建立身分、輸入身分代碼、使用者名稱與頭像也都會改走個人雲。',
                      en: 'When enabled, identity creation, sign-in, user name, and avatar sync also use the personal cloud.',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(MaterialLocalizations.of(context)
                            .cancelButtonLabel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submit,
                        child: Text(
                          _localizedText(
                            context,
                            zhHans: '保存',
                            zhHant: '儲存',
                            en: 'Save',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    final String normalizedBaseUrl =
        normalizePrivateCloudBaseUrl(_baseUrlController.text);
    if (normalizedBaseUrl.isEmpty || Uri.tryParse(normalizedBaseUrl) == null) {
      setState(() {
        _baseUrlError = _localizedText(
          context,
          zhHans: '请输入可用的 WebDAV 地址。',
          zhHant: '請輸入可用的 WebDAV 位址。',
          en: 'Enter a valid WebDAV address.',
        );
      });
      return;
    }

    Navigator.of(context).pop(
      _PrivateCloudServerConfigResult(
        protocol: _protocol,
        baseUrl: normalizedBaseUrl,
        username: _usernameController.text,
        password: _passwordController.text,
        basePath: normalizePrivateCloudBasePath(_basePathController.text),
        advancedModeEnabled: _advancedModeEnabled,
      ),
    );
  }

  String _localizedText(
    BuildContext context, {
    required String zhHans,
    String? zhHant,
    required String en,
  }) {
    final Locale locale = Localizations.localeOf(context);
    if (locale.languageCode == 'zh') {
      final bool traditional =
          locale.scriptCode == 'Hant' || locale.countryCode == 'TW';
      return traditional ? (zhHant ?? zhHans) : zhHans;
    }
    return en;
  }
}

class _PrivateCloudServerConfigResult {
  const _PrivateCloudServerConfigResult({
    required this.protocol,
    required this.baseUrl,
    required this.username,
    required this.password,
    required this.basePath,
    required this.advancedModeEnabled,
  });

  final PrivateCloudProtocol protocol;
  final String baseUrl;
  final String username;
  final String password;
  final String basePath;
  final bool advancedModeEnabled;
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

    return Container(
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
    );
  }
}
