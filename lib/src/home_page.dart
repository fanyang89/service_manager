import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'controller.dart';
import 'models.dart';
import 'service_editor.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.controller,
    required this.onSetLaunchAtLogin,
    this.onOpenLogDirectory,
    this.onExit,
    this.onLocalizationsChanged,
    this.showLaunchAtLogin = true,
    super.key,
  });

  final ServiceController controller;
  final Future<void> Function(bool enabled) onSetLaunchAtLogin;
  final Future<void> Function()? onOpenLogDirectory;
  final Future<void> Function()? onExit;
  final void Function(AppLocalizations localizations)? onLocalizationsChanged;
  final bool showLaunchAtLogin;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedId;
  StreamSubscription<void>? _subscription;
  String? _reportedLocale;

  ServiceRecord? get _selected {
    for (final service in widget.controller.services) {
      if (service.config.id == _selectedId) return service;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _subscription = widget.controller.changes.listen((_) {
      if (!mounted) return;
      if (_selected == null && widget.controller.services.isNotEmpty) {
        _selectedId = widget.controller.services.first.config.id;
      }
      setState(() {});
    });
    if (widget.controller.services.isNotEmpty) {
      _selectedId = widget.controller.services.first.config.id;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localizations = AppLocalizations.of(context);
    if (_reportedLocale != localizations.localeName) {
      _reportedLocale = localizations.localeName;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onLocalizationsChanged?.call(localizations);
      });
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  Future<void> _run(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (error) {
      if (!mounted) return;
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.operationFailed(error: '$error'))),
      );
    }
  }

  Future<void> _addService() async {
    final config = await showServiceEditor(context);
    if (config == null) return;
    await _run(() => widget.controller.addService(config));
    if (mounted && widget.controller.services.isNotEmpty) {
      setState(() => _selectedId = widget.controller.services.last.config.id);
    }
  }

  Future<void> _editService(ServiceRecord service) async {
    final config = await showServiceEditor(context, service: service.config);
    if (config != null) {
      await _run(() => widget.controller.updateService(config));
    }
  }

  Future<void> _deleteService(ServiceRecord service) async {
    final localizations = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          localizations.deleteServiceTitle(name: service.config.name),
        ),
        content: Text(localizations.deleteServiceMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: Text(localizations.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(() => widget.controller.deleteService(service.config.id));
      if (mounted) setState(() => _selectedId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final recoveredPath = widget.controller.recoveredConfigPath;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              runningCount: widget.controller.runningCount,
              onStartAll: () => _run(widget.controller.startAll),
              onStopAll: () => _run(widget.controller.stopAll),
              onSettings: _showSettings,
            ),
            if (recoveredPath != null)
              MaterialBanner(
                content: Text(
                  localizations.configurationRecovered(path: recoveredPath),
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        ScaffoldMessenger.of(context)
                            .hideCurrentMaterialBanner(),
                    child: Text(localizations.confirm),
                  ),
                ],
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 760;
                  if (narrow && _selected != null) {
                    return _ServiceDetail(
                      service: _selected!,
                      controller: widget.controller,
                      onBack: () => setState(() => _selectedId = null),
                      onEdit: () => _editService(_selected!),
                      onDelete: () => _deleteService(_selected!),
                      onOperation: _run,
                      onOpenLogDirectory: widget.onOpenLogDirectory,
                    );
                  }
                  final list = _ServiceList(
                    services: widget.controller.services,
                    selectedId: _selectedId,
                    onSelected: (service) =>
                        setState(() => _selectedId = service.config.id),
                    onAdd: _addService,
                  );
                  if (narrow) return list;
                  return Row(
                    children: [
                      SizedBox(width: 310, child: list),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: _selected == null
                            ? _EmptyDetail(onAdd: _addService)
                            : _ServiceDetail(
                                service: _selected!,
                                controller: widget.controller,
                                onEdit: () => _editService(_selected!),
                                onDelete: () => _deleteService(_selected!),
                                onOperation: _run,
                                onOpenLogDirectory: widget.onOpenLogDirectory,
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSettings() async {
    await showDialog<void>(
      context: context,
      builder: (context) => _SettingsDialog(
        controller: widget.controller,
        onSetLaunchAtLogin: widget.onSetLaunchAtLogin,
        onExit: widget.onExit,
        showLaunchAtLogin: widget.showLaunchAtLogin,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.runningCount,
    required this.onStartAll,
    required this.onStopAll,
    required this.onSettings,
  });

  final int runningCount;
  final VoidCallback onStartAll;
  final VoidCallback onStopAll;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 14, 14),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.dns_outlined,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.appName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                localizations.runningCount(running: runningCount),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: onStartAll,
            tooltip: localizations.startAll,
            icon: const Icon(Icons.play_arrow_rounded),
          ),
          IconButton(
            onPressed: onStopAll,
            tooltip: localizations.stopAll,
            icon: const Icon(Icons.stop_rounded),
          ),
          IconButton(
            onPressed: onSettings,
            tooltip: localizations.settings,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
    );
  }
}

class _ServiceList extends StatelessWidget {
  const _ServiceList({
    required this.services,
    required this.selectedId,
    required this.onSelected,
    required this.onAdd,
  });

  final List<ServiceRecord> services;
  final String? selectedId;
  final ValueChanged<ServiceRecord> onSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    localizations.services,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: onAdd,
                  tooltip: localizations.addService,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: services.isEmpty
                ? _EmptyList(onAdd: onAdd)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return StreamBuilder<void>(
                        stream: service.changes,
                        builder: (context, _) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            selected: service.config.id == selectedId,
                            selectedTileColor: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: _StatusDot(status: service.status),
                            title: Text(
                              service.config.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              _statusText(localizations, service.status),
                            ),
                            onTap: () => onSelected(service),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ServiceDetail extends StatelessWidget {
  const _ServiceDetail({
    required this.service,
    required this.controller,
    required this.onEdit,
    required this.onDelete,
    required this.onOperation,
    this.onBack,
    this.onOpenLogDirectory,
  });

  final ServiceRecord service;
  final ServiceController controller;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(Future<void> Function() operation) onOperation;
  final VoidCallback? onBack;
  final Future<void> Function()? onOpenLogDirectory;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: service.changes,
      builder: (context, _) {
        final localizations = AppLocalizations.of(context);
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (onBack != null)
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.config.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service.config.executable,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onEdit,
                    tooltip: localizations.editService,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    tooltip: localizations.deleteService,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: service.isActive
                        ? null
                        : () => onOperation(() => controller.start(service)),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(localizations.start),
                  ),
                  OutlinedButton.icon(
                    onPressed: service.isActive
                        ? () => onOperation(() => controller.stop(service))
                        : null,
                    icon: const Icon(Icons.stop),
                    label: Text(localizations.stop),
                  ),
                  OutlinedButton.icon(
                    onPressed: service.status == ServiceStatus.running
                        ? () => onOperation(() => controller.restart(service))
                        : null,
                    icon: const Icon(Icons.refresh),
                    label: Text(localizations.restart),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _RuntimeSummary(service: service),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    localizations.logs,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () =>
                        onOperation(() => controller.clearLogs(service)),
                    tooltip: localizations.clearLogs,
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
                  if (onOpenLogDirectory != null)
                    IconButton(
                      onPressed: () => onOperation(onOpenLogDirectory!),
                      tooltip: localizations.openLogFolder,
                      icon: const Icon(Icons.folder_open_outlined),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(child: _LogView(logs: service.logs)),
            ],
          ),
        );
      },
    );
  }
}

class _RuntimeSummary extends StatelessWidget {
  const _RuntimeSummary({required this.service});

  final ServiceRecord service;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _InfoChip(
          label: localizations.status,
          value: _statusText(localizations, service.status),
        ),
        if (service.pid != null)
          _InfoChip(label: localizations.pid, value: '${service.pid}'),
        if (service.startedAt != null)
          _InfoChip(
            label: localizations.startedAt,
            value: DateFormat.Hms().format(service.startedAt!),
          ),
        if (service.exitCode != null)
          _InfoChip(
            label: localizations.exitCode,
            value: '${service.exitCode}',
          ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text('$label  $value'),
      ),
    );
  }
}

class _LogView extends StatelessWidget {
  const _LogView({required this.logs});

  final List<LogEntry> logs;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (logs.isEmpty) {
      return Center(child: Text(localizations.noLogs));
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff17201e),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.all(14),
        itemCount: logs.length,
        itemBuilder: (context, reverseIndex) {
          final entry = logs[logs.length - reverseIndex - 1];
          final color = switch (entry.source) {
            LogSource.stdout => const Color(0xffd7e4df),
            LogSource.stderr => const Color(0xffff9b91),
            LogSource.manager => const Color(0xff72d4ba),
          };
          return Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: SelectableText.rich(
              TextSpan(
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '${DateFormat.Hms().format(entry.timestamp)}  ',
                    style: const TextStyle(color: Color(0xff81908c)),
                  ),
                  TextSpan(
                    text: entry.message,
                    style: TextStyle(color: color),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final ServiceStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ServiceStatus.running => const Color(0xff1f9d74),
      ServiceStatus.starting ||
      ServiceStatus.restarting => const Color(0xffdf8d21),
      ServiceStatus.failed => Theme.of(context).colorScheme.error,
      ServiceStatus.stopping => const Color(0xff8b7da8),
      ServiceStatus.stopped => const Color(0xff8d9995),
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.layers_clear_outlined, size: 42),
            const SizedBox(height: 14),
            Text(localizations.noServices),
            const SizedBox(height: 6),
            Text(
              localizations.noServicesDescription,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(localizations.addService),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(AppLocalizations.of(context).selectService));
  }
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog({
    required this.controller,
    required this.onSetLaunchAtLogin,
    this.onExit,
    required this.showLaunchAtLogin,
  });

  final ServiceController controller;
  final Future<void> Function(bool enabled) onSetLaunchAtLogin;
  final VoidCallback? onExit;
  final bool showLaunchAtLogin;

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  bool _updatingLogin = false;

  Future<void> _setLocale(String? value) async {
    await widget.controller.updateSettings(
      widget.controller.settings.copyWith(
        localeCode: value,
        clearLocale: value == null,
      ),
    );
  }

  Future<void> _setLaunchAtLogin(bool value) async {
    setState(() => _updatingLogin = true);
    try {
      await widget.onSetLaunchAtLogin(value);
    } finally {
      if (mounted) setState(() => _updatingLogin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(localizations.settings),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String?>(
              initialValue: widget.controller.settings.localeCode,
              decoration: InputDecoration(labelText: localizations.language),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(localizations.systemLanguage),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(localizations.english),
                ),
                DropdownMenuItem(
                  value: 'zh',
                  child: Text(localizations.simplifiedChinese),
                ),
              ],
              onChanged: _setLocale,
            ),
            const SizedBox(height: 14),
            if (widget.showLaunchAtLogin)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(localizations.launchAtLogin),
                value: widget.controller.settings.launchAtLogin,
                onChanged: _updatingLogin ? null : _setLaunchAtLogin,
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(localizations.logRetention),
              subtitle: Text(localizations.logRetentionDescription),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.onExit != null)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onExit!();
            },
            child: Text(localizations.exit),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(localizations.confirm),
        ),
      ],
    );
  }
}

String _statusText(AppLocalizations localizations, ServiceStatus status) =>
    switch (status) {
      ServiceStatus.stopped => localizations.statusStopped,
      ServiceStatus.starting => localizations.statusStarting,
      ServiceStatus.running => localizations.statusRunning,
      ServiceStatus.stopping => localizations.statusStopping,
      ServiceStatus.restarting => localizations.statusRestarting,
      ServiceStatus.failed => localizations.statusFailed,
    };
