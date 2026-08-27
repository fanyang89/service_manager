import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Service Manager'**
  String get appName;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @addService.
  ///
  /// In en, this message translates to:
  /// **'Add service'**
  String get addService;

  /// No description provided for @editService.
  ///
  /// In en, this message translates to:
  /// **'Edit service'**
  String get editService;

  /// No description provided for @deleteService.
  ///
  /// In en, this message translates to:
  /// **'Delete service'**
  String get deleteService;

  /// No description provided for @noServices.
  ///
  /// In en, this message translates to:
  /// **'No services yet'**
  String get noServices;

  /// No description provided for @noServicesDescription.
  ///
  /// In en, this message translates to:
  /// **'Add a local program to manage it here.'**
  String get noServicesDescription;

  /// No description provided for @selectService.
  ///
  /// In en, this message translates to:
  /// **'Select a service'**
  String get selectService;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @startAll.
  ///
  /// In en, this message translates to:
  /// **'Start all'**
  String get startAll;

  /// No description provided for @stopAll.
  ///
  /// In en, this message translates to:
  /// **'Stop all'**
  String get stopAll;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @executable.
  ///
  /// In en, this message translates to:
  /// **'Executable'**
  String get executable;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @arguments.
  ///
  /// In en, this message translates to:
  /// **'Arguments'**
  String get arguments;

  /// No description provided for @argumentsHint.
  ///
  /// In en, this message translates to:
  /// **'One argument per line'**
  String get argumentsHint;

  /// No description provided for @workingDirectory.
  ///
  /// In en, this message translates to:
  /// **'Working directory'**
  String get workingDirectory;

  /// No description provided for @environment.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get environment;

  /// No description provided for @environmentHint.
  ///
  /// In en, this message translates to:
  /// **'One KEY=VALUE pair per line'**
  String get environmentHint;

  /// No description provided for @stopExecutable.
  ///
  /// In en, this message translates to:
  /// **'Stop executable'**
  String get stopExecutable;

  /// No description provided for @stopArguments.
  ///
  /// In en, this message translates to:
  /// **'Stop arguments'**
  String get stopArguments;

  /// No description provided for @startAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Start with Service Manager'**
  String get startAutomatically;

  /// No description provided for @restartAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Restart after unexpected exit'**
  String get restartAutomatically;

  /// No description provided for @stopTimeout.
  ///
  /// In en, this message translates to:
  /// **'Stop timeout'**
  String get stopTimeout;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @pid.
  ///
  /// In en, this message translates to:
  /// **'PID'**
  String get pid;

  /// No description provided for @startedAt.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get startedAt;

  /// No description provided for @exitCode.
  ///
  /// In en, this message translates to:
  /// **'Exit code'**
  String get exitCode;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// No description provided for @clearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearLogs;

  /// No description provided for @openLogFolder.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get openLogFolder;

  /// No description provided for @pauseLogs.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseLogs;

  /// No description provided for @resumeLogs.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeLogs;

  /// No description provided for @searchLogs.
  ///
  /// In en, this message translates to:
  /// **'Search logs'**
  String get searchLogs;

  /// No description provided for @followLogs.
  ///
  /// In en, this message translates to:
  /// **'Follow output'**
  String get followLogs;

  /// No description provided for @noLogs.
  ///
  /// In en, this message translates to:
  /// **'No logs'**
  String get noLogs;

  /// No description provided for @launchAtLogin.
  ///
  /// In en, this message translates to:
  /// **'Launch at login'**
  String get launchAtLogin;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @simplifiedChinese.
  ///
  /// In en, this message translates to:
  /// **'Simplified Chinese'**
  String get simplifiedChinese;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @behavior.
  ///
  /// In en, this message translates to:
  /// **'Behavior'**
  String get behavior;

  /// No description provided for @logRetention.
  ///
  /// In en, this message translates to:
  /// **'Log retention'**
  String get logRetention;

  /// No description provided for @logRetentionDescription.
  ///
  /// In en, this message translates to:
  /// **'Five 5 MiB files per service'**
  String get logRetentionDescription;

  /// No description provided for @deleteServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteServiceTitle({required String name});

  /// No description provided for @deleteServiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Its configuration and logs will be removed.'**
  String get deleteServiceMessage;

  /// No description provided for @exitTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit Service Manager?'**
  String get exitTitle;

  /// No description provided for @exitMessage.
  ///
  /// In en, this message translates to:
  /// **'Running services will be stopped before exit.'**
  String get exitMessage;

  /// No description provided for @stopAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop all services?'**
  String get stopAllTitle;

  /// No description provided for @stopAllMessage.
  ///
  /// In en, this message translates to:
  /// **'All running services will be stopped.'**
  String get stopAllMessage;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @invalidEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Use KEY=VALUE on each line'**
  String get invalidEnvironment;

  /// No description provided for @executableNotFound.
  ///
  /// In en, this message translates to:
  /// **'Executable does not exist'**
  String get executableNotFound;

  /// No description provided for @directoryNotFound.
  ///
  /// In en, this message translates to:
  /// **'Working directory does not exist'**
  String get directoryNotFound;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save configuration: {error}'**
  String saveFailed({required String error});

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed: {error}'**
  String operationFailed({required String error});

  /// No description provided for @configurationRecovered.
  ///
  /// In en, this message translates to:
  /// **'The configuration was damaged and moved to {path}.'**
  String configurationRecovered({required String path});

  /// No description provided for @runningCount.
  ///
  /// In en, this message translates to:
  /// **'{running, plural, =0{No services running} =1{1 service running} other{{running} services running}}'**
  String runningCount({required int running});

  /// No description provided for @statusStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get statusStopped;

  /// No description provided for @statusStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get statusStarting;

  /// No description provided for @statusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get statusRunning;

  /// No description provided for @statusStopping.
  ///
  /// In en, this message translates to:
  /// **'Stopping'**
  String get statusStopping;

  /// No description provided for @statusRestarting.
  ///
  /// In en, this message translates to:
  /// **'Restarting'**
  String get statusRestarting;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @stdout.
  ///
  /// In en, this message translates to:
  /// **'OUT'**
  String get stdout;

  /// No description provided for @stderr.
  ///
  /// In en, this message translates to:
  /// **'ERR'**
  String get stderr;

  /// No description provided for @manager.
  ///
  /// In en, this message translates to:
  /// **'MANAGER'**
  String get manager;

  /// No description provided for @serviceNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a service name'**
  String get serviceNameRequired;

  /// No description provided for @plainTextEnvironmentWarning.
  ///
  /// In en, this message translates to:
  /// **'Environment values are stored as plain text.'**
  String get plainTextEnvironmentWarning;

  /// No description provided for @unexpectedExit.
  ///
  /// In en, this message translates to:
  /// **'Process exited unexpectedly with code {code}.'**
  String unexpectedExit({required int code});

  /// No description provided for @restartLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Automatic restart limit reached.'**
  String get restartLimitReached;

  /// No description provided for @launchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to launch: {error}'**
  String launchFailed({required String error});
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
