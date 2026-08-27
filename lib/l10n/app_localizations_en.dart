// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Service Manager';

  @override
  String get services => 'Services';

  @override
  String get settings => 'Settings';

  @override
  String get addService => 'Add service';

  @override
  String get editService => 'Edit service';

  @override
  String get deleteService => 'Delete service';

  @override
  String get noServices => 'No services yet';

  @override
  String get noServicesDescription => 'Add a local program to manage it here.';

  @override
  String get selectService => 'Select a service';

  @override
  String get start => 'Start';

  @override
  String get stop => 'Stop';

  @override
  String get restart => 'Restart';

  @override
  String get startAll => 'Start all';

  @override
  String get stopAll => 'Stop all';

  @override
  String get open => 'Open';

  @override
  String get exit => 'Exit';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get name => 'Name';

  @override
  String get executable => 'Executable';

  @override
  String get browse => 'Browse';

  @override
  String get arguments => 'Arguments';

  @override
  String get argumentsHint => 'One argument per line';

  @override
  String get workingDirectory => 'Working directory';

  @override
  String get environment => 'Environment';

  @override
  String get environmentHint => 'One KEY=VALUE pair per line';

  @override
  String get stopExecutable => 'Stop executable';

  @override
  String get stopArguments => 'Stop arguments';

  @override
  String get startAutomatically => 'Start with Service Manager';

  @override
  String get restartAutomatically => 'Restart after unexpected exit';

  @override
  String get stopTimeout => 'Stop timeout';

  @override
  String get seconds => 'seconds';

  @override
  String get status => 'Status';

  @override
  String get pid => 'PID';

  @override
  String get startedAt => 'Started';

  @override
  String get exitCode => 'Exit code';

  @override
  String get logs => 'Logs';

  @override
  String get clearLogs => 'Clear';

  @override
  String get openLogFolder => 'Open folder';

  @override
  String get pauseLogs => 'Pause';

  @override
  String get resumeLogs => 'Resume';

  @override
  String get searchLogs => 'Search logs';

  @override
  String get followLogs => 'Follow output';

  @override
  String get noLogs => 'No logs';

  @override
  String get launchAtLogin => 'Launch at login';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'System default';

  @override
  String get english => 'English';

  @override
  String get simplifiedChinese => 'Simplified Chinese';

  @override
  String get appearance => 'Appearance';

  @override
  String get behavior => 'Behavior';

  @override
  String get logRetention => 'Log retention';

  @override
  String get logRetentionDescription => 'Five 5 MiB files per service';

  @override
  String deleteServiceTitle({required String name}) {
    return 'Delete $name?';
  }

  @override
  String get deleteServiceMessage =>
      'Its configuration and logs will be removed.';

  @override
  String get exitTitle => 'Exit Service Manager?';

  @override
  String get exitMessage => 'Running services will be stopped before exit.';

  @override
  String get stopAllTitle => 'Stop all services?';

  @override
  String get stopAllMessage => 'All running services will be stopped.';

  @override
  String get requiredField => 'Required';

  @override
  String get invalidEnvironment => 'Use KEY=VALUE on each line';

  @override
  String get executableNotFound => 'Executable does not exist';

  @override
  String get directoryNotFound => 'Working directory does not exist';

  @override
  String saveFailed({required String error}) {
    return 'Could not save configuration: $error';
  }

  @override
  String operationFailed({required String error}) {
    return 'Operation failed: $error';
  }

  @override
  String configurationRecovered({required String path}) {
    return 'The configuration was damaged and moved to $path.';
  }

  @override
  String runningCount({required int running}) {
    String _temp0 = intl.Intl.pluralLogic(
      running,
      locale: localeName,
      other: '$running services running',
      one: '1 service running',
      zero: 'No services running',
    );
    return '$_temp0';
  }

  @override
  String get statusStopped => 'Stopped';

  @override
  String get statusStarting => 'Starting';

  @override
  String get statusRunning => 'Running';

  @override
  String get statusStopping => 'Stopping';

  @override
  String get statusRestarting => 'Restarting';

  @override
  String get statusFailed => 'Failed';

  @override
  String get stdout => 'OUT';

  @override
  String get stderr => 'ERR';

  @override
  String get manager => 'MANAGER';

  @override
  String get serviceNameRequired => 'Enter a service name';

  @override
  String get plainTextEnvironmentWarning =>
      'Environment values are stored as plain text.';

  @override
  String unexpectedExit({required int code}) {
    return 'Process exited unexpectedly with code $code.';
  }

  @override
  String get restartLimitReached => 'Automatic restart limit reached.';

  @override
  String launchFailed({required String error}) {
    return 'Failed to launch: $error';
  }
}
