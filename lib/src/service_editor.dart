import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'models.dart';
import 'path_picker.dart';

Future<ServiceConfig?> showServiceEditor(
  BuildContext context, {
  ServiceConfig? service,
}) {
  return showDialog<ServiceConfig>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ServiceEditor(service: service),
  );
}

class _ServiceEditor extends StatefulWidget {
  const _ServiceEditor({this.service});

  final ServiceConfig? service;

  @override
  State<_ServiceEditor> createState() => _ServiceEditorState();
}

class _ServiceEditorState extends State<_ServiceEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _executable;
  late final TextEditingController _arguments;
  late final TextEditingController _workingDirectory;
  late final TextEditingController _environment;
  late final TextEditingController _stopExecutable;
  late final TextEditingController _stopArguments;
  late final TextEditingController _timeout;
  late bool _startAutomatically;
  late bool _restartAutomatically;
  late bool _advancedExpanded;
  String? _environmentError;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    _name = TextEditingController(text: service?.name);
    _executable = TextEditingController(text: service?.executable);
    _arguments = TextEditingController(text: service?.arguments.join('\n'));
    _workingDirectory = TextEditingController(text: service?.workingDirectory);
    _environment = TextEditingController(
      text: service?.environment.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('\n'),
    );
    _stopExecutable = TextEditingController(text: service?.stopExecutable);
    _stopArguments = TextEditingController(
      text: service?.stopArguments.join('\n'),
    );
    _timeout = TextEditingController(
      text: '${service?.stopTimeoutSeconds ?? 10}',
    );
    _startAutomatically = service?.startAutomatically ?? false;
    _restartAutomatically = service?.restartAutomatically ?? false;
    _advancedExpanded =
        service != null &&
        (service.environment.isNotEmpty ||
            service.stopExecutable.isNotEmpty ||
            service.stopArguments.isNotEmpty ||
            service.stopTimeoutSeconds != 10);
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _executable,
      _arguments,
      _workingDirectory,
      _environment,
      _stopExecutable,
      _stopArguments,
      _timeout,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  List<String> _lines(TextEditingController controller) => controller.text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  Map<String, String>? _parseEnvironment() {
    final values = <String, String>{};
    for (final line in _lines(_environment)) {
      final separator = line.indexOf('=');
      if (separator <= 0) return null;
      values[line.substring(0, separator).trim()] = line.substring(
        separator + 1,
      );
    }
    return values;
  }

  void _save() {
    final localizations = AppLocalizations.of(context);
    final environment = _parseEnvironment();
    setState(() {
      _environmentError = environment == null
          ? localizations.invalidEnvironment
          : null;
      if (environment == null) _advancedExpanded = true;
    });
    if (!_formKey.currentState!.validate() || environment == null) return;
    final timeout = int.tryParse(_timeout.text)?.clamp(1, 300) ?? 10;
    Navigator.of(context).pop(
      ServiceConfig(
        id: widget.service?.id ?? createServiceId(),
        name: _name.text.trim(),
        executable: _executable.text.trim(),
        arguments: _lines(_arguments),
        workingDirectory: _workingDirectory.text.trim(),
        environment: environment,
        stopExecutable: _stopExecutable.text.trim(),
        stopArguments: _lines(_stopArguments),
        startAutomatically: _startAutomatically,
        restartAutomatically: _restartAutomatically,
        stopTimeoutSeconds: timeout,
      ),
    );
  }

  Future<void> _pickExecutable(TextEditingController controller) async {
    final path = await pickExecutablePath();
    if (path != null) controller.text = path;
  }

  Future<void> _pickDirectory() async {
    final path = await pickDirectoryPath();
    if (path != null) _workingDirectory.text = path;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.service == null
                          ? localizations.addService
                          : localizations.editService,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(28),
                  children: [
                    _SectionHeading(title: localizations.basicSettings),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _name,
                      decoration: InputDecoration(
                        labelText: localizations.name,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? localizations.serviceNameRequired
                          : null,
                      autofocus: true,
                    ),
                    const SizedBox(height: 18),
                    _PathField(
                      controller: _executable,
                      label: localizations.executable,
                      onBrowse: kIsWeb
                          ? null
                          : () => _pickExecutable(_executable),
                      requiredMessage: localizations.requiredField,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _arguments,
                      decoration: InputDecoration(
                        labelText: localizations.arguments,
                        hintText: localizations.argumentsHint,
                        alignLabelWithHint: true,
                      ),
                      minLines: 2,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 18),
                    _PathField(
                      controller: _workingDirectory,
                      label: localizations.workingDirectory,
                      onBrowse: kIsWeb ? null : _pickDirectory,
                    ),
                    const SizedBox(height: 28),
                    _SectionHeading(title: localizations.behavior),
                    const SizedBox(height: 10),
                    _BehaviorOptions(
                      startAutomatically: _startAutomatically,
                      restartAutomatically: _restartAutomatically,
                      onStartAutomaticallyChanged: (value) =>
                          setState(() => _startAutomatically = value),
                      onRestartAutomaticallyChanged: (value) =>
                          setState(() => _restartAutomatically = value),
                    ),
                    const SizedBox(height: 24),
                    _AdvancedSection(
                      expanded: _advancedExpanded,
                      title: localizations.advancedSettings,
                      description: localizations.advancedSettingsDescription,
                      onToggle: () => setState(
                        () => _advancedExpanded = !_advancedExpanded,
                      ),
                      children: [
                        TextFormField(
                          controller: _environment,
                          decoration: InputDecoration(
                            labelText: localizations.environment,
                            hintText: localizations.environmentHint,
                            helperText:
                                localizations.plainTextEnvironmentWarning,
                            errorText: _environmentError,
                            alignLabelWithHint: true,
                          ),
                          minLines: 2,
                          maxLines: 5,
                        ),
                        const SizedBox(height: 18),
                        _PathField(
                          controller: _stopExecutable,
                          label: localizations.stopExecutable,
                          onBrowse: kIsWeb
                              ? null
                              : () => _pickExecutable(_stopExecutable),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _stopArguments,
                          decoration: InputDecoration(
                            labelText: localizations.stopArguments,
                            hintText: localizations.argumentsHint,
                            alignLabelWithHint: true,
                          ),
                          minLines: 2,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _timeout,
                          decoration: InputDecoration(
                            labelText: localizations.stopTimeout,
                            suffixText: localizations.seconds,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(localizations.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _save,
                    child: Text(localizations.save),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _BehaviorOptions extends StatelessWidget {
  const _BehaviorOptions({
    required this.startAutomatically,
    required this.restartAutomatically,
    required this.onStartAutomaticallyChanged,
    required this.onRestartAutomaticallyChanged,
  });

  final bool startAutomatically;
  final bool restartAutomatically;
  final ValueChanged<bool> onStartAutomaticallyChanged;
  final ValueChanged<bool> onRestartAutomaticallyChanged;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SwitchListTile(
            value: startAutomatically,
            title: Text(localizations.startAutomatically),
            onChanged: onStartAutomaticallyChanged,
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: colors.outlineVariant,
          ),
          SwitchListTile(
            value: restartAutomatically,
            title: Text(localizations.restartAutomatically),
            onChanged: onRestartAutomaticallyChanged,
          ),
        ],
      ),
    );
  }
}

class _AdvancedSection extends StatelessWidget {
  const _AdvancedSection({
    required this.expanded,
    required this.title,
    required this.description,
    required this.onToggle,
    required this.children,
  });

  final bool expanded;
  final String title;
  final String description;
  final VoidCallback onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            onTap: onToggle,
            leading: const Icon(Icons.tune),
            title: Text(title),
            subtitle: Text(description),
            trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
          ),
          if (expanded) ...[
            Divider(height: 1, color: colors.outlineVariant),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: children),
            ),
          ],
        ],
      ),
    );
  }
}

class _PathField extends StatelessWidget {
  const _PathField({
    required this.controller,
    required this.label,
    this.onBrowse,
    this.requiredMessage,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback? onBrowse;
  final String? requiredMessage;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: onBrowse == null
            ? null
            : IconButton(
                onPressed: onBrowse,
                tooltip: AppLocalizations.of(context).browse,
                icon: const Icon(Icons.folder_open_outlined),
              ),
      ),
      validator: requiredMessage == null
          ? null
          : (value) =>
                value == null || value.trim().isEmpty ? requiredMessage : null,
    );
  }
}
