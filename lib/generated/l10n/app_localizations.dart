import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_no.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_sv.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('nl'),
    Locale('no'),
    Locale('pl'),
    Locale('pt'),
    Locale('sv')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Game Map Master'**
  String get appTitle;

  /// Title for language selection dialog
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Yes button text
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No button text
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit button text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Create button text
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Error message title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Success message title
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Warning message title
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// Information message title
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get info;

  /// Message shown during login process
  ///
  /// In en, this message translates to:
  /// **'Connection in progress...'**
  String get connectionInProgress;

  /// Message shown when sending login credentials
  ///
  /// In en, this message translates to:
  /// **'Sending credentials to AuthService...'**
  String get sendingCredentials;

  /// Message shown when login is successful
  ///
  /// In en, this message translates to:
  /// **'Connection successful. Starting session restoration...'**
  String get connectionSuccessful;

  /// Message shown when session might be restored
  ///
  /// In en, this message translates to:
  /// **'Field session potentially restored.'**
  String get sessionPotentiallyRestored;

  /// Message shown during automatic reconnection
  ///
  /// In en, this message translates to:
  /// **'Automatic user reconnection to field...'**
  String get automaticReconnection;

  /// Message shown when successfully rejoined a field
  ///
  /// In en, this message translates to:
  /// **'Rejoined field successfully. Reloading session...'**
  String get rejoinedFieldSuccessfully;

  /// Message shown when user is already connected
  ///
  /// In en, this message translates to:
  /// **'User already connected to field.'**
  String get userAlreadyConnected;

  /// Message shown when no active field or user
  ///
  /// In en, this message translates to:
  /// **'No active field or user not defined.'**
  String get noActiveFieldOrUser;

  /// Error message for automatic reconnection failure
  ///
  /// In en, this message translates to:
  /// **'Error during automatic reconnection attempt'**
  String get automaticReconnectionError;

  /// Username field label
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Register button text
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// First name field label
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// Last name field label
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// Field management tab title
  ///
  /// In en, this message translates to:
  /// **'Field Management'**
  String get fieldManagement;

  /// Maps management tab title
  ///
  /// In en, this message translates to:
  /// **'Maps Management'**
  String get mapsManagement;

  /// Scenarios management tab title
  ///
  /// In en, this message translates to:
  /// **'Scenarios Management'**
  String get scenariosManagement;

  /// Players management tab title
  ///
  /// In en, this message translates to:
  /// **'Players Management'**
  String get playersManagement;

  /// Open field button text
  ///
  /// In en, this message translates to:
  /// **'Open Field'**
  String get openField;

  /// Close field button text
  ///
  /// In en, this message translates to:
  /// **'Close Field'**
  String get closeField;

  /// Start game button text
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get startGame;

  /// Stop game button text
  ///
  /// In en, this message translates to:
  /// **'Stop Game'**
  String get stopGame;

  /// Game time label
  ///
  /// In en, this message translates to:
  /// **'Game Time'**
  String get gameTime;

  /// Select map label
  ///
  /// In en, this message translates to:
  /// **'Select Map'**
  String get selectMap;

  /// Select scenarios label
  ///
  /// In en, this message translates to:
  /// **'Select Scenarios'**
  String get selectScenarios;

  /// Connected players label
  ///
  /// In en, this message translates to:
  /// **'Connected Players'**
  String get connectedPlayers;

  /// Teams label
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get teams;

  /// Create team button text
  ///
  /// In en, this message translates to:
  /// **'Create Team'**
  String get createTeam;

  /// Team name field label
  ///
  /// In en, this message translates to:
  /// **'Team Name'**
  String get teamName;

  /// Join team button text
  ///
  /// In en, this message translates to:
  /// **'Join Team'**
  String get joinTeam;

  /// Leave team button text
  ///
  /// In en, this message translates to:
  /// **'Leave Team'**
  String get leaveTeam;

  /// Invite players button text
  ///
  /// In en, this message translates to:
  /// **'Invite Players'**
  String get invitePlayers;

  /// Search players placeholder
  ///
  /// In en, this message translates to:
  /// **'Search Players'**
  String get searchPlayers;

  /// Send invitation button text
  ///
  /// In en, this message translates to:
  /// **'Send Invitation'**
  String get sendInvitation;

  /// Accept invitation button text
  ///
  /// In en, this message translates to:
  /// **'Accept Invitation'**
  String get acceptInvitation;

  /// Decline invitation button text
  ///
  /// In en, this message translates to:
  /// **'Decline Invitation'**
  String get declineInvitation;

  /// Invitations section title
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get invitations;

  /// Message when no invitations available
  ///
  /// In en, this message translates to:
  /// **'No invitations'**
  String get noInvitations;

  /// Map name field label
  ///
  /// In en, this message translates to:
  /// **'Map Name'**
  String get mapName;

  /// Map description field label
  ///
  /// In en, this message translates to:
  /// **'Map Description'**
  String get mapDescription;

  /// Create map button text
  ///
  /// In en, this message translates to:
  /// **'Create Map'**
  String get createMap;

  /// Edit map button text
  ///
  /// In en, this message translates to:
  /// **'Edit Map'**
  String get editMap;

  /// Delete map button text
  ///
  /// In en, this message translates to:
  /// **'Delete Map'**
  String get deleteMap;

  /// Scenario name field label
  ///
  /// In en, this message translates to:
  /// **'Scenario Name'**
  String get scenarioName;

  /// Scenario description field label
  ///
  /// In en, this message translates to:
  /// **'Scenario Description'**
  String get scenarioDescription;

  /// Create scenario button text
  ///
  /// In en, this message translates to:
  /// **'Create Scenario'**
  String get createScenario;

  /// Edit scenario button text
  ///
  /// In en, this message translates to:
  /// **'Edit Scenario'**
  String get editScenario;

  /// Delete scenario button text
  ///
  /// In en, this message translates to:
  /// **'Delete Scenario'**
  String get deleteScenario;

  /// Treasure hunt scenario name
  ///
  /// In en, this message translates to:
  /// **'Treasure Hunt'**
  String get treasureHunt;

  /// Bomb defusal scenario name
  ///
  /// In en, this message translates to:
  /// **'Bomb Defusal'**
  String get bombDefusal;

  /// Capture the flag scenario name
  ///
  /// In en, this message translates to:
  /// **'Capture The Flag'**
  String get captureTheFlag;

  /// GPS quality indicator label
  ///
  /// In en, this message translates to:
  /// **'GPS Quality'**
  String get gpsQuality;

  /// Speed indicator label
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// Stationary movement state
  ///
  /// In en, this message translates to:
  /// **'Stationary'**
  String get stationary;

  /// Walking movement state
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get walking;

  /// Running movement state
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// Tactical movement state
  ///
  /// In en, this message translates to:
  /// **'Tactical'**
  String get tactical;

  /// Immobile state for GPS
  ///
  /// In en, this message translates to:
  /// **'Immobile'**
  String get immobile;

  /// Game history section title
  ///
  /// In en, this message translates to:
  /// **'Game History'**
  String get gameHistory;

  /// Game replay section title
  ///
  /// In en, this message translates to:
  /// **'Game Replay'**
  String get gameReplay;

  /// Session details title
  ///
  /// In en, this message translates to:
  /// **'Session Details'**
  String get sessionDetails;

  /// Duration label
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// Start time label
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// End time label
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// Participants label
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participants;

  /// Settings section title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Notifications setting label
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Sound setting label
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// Vibration setting label
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// About section title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Logout confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get confirmLogout;

  /// Network error message
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get networkError;

  /// Server error message
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get serverError;

  /// Invalid credentials error message
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password.'**
  String get invalidCredentials;

  /// Required field validation message
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get fieldRequired;

  /// Invalid email validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get emailInvalid;

  /// Password too short validation message
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters long.'**
  String get passwordTooShort;

  /// Passwords mismatch validation message
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// Welcome message for users
  ///
  /// In en, this message translates to:
  /// **'Welcome to Game Map Master!'**
  String get welcomeMessage;

  /// Game in progress status
  ///
  /// In en, this message translates to:
  /// **'Game in Progress'**
  String get gameInProgress;

  /// Game finished status
  ///
  /// In en, this message translates to:
  /// **'Game Finished'**
  String get gameFinished;

  /// Waiting for players status
  ///
  /// In en, this message translates to:
  /// **'Waiting for Players'**
  String get waitingForPlayers;

  /// Field closed status
  ///
  /// In en, this message translates to:
  /// **'Field Closed'**
  String get fieldClosed;

  /// Field open status
  ///
  /// In en, this message translates to:
  /// **'Field Open'**
  String get fieldOpen;

  /// Prompt asking the user to enter their username
  ///
  /// In en, this message translates to:
  /// **'Please enter your username'**
  String get promptUsername;

  /// Prompt asking the user to enter their password
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get promptPassword;

  /// Title of the registration screen
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerTitle;

  /// Text displayed as heading to create a new account
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccount;

  /// Label for username field
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// Prompt asking the user to enter a username
  ///
  /// In en, this message translates to:
  /// **'Please enter a username'**
  String get usernamePrompt;

  /// Label for email field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Prompt asking the user to enter their email
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailPrompt;

  /// Label for password field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Prompt asking the user to enter a password
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get passwordPrompt;

  /// Label for confirm password field
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// Prompt asking the user to confirm their password
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordPrompt;

  /// Label for first name field
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstNameLabel;

  /// Label for last name field
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastNameLabel;

  /// Label for phone number field
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// Label for selecting user role
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// Prompt asking the user to select a role
  ///
  /// In en, this message translates to:
  /// **'Please select a role'**
  String get rolePrompt;

  /// Role option for host/organizer
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get roleHost;

  /// Role option for gamer/player
  ///
  /// In en, this message translates to:
  /// **'Gamer'**
  String get roleGamer;

  /// Register button text
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// Prompt for users already registered to log in
  ///
  /// In en, this message translates to:
  /// **'Already registered? Log in'**
  String get alreadyRegistered;

  /// Message shown when registration succeeds
  ///
  /// In en, this message translates to:
  /// **'Registration successful! You can now log in.'**
  String get registrationSuccess;

  /// Message shown when registration fails
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get registrationFailure;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'es', 'fr', 'it', 'ja', 'nl', 'no', 'pl', 'pt', 'sv'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'it': return AppLocalizationsIt();
    case 'ja': return AppLocalizationsJa();
    case 'nl': return AppLocalizationsNl();
    case 'no': return AppLocalizationsNo();
    case 'pl': return AppLocalizationsPl();
    case 'pt': return AppLocalizationsPt();
    case 'sv': return AppLocalizationsSv();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
