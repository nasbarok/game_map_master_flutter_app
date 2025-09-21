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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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

  /// Message shown when login fails
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your credentials.'**
  String get loginFailed;

  /// Title on the splash screen
  ///
  /// In en, this message translates to:
  /// **'Game Map Master'**
  String get splashTitle;

  /// Subtitle on the splash screen
  ///
  /// In en, this message translates to:
  /// **'Créez et jouez des scénarios 2.0'**
  String get splashSubtitle;

  /// Subtitle on the splash screen
  ///
  /// In en, this message translates to:
  /// **'Create and play 2.0 scenarios'**
  String get splashScreenSubtitle;

  /// Title for the game lobby screen
  ///
  /// In en, this message translates to:
  /// **'Game Lobby'**
  String get gameLobbyTitle;

  /// Label for the Field tab
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get terrainTab;

  /// Label for the Players tab
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get playersTab;

  /// Label showing the current map name
  ///
  /// In en, this message translates to:
  /// **'Map: {mapName}'**
  String mapLabel(Object mapName);

  /// Placeholder for an unknown map name
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownMap;

  /// Tooltip for the session history button
  ///
  /// In en, this message translates to:
  /// **'Sessions history'**
  String get sessionsHistoryTooltip;

  /// Message when no field is associated with the map
  ///
  /// In en, this message translates to:
  /// **'No associated field found'**
  String get noAssociatedField;

  /// Label showing the remaining game time
  ///
  /// In en, this message translates to:
  /// **'Time remaining: {time}'**
  String remainingTimeLabel(Object time);

  /// Title for the game in progress section
  ///
  /// In en, this message translates to:
  /// **'Game in progress'**
  String get gameInProgressTitle;

  /// Instructions for players when a game is in progress
  ///
  /// In en, this message translates to:
  /// **'Follow the host\'s instructions and collaborate with your team to achieve the scenario objectives.'**
  String get gameInProgressInstructions;

  /// Button text to join an ongoing game
  ///
  /// In en, this message translates to:
  /// **'Join Game'**
  String get joinGameButton;

  /// Title when waiting for the host to start the game
  ///
  /// In en, this message translates to:
  /// **'Waiting for game to start'**
  String get waitingForGameStartTitle;

  /// Instructions for players when waiting for the game to start
  ///
  /// In en, this message translates to:
  /// **'The host has not started the game yet. Prepare your gear and join a team while you wait.'**
  String get waitingForGameStartInstructions;

  /// Button text to leave the current field
  ///
  /// In en, this message translates to:
  /// **'Leave Field'**
  String get leaveFieldButton;

  /// Message when no scenario is selected for the game
  ///
  /// In en, this message translates to:
  /// **'No scenario selected'**
  String get noScenarioSelected;

  /// Label for the list of selected scenarios
  ///
  /// In en, this message translates to:
  /// **'Selected scenarios:'**
  String get selectedScenariosLabel;

  /// Details for a treasure hunt scenario
  ///
  /// In en, this message translates to:
  /// **'Treasure Hunt: {count} QR codes ({symbol})'**
  String treasureHuntScenarioDetails(Object count, Object symbol);

  /// Placeholder for when an item has no description
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// Generic error message with a placeholder for the error details
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String loadingError(Object error);

  /// Message when the user has not visited any fields yet
  ///
  /// In en, this message translates to:
  /// **'No fields visited'**
  String get noFieldsVisited;

  /// Instruction to wait for an invitation
  ///
  /// In en, this message translates to:
  /// **'Wait for an invitation to join a field'**
  String get waitForInvitation;

  /// Indicates when a field was opened
  ///
  /// In en, this message translates to:
  /// **'Opened on {date}'**
  String fieldOpenedOn(Object date);

  /// Placeholder for an unknown field opening date
  ///
  /// In en, this message translates to:
  /// **'Unknown opening date'**
  String get unknownOpeningDate;

  /// Indicates when a field was closed
  ///
  /// In en, this message translates to:
  /// **'Closed on {date}'**
  String fieldClosedOn(Object date);

  /// Status indication that a field is still active
  ///
  /// In en, this message translates to:
  /// **'Still active'**
  String get stillActive;

  /// Label showing the owner of a field
  ///
  /// In en, this message translates to:
  /// **'Owner: {username}'**
  String ownerLabel(Object username);

  /// Placeholder for an unknown field owner
  ///
  /// In en, this message translates to:
  /// **'Unknown owner'**
  String get unknownOwner;

  /// Status indicating a field is open
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get fieldStatusOpen;

  /// Status indicating a field is closed
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get fieldStatusClosed;

  /// Generic join button text
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinButton;

  /// Tooltip for the delete from history button
  ///
  /// In en, this message translates to:
  /// **'Delete from history'**
  String get deleteFromHistoryTooltip;

  /// Success message when a user joins a field
  ///
  /// In en, this message translates to:
  /// **'You have successfully joined the field'**
  String get youJoinedFieldSuccess;

  /// Message when a user leaves a field
  ///
  /// In en, this message translates to:
  /// **'You have left the field'**
  String get youLeftField;

  /// Message when the user is not connected to any field
  ///
  /// In en, this message translates to:
  /// **'You are not connected to a field'**
  String get notConnectedToField;

  /// Label showing the number of connected players
  ///
  /// In en, this message translates to:
  /// **'Connected players ({count})'**
  String connectedPlayersCount(Object count);

  /// Message when no players are connected
  ///
  /// In en, this message translates to:
  /// **'No player connected'**
  String get noPlayerConnected;

  /// Indicates that a player is not in any team
  ///
  /// In en, this message translates to:
  /// **'No team'**
  String get noTeam;

  /// Label to identify the current user
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youLabel;

  /// Label for the user's current team section
  ///
  /// In en, this message translates to:
  /// **'Your team'**
  String get yourTeamLabel;

  /// Button text to navigate to team management
  ///
  /// In en, this message translates to:
  /// **'Manage teams'**
  String get manageTeamsButton;

  /// Title for the change team dialog
  ///
  /// In en, this message translates to:
  /// **'Change team'**
  String get changeTeamTitle;

  /// Suffix for player count, handles pluralization
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =0{players} =1{player} other{players}}'**
  String playersCountSuffix(num count);

  /// Title for the leave field confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Leave field?'**
  String get leaveFieldConfirmationTitle;

  /// Confirmation message when a user tries to leave a field
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this field? You will not be able to rejoin if it is closed.'**
  String get leaveFieldConfirmationMessage;

  /// Button text for leaving an action or a place
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveButton;

  /// Title for the delete field from history confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete this field?'**
  String get deleteFieldHistoryTitle;

  /// Confirmation message when deleting a field from history
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this field from your history?'**
  String get deleteFieldHistoryMessage;

  /// Success message when a field is deleted from history
  ///
  /// In en, this message translates to:
  /// **'Field deleted from history'**
  String get fieldDeletedFromHistory;

  /// Error message when field deletion fails
  ///
  /// In en, this message translates to:
  /// **'Error during deletion'**
  String get errorDeletingField;

  /// Error message when a user cannot join a game
  ///
  /// In en, this message translates to:
  /// **'Cannot join game'**
  String get cannotJoinGame;

  /// Title for the join team screen
  ///
  /// In en, this message translates to:
  /// **'Join a team'**
  String get joinTeamTitle;

  /// Error message when teams fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading teams: {error}'**
  String errorLoadingTeams(Object error);

  /// Button text to retry an action
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// Title shown when no teams are available to join
  ///
  /// In en, this message translates to:
  /// **'No teams available'**
  String get noTeamsAvailableTitle;

  /// Message shown when no teams are available, prompting user to ask organizer
  ///
  /// In en, this message translates to:
  /// **'Ask an organizer to create a team'**
  String get noTeamsAvailableMessage;

  /// Button text to refresh data
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshButton;

  /// Success message when a user joins a team
  ///
  /// In en, this message translates to:
  /// **'You have joined team {teamName}'**
  String joinedTeamSuccess(Object teamName);

  /// Title for the team management screen
  ///
  /// In en, this message translates to:
  /// **'Team Management'**
  String get teamManagementTitle;

  /// Alternative error message when teams fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading teams'**
  String get errorLoadingTeamsAlt;

  /// Alternative success message when a user joins a team
  ///
  /// In en, this message translates to:
  /// **'Successfully joined the team'**
  String get joinedTeamSuccessAlt;

  /// Error message when failing to join a team
  ///
  /// In en, this message translates to:
  /// **'Error joining team: {error}'**
  String errorJoiningTeam(Object error);

  /// Message shown to players when no teams are created by the host yet
  ///
  /// In en, this message translates to:
  /// **'Wait for the host to create teams'**
  String get noTeamsAvailableHostMessage;

  /// Label for a chip indicating the user's team
  ///
  /// In en, this message translates to:
  /// **'Your team'**
  String get yourTeamChip;

  /// Message shown when there are no connected players to display
  ///
  /// In en, this message translates to:
  /// **'Connected players will appear here'**
  String get noPlayersConnectedMessage;

  /// Title for the game map screen
  ///
  /// In en, this message translates to:
  /// **'Game Map'**
  String get gameMapScreenTitle;

  /// Tooltip for the fullscreen button
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get fullscreenTooltip;

  /// Tooltip for the satellite view button
  ///
  /// In en, this message translates to:
  /// **'Satellite view'**
  String get satelliteViewTooltip;

  /// Tooltip for the standard map view button
  ///
  /// In en, this message translates to:
  /// **'Standard view'**
  String get standardViewTooltip;

  /// Label showing remaining time for a bomb
  ///
  /// In en, this message translates to:
  /// **'BOMB: {time}'**
  String bombTimeRemaining(Object time);

  /// Tooltip for the center on location button
  ///
  /// In en, this message translates to:
  /// **'Center on current location'**
  String get centerOnLocationTooltip;

  /// Error message when centering on location fails
  ///
  /// In en, this message translates to:
  /// **'Error centering on current location: {error}'**
  String errorCenteringLocation(Object error);

  /// Label for a player marker on the map if username is not available
  ///
  /// In en, this message translates to:
  /// **'Player {playerName}'**
  String playerMarkerLabel(Object playerName);

  /// Title for the game session screen
  ///
  /// In en, this message translates to:
  /// **'Game Session'**
  String get gameSessionScreenTitle;

  /// Error message when game session data fails to load
  ///
  /// In en, this message translates to:
  /// **'Error loading session data: {error}'**
  String errorLoadingSessionData(Object error);

  /// Tooltip for the end game button
  ///
  /// In en, this message translates to:
  /// **'End game'**
  String get endGameTooltip;

  /// Tooltip for the refresh button
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// Message shown while the bomb scenario is loading
  ///
  /// In en, this message translates to:
  /// **'Loading Bomb scenario...'**
  String get bombScenarioLoading;

  /// Button text to open QR code scanner when game is active
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get qrScannerButtonActive;

  /// Message shown when trying to scan QR for non-existent treasure hunt
  ///
  /// In en, this message translates to:
  /// **'No active treasure hunt scenario'**
  String get noActiveTreasureHunt;

  /// Message shown when the game has been stopped/ended
  ///
  /// In en, this message translates to:
  /// **'The game has ended.'**
  String get gameEndedMessage;

  /// Error message when failing to end a game
  ///
  /// In en, this message translates to:
  /// **'Error ending game: {error}'**
  String errorEndingGame(Object error);

  /// Message shown in scoreboard when there are no scores
  ///
  /// In en, this message translates to:
  /// **'No scores to display yet'**
  String get noScoresYet;

  /// Notification message when a player from a team finds a treasure
  ///
  /// In en, this message translates to:
  /// **'{username} from team {teamName} found a treasure worth {points} points! ({symbol})'**
  String treasureFoundNotification(
      Object username, Object teamName, Object points, Object symbol);

  /// Notification message when a player (no team) finds a treasure
  ///
  /// In en, this message translates to:
  /// **'{username} found a treasure worth {points} points! ({symbol})'**
  String treasureFoundNotificationNoTeam(
      Object username, Object points, Object symbol);

  /// Title for the field sessions screen, showing the field name
  ///
  /// In en, this message translates to:
  /// **'Sessions - {fieldName}'**
  String fieldSessionsTitle(Object fieldName);

  /// Placeholder for an unknown field name
  ///
  /// In en, this message translates to:
  /// **'Unknown Field'**
  String get unknownField;

  /// Generic title for game sessions screen if field name is not available
  ///
  /// In en, this message translates to:
  /// **'Game Sessions'**
  String get gameSessionsTitle;

  /// Generic error message when data loading fails
  ///
  /// In en, this message translates to:
  /// **'Error loading data: {error}'**
  String errorLoadingData(Object error);

  /// Message shown when a field has no game sessions
  ///
  /// In en, this message translates to:
  /// **'No game sessions available for this field'**
  String get noGameSessionsForField;

  /// Title for a list item representing a game session, with its index
  ///
  /// In en, this message translates to:
  /// **'Session #{index}'**
  String sessionListItemTitle(Object index);

  /// Label showing the status of a game session
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String sessionStatusLabel(Object status);

  /// Label showing the start and end time of a game session
  ///
  /// In en, this message translates to:
  /// **'Start: {startTime} - End: {endTime}'**
  String sessionTimeLabel(Object startTime, Object endTime);

  /// Label showing only the start time of a game session (if end time is not available)
  ///
  /// In en, this message translates to:
  /// **'Start: {startTime}'**
  String sessionStartTimeLabel(Object startTime);

  /// Success message when a game session is deleted
  ///
  /// In en, this message translates to:
  /// **'Game session deleted successfully'**
  String get deleteSessionSuccess;

  /// Generic confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get confirmation;

  /// Confirmation message when attempting to delete a game session
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this game session?'**
  String get deleteSessionConfirmationMessage;

  /// Title for the game replay screen
  ///
  /// In en, this message translates to:
  /// **'Session Replay'**
  String get replayScreenTitle;

  /// Title for the scenario summary dialog in replay
  ///
  /// In en, this message translates to:
  /// **'Scenarios Summary'**
  String get scenarioSummaryTitle;

  /// Message shown when scenario information is not available in replay
  ///
  /// In en, this message translates to:
  /// **'No information available'**
  String get scenarioInfoNotAvailable;

  /// Label for playback speed control in replay
  ///
  /// In en, this message translates to:
  /// **'Speed: {speed}x'**
  String playbackSpeedLabel(Object speed);

  /// Error message when loading replay history fails
  ///
  /// In en, this message translates to:
  /// **'Error loading history: {error}'**
  String errorLoadingHistory(Object error);

  /// Title for the session details screen
  ///
  /// In en, this message translates to:
  /// **'Session Details'**
  String get sessionDetailsScreenTitle;

  /// Title for a specific session, including its index
  ///
  /// In en, this message translates to:
  /// **'Session #{index}'**
  String sessionTitleWithIndex(Object index);

  /// Message when specific session data cannot be found
  ///
  /// In en, this message translates to:
  /// **'Session not found'**
  String get noSessionFound;

  /// Tooltip for the button to view all sessions of a field
  ///
  /// In en, this message translates to:
  /// **'View sessions for this field'**
  String get viewSessionsForFieldTooltip;

  /// Label showing the field name
  ///
  /// In en, this message translates to:
  /// **'Field: {fieldName}'**
  String fieldLabel(Object fieldName);

  /// Label for the end time of a session
  ///
  /// In en, this message translates to:
  /// **'End: {time}'**
  String endTimeLabel(Object time);

  /// Label showing the number of participants in a session
  ///
  /// In en, this message translates to:
  /// **'Participants: {count}'**
  String participantsLabel(Object count);

  /// Button text to view the replay of a session
  ///
  /// In en, this message translates to:
  /// **'View Replay'**
  String get viewReplayButton;

  /// Label for the scenarios section
  ///
  /// In en, this message translates to:
  /// **'Scenarios'**
  String get scenariosLabel;

  /// Default name for a scenario if not specified
  ///
  /// In en, this message translates to:
  /// **'Unnamed Scenario'**
  String get scenarioNameDefault;

  /// Title for the treasure hunt scoreboard section
  ///
  /// In en, this message translates to:
  /// **'Treasure Hunt Scoreboard'**
  String get treasureHuntScoreboardTitle;

  /// Title for the bomb operation results section
  ///
  /// In en, this message translates to:
  /// **'Bomb Operation Results'**
  String get bombOperationResultsTitle;

  /// Label for team scores table/section
  ///
  /// In en, this message translates to:
  /// **'Team Scores'**
  String get teamScoresLabel;

  /// Label for individual scores table/section
  ///
  /// In en, this message translates to:
  /// **'Individual Scores'**
  String get individualScoresLabel;

  /// Table header for rank
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get rankLabel;

  /// Table header for name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// Table header for treasures found
  ///
  /// In en, this message translates to:
  /// **'Treasures'**
  String get treasuresLabel;

  /// Table header for score
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get scoreLabel;

  /// Name for the Terrorists team in Bomb Operation
  ///
  /// In en, this message translates to:
  /// **'Terrorists'**
  String get terroristsTeam;

  /// Name for the Counter-Terrorists team in Bomb Operation
  ///
  /// In en, this message translates to:
  /// **'Counter-Terrorists'**
  String get counterTerroristsTeam;

  /// Label for armed bomb sites
  ///
  /// In en, this message translates to:
  /// **'Armed Sites'**
  String get armedSitesLabel;

  /// Label for exploded bomb sites
  ///
  /// In en, this message translates to:
  /// **'Exploded Sites'**
  String get explodedSitesLabel;

  /// Label for active bomb sites
  ///
  /// In en, this message translates to:
  /// **'Active Sites'**
  String get activeSitesLabel;

  /// Label for disarmed bomb sites
  ///
  /// In en, this message translates to:
  /// **'Disarmed Sites'**
  String get disarmedSitesLabel;

  /// Result message when terrorists win
  ///
  /// In en, this message translates to:
  /// **'🔥 Terrorists Win'**
  String get terroristsWinResult;

  /// Result message when counter-terrorists win
  ///
  /// In en, this message translates to:
  /// **'🛡️ Counter-Terrorists Win'**
  String get counterTerroristsWinResult;

  /// Result message for a draw
  ///
  /// In en, this message translates to:
  /// **'🤝 Draw'**
  String get drawResult;

  /// Label for the detailed statistics section
  ///
  /// In en, this message translates to:
  /// **'Detailed Statistics'**
  String get detailedStatsLabel;

  /// Table header for statistic name
  ///
  /// In en, this message translates to:
  /// **'Statistic'**
  String get statisticLabel;

  /// Table header for statistic value
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get valueLabel;

  /// Statistic label for total bomb sites
  ///
  /// In en, this message translates to:
  /// **'Total Sites'**
  String get totalSitesStat;

  /// Statistic label for bomb timer duration
  ///
  /// In en, this message translates to:
  /// **'Bomb Timer'**
  String get bombTimerStat;

  /// Statistic label for bomb defuse time
  ///
  /// In en, this message translates to:
  /// **'Defuse Time'**
  String get defuseTimeStat;

  /// Statistic label for bomb arming time
  ///
  /// In en, this message translates to:
  /// **'Arming Time'**
  String get armingTimeStat;

  /// Title for the history screen when a specific field is selected
  ///
  /// In en, this message translates to:
  /// **'Field History'**
  String get historyScreenTitleField;

  /// Generic title for the history screen showing all fields
  ///
  /// In en, this message translates to:
  /// **'Fields History'**
  String get historyScreenTitleGeneric;

  /// Message shown when there are no fields in the history
  ///
  /// In en, this message translates to:
  /// **'No fields available'**
  String get noFieldsAvailable;

  /// Tooltip for the delete field button
  ///
  /// In en, this message translates to:
  /// **'Delete this field'**
  String get deleteFieldTooltip;

  /// Confirmation message when attempting to delete a field and its history
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete field \"{fieldName}\" and all its history?'**
  String deleteFieldConfirmationMessage(Object fieldName);

  /// Success message when a field is deleted
  ///
  /// In en, this message translates to:
  /// **'Field \"{fieldName}\" deleted'**
  String fieldDeletedSuccess(Object fieldName);

  /// Title for the new field form screen
  ///
  /// In en, this message translates to:
  /// **'New Field'**
  String get newFieldTitle;

  /// Title for the edit field form screen
  ///
  /// In en, this message translates to:
  /// **'Edit Field'**
  String get editFieldTitle;

  /// Label for the field name input
  ///
  /// In en, this message translates to:
  /// **'Field Name *'**
  String get fieldNameLabel;

  /// Label for the field description input
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get fieldDescriptionLabel;

  /// Label for the field address input
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get fieldAddressLabel;

  /// Label for the latitude input
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitudeLabel;

  /// Label for the longitude input
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitudeLabel;

  /// Label for the field width input
  ///
  /// In en, this message translates to:
  /// **'Width (m)'**
  String get widthLabel;

  /// Label for the field length input
  ///
  /// In en, this message translates to:
  /// **'Length (m)'**
  String get lengthLabel;

  /// Button text to create a new field
  ///
  /// In en, this message translates to:
  /// **'Create Field'**
  String get createFieldButton;

  /// Button text to update an existing field
  ///
  /// In en, this message translates to:
  /// **'Update Field'**
  String get updateFieldButton;

  /// Error message when field name is required but not provided
  ///
  /// In en, this message translates to:
  /// **'Please enter a name for the field'**
  String get fieldRequiredError;

  /// Success message when a field is saved
  ///
  /// In en, this message translates to:
  /// **'Field saved successfully'**
  String get fieldSavedSuccess;

  /// Title for the new map form screen
  ///
  /// In en, this message translates to:
  /// **'New Map'**
  String get newMapTitle;

  /// Label for the map scale input
  ///
  /// In en, this message translates to:
  /// **'Scale (m/pixel)'**
  String get scaleLabel;

  /// Error message when map name is required but not provided
  ///
  /// In en, this message translates to:
  /// **'Please enter a name for the map'**
  String get mapNameRequiredError;

  /// Error message for invalid map scale input
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid scale'**
  String get invalidScaleError;

  /// Label for the address of the field in interactive map editor
  ///
  /// In en, this message translates to:
  /// **'Field Address'**
  String get interactiveMapAddressLabel;

  /// Button text to define the interactive map features
  ///
  /// In en, this message translates to:
  /// **'Define Interactive Map'**
  String get defineInteractiveMapButton;

  /// Button text to edit the interactive map features
  ///
  /// In en, this message translates to:
  /// **'Edit Interactive Map'**
  String get editInteractiveMapButton;

  /// Success message when a map is saved
  ///
  /// In en, this message translates to:
  /// **'Map saved successfully'**
  String get mapSavedSuccess;

  /// Button text to update an existing map
  ///
  /// In en, this message translates to:
  /// **'Update Map'**
  String get updateMapButton;

  /// Title for the host dashboard screen
  ///
  /// In en, this message translates to:
  /// **'Host Dashboard'**
  String get hostDashboardTitle;

  /// Label for the History tab
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTab;

  /// Title for the invitation received dialog
  ///
  /// In en, this message translates to:
  /// **'Invitation Received'**
  String get invitationReceivedTitle;

  /// Message content for a received invitation
  ///
  /// In en, this message translates to:
  /// **'You have been invited by {username} to join the map \"{mapName}\".'**
  String invitationReceivedMessage(Object username, Object mapName);

  /// Snackbar message guiding user to the maps tab
  ///
  /// In en, this message translates to:
  /// **'Use the Maps tab to create or modify maps'**
  String get noActionForFieldTabSnackbar;

  /// Snackbar message asking user to open a field
  ///
  /// In en, this message translates to:
  /// **'Please open a field first'**
  String get openFieldFirstSnackbar;

  /// Message when no maps are available
  ///
  /// In en, this message translates to:
  /// **'No map'**
  String get noMapAvailable;

  /// Prompt to create a map when none exist
  ///
  /// In en, this message translates to:
  /// **'Create a map to get started'**
  String get createMapPrompt;

  /// Message when no scenarios are available
  ///
  /// In en, this message translates to:
  /// **'No scenario'**
  String get noScenarioAvailable;

  /// Prompt to create a scenario when none exist
  ///
  /// In en, this message translates to:
  /// **'Create a scenario to get started'**
  String get createScenarioPrompt;

  /// Button text to view the scoreboard
  ///
  /// In en, this message translates to:
  /// **'Scoreboard'**
  String get scoreboardButton;

  /// Generic title for deletion confirmation dialogs
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeleteTitle;

  /// Confirmation message for deleting a map
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this map?'**
  String get confirmDeleteMapMessage;

  /// Success message when a map is deleted
  ///
  /// In en, this message translates to:
  /// **'Map deleted successfully'**
  String get mapDeletedSuccess;

  /// Error message when map deletion fails
  ///
  /// In en, this message translates to:
  /// **'Error deleting map: {error}'**
  String errorDeletingMap(Object error);

  /// Confirmation message for deleting a scenario
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this scenario?'**
  String get confirmDeleteScenarioMessage;

  /// Success message when a scenario is deleted
  ///
  /// In en, this message translates to:
  /// **'Scenario deleted'**
  String get scenarioDeletedSuccess;

  /// Message when no teams have been created
  ///
  /// In en, this message translates to:
  /// **'No teams'**
  String get noTeamsCreated;

  /// Prompt to create a team when none exist
  ///
  /// In en, this message translates to:
  /// **'Create a team to get started'**
  String get createTeamPrompt;

  /// Title indicating that player management is currently unavailable
  ///
  /// In en, this message translates to:
  /// **'Players unavailable'**
  String get playersUnavailableTitle;

  /// Button text to navigate to the field tab
  ///
  /// In en, this message translates to:
  /// **'Go to Field Tab'**
  String get goToFieldTabButton;

  /// Error message when loading maps fails
  ///
  /// In en, this message translates to:
  /// **'Error loading maps: {error}'**
  String errorLoadingMaps(Object error);

  /// Error message when loading scenarios fails
  ///
  /// In en, this message translates to:
  /// **'Error loading scenarios: {error}'**
  String errorLoadingScenarios(Object error);

  /// Label for the Search tab
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTab;

  /// Hint text for the player search input field
  ///
  /// In en, this message translates to:
  /// **'Enter a username'**
  String get searchPlayersHint;

  /// Message displayed when player search yields no results
  ///
  /// In en, this message translates to:
  /// **'No results. Try another search.'**
  String get noResultsFound;

  /// Button text to send an invitation
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get inviteButton;

  /// Indicates who sent an invitation
  ///
  /// In en, this message translates to:
  /// **'Invitation from {username}'**
  String invitationFrom(Object username);

  /// Short label for map name, possibly in a list item
  ///
  /// In en, this message translates to:
  /// **'Map: {mapName}'**
  String mapLabelShort(Object mapName);

  /// Title for the section showing sent invitations
  ///
  /// In en, this message translates to:
  /// **'Invitations Sent'**
  String get invitationsSentTitle;

  /// Message when no invitations have been sent by the user
  ///
  /// In en, this message translates to:
  /// **'No invitations sent'**
  String get noInvitationsSent;

  /// Indicates to whom an invitation was sent
  ///
  /// In en, this message translates to:
  /// **'Invitation to {username}'**
  String invitationTo(Object username);

  /// Status of an invitation that is pending
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// Status of an invitation that has been accepted
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// Status of an invitation that has been declined
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get statusDeclined;

  /// Label for the list of players not yet assigned to a team
  ///
  /// In en, this message translates to:
  /// **'Unassigned Players'**
  String get unassignedPlayersLabel;

  /// Hint text for a dropdown or button to assign a team
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assignTeamHint;

  /// Tooltip for the kick player button
  ///
  /// In en, this message translates to:
  /// **'Kick Player'**
  String get kickPlayerTooltip;

  /// Tooltip for the remove player from team button
  ///
  /// In en, this message translates to:
  /// **'Remove from team'**
  String get removeFromTeamTooltip;

  /// Success message when a player is kicked
  ///
  /// In en, this message translates to:
  /// **'{playerName} has been kicked from the game'**
  String playerKickedSuccess(Object playerName);

  /// Error message when kicking a player fails
  ///
  /// In en, this message translates to:
  /// **'Error kicking player: {error}'**
  String errorKickingPlayer(Object error);

  /// Title shown when player management features are not available (e.g., field not open)
  ///
  /// In en, this message translates to:
  /// **'Player management unavailable'**
  String get playerManagementUnavailableTitle;

  /// Button text to create a new team
  ///
  /// In en, this message translates to:
  /// **'New Team'**
  String get newTeamButton;

  /// Button text to save team configuration
  ///
  /// In en, this message translates to:
  /// **'Save Configuration'**
  String get saveConfigurationButton;

  /// Title for the save team configuration dialog
  ///
  /// In en, this message translates to:
  /// **'Save Configuration'**
  String get saveConfigurationDialogTitle;

  /// Label for the configuration name input field
  ///
  /// In en, this message translates to:
  /// **'Configuration Name'**
  String get configurationNameLabel;

  /// Success message when team configuration is saved
  ///
  /// In en, this message translates to:
  /// **'Configuration saved'**
  String get configurationSavedSuccess;

  /// Title for the dialog to add players to a team
  ///
  /// In en, this message translates to:
  /// **'Add Players'**
  String get addPlayersToTeamDialogTitle;

  /// Label indicating a player is already in a team
  ///
  /// In en, this message translates to:
  /// **'Already in a team'**
  String get alreadyInTeamLabel;

  /// Generic add button text
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addButton;

  /// Title for the rename team dialog
  ///
  /// In en, this message translates to:
  /// **'Rename Team'**
  String get renameTeamDialogTitle;

  /// Label for the new team name input field
  ///
  /// In en, this message translates to:
  /// **'New Name'**
  String get newTeamNameLabel;

  /// Button text to confirm renaming
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameButton;

  /// Title for the QR code generator screen, indicating the scenario name
  ///
  /// In en, this message translates to:
  /// **'QR Code for {scenarioName}'**
  String qrCodeForScenarioTitle(Object scenarioName);

  /// Error message when QR code generation fails
  ///
  /// In en, this message translates to:
  /// **'Error generating QR code: {error}'**
  String errorGeneratingQRCode(Object error);

  /// Instructional message on the QR code screen
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code to join the game'**
  String get scanToJoinMessage;

  /// Label displaying the textual invitation code
  ///
  /// In en, this message translates to:
  /// **'Invitation Code: {code}'**
  String invitationCodeLabel(Object code);

  /// Message indicating the validity period of the QR code
  ///
  /// In en, this message translates to:
  /// **'This code is valid for 1 hour'**
  String get codeValidForHour;

  /// Button text to generate a new QR code
  ///
  /// In en, this message translates to:
  /// **'Generate New Code'**
  String get generateNewCodeButton;

  /// Title for the new scenario form screen
  ///
  /// In en, this message translates to:
  /// **'New Scenario'**
  String get newScenarioTitle;

  /// Label for the scenario type selection field
  ///
  /// In en, this message translates to:
  /// **'Scenario Type *'**
  String get scenarioTypeLabel;

  /// Scenario type option for Bomb Operation
  ///
  /// In en, this message translates to:
  /// **'Bomb Operation'**
  String get scenarioTypeBombOperation;

  /// Scenario type option for Domination
  ///
  /// In en, this message translates to:
  /// **'Domination'**
  String get scenarioTypeDomination;

  /// Error message when scenario name is required but not provided
  ///
  /// In en, this message translates to:
  /// **'Please enter a name for the scenario'**
  String get scenarioNameRequiredError;

  /// Error message when scenario type is required but not selected
  ///
  /// In en, this message translates to:
  /// **'Please select a scenario type'**
  String get scenarioTypeRequiredError;

  /// Error message when map is required for a scenario but not selected
  ///
  /// In en, this message translates to:
  /// **'Please select a map'**
  String get mapRequiredError;

  /// Error message when a scenario type requires an interactive map, but the selected map is not configured for it
  ///
  /// In en, this message translates to:
  /// **'This map does not have an interactive configuration. Please select another map or configure this one in the map editor.'**
  String get interactiveMapRequiredError;

  /// Success message when a scenario is saved
  ///
  /// In en, this message translates to:
  /// **'Scenario saved successfully'**
  String get scenarioSavedSuccess;

  /// Button text to update an existing scenario
  ///
  /// In en, this message translates to:
  /// **'Update Scenario'**
  String get updateScenarioButton;

  /// Button text to navigate to treasure hunt configuration
  ///
  /// In en, this message translates to:
  /// **'Configure Treasure Hunt'**
  String get configureTreasureHuntButton;

  /// Button text to navigate to bomb operation configuration
  ///
  /// In en, this message translates to:
  /// **'Configure Bomb Operation'**
  String get configureBombOperationButton;

  /// Error message shown in scenario form if no maps exist
  ///
  /// In en, this message translates to:
  /// **'No map available. Please create a map first.'**
  String get noMapAvailableError;

  /// Legend indicating that a map has interactive features available
  ///
  /// In en, this message translates to:
  /// **'Interactive map available'**
  String get interactiveMapAvailableLegend;

  /// Error message prompting user to select a map first
  ///
  /// In en, this message translates to:
  /// **'Please select a map before choosing the scenario type.'**
  String get selectMapFirstError;

  /// Title for the scenario selection dialog
  ///
  /// In en, this message translates to:
  /// **'Select Scenarios'**
  String get selectScenariosDialogTitle;

  /// Message shown in scenario selection dialog when no scenarios exist
  ///
  /// In en, this message translates to:
  /// **'No scenarios available.\nCreate a scenario first.'**
  String get noScenariosAvailableDialogMessage;

  /// Button text to validate a selection
  ///
  /// In en, this message translates to:
  /// **'Validate'**
  String get validateButton;

  /// Title for the new team form screen
  ///
  /// In en, this message translates to:
  /// **'New Team'**
  String get newTeamScreenTitle;

  /// Title for the edit team form screen
  ///
  /// In en, this message translates to:
  /// **'Edit Team'**
  String get editTeamTitle;

  /// Label for the team color selection field
  ///
  /// In en, this message translates to:
  /// **'Team Color'**
  String get teamColorLabel;

  /// Color option Red
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// Color option Blue
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// Color option Green
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// Color option Yellow
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get colorYellow;

  /// Color option Orange
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// Color option Purple
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorPurple;

  /// Color option Black
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get colorBlack;

  /// Color option White
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get colorWhite;

  /// Error message when team name is required but not provided
  ///
  /// In en, this message translates to:
  /// **'Please enter a name for the team'**
  String get teamNameRequiredError;

  /// Success message when a team is saved
  ///
  /// In en, this message translates to:
  /// **'Team saved successfully'**
  String get teamSavedSuccess;

  /// Button text to update an existing team
  ///
  /// In en, this message translates to:
  /// **'Update Team'**
  String get updateTeamButton;

  /// Error message when a map needs to be selected before an action
  ///
  /// In en, this message translates to:
  /// **'Please select a map first'**
  String get selectMapError;

  /// Success message when scenarios are selected
  ///
  /// In en, this message translates to:
  /// **'Scenarios selected'**
  String get scenariosSelectedSuccess;

  /// Success message when game duration is set
  ///
  /// In en, this message translates to:
  /// **'Duration set: {hours}h {minutes}min'**
  String durationSetSuccess(Object hours, Object minutes);

  /// Error message when starting a game fails
  ///
  /// In en, this message translates to:
  /// **'Error starting game: {error}'**
  String errorStartingGame(Object error);

  /// Success message when a game has started
  ///
  /// In en, this message translates to:
  /// **'The game has started!'**
  String get gameStartedSuccess;

  /// Error message when bomb scenario requirements (2 teams) are not met
  ///
  /// In en, this message translates to:
  /// **'Bomb Operation scenario requires exactly 2 teams with players.'**
  String get bombScenarioRequiresTwoTeamsError;

  /// Message indicating that bomb scenario configuration was cancelled
  ///
  /// In en, this message translates to:
  /// **'Configuration cancelled.'**
  String get bombConfigurationCancelled;

  /// Title for the bomb operation configuration dialog
  ///
  /// In en, this message translates to:
  /// **'Bomb Operation Configuration'**
  String get bombConfigurationTitle;

  /// Success message when a map is selected
  ///
  /// In en, this message translates to:
  /// **'Map \"{mapName}\" selected'**
  String mapSelectedSuccess(Object mapName);

  /// Success message when a field is opened
  ///
  /// In en, this message translates to:
  /// **'Field opened: {fieldName}'**
  String fieldOpenedSuccess(Object fieldName);

  /// Success message when a field is closed
  ///
  /// In en, this message translates to:
  /// **'Field closed'**
  String get fieldClosedSuccess;

  /// Error message when opening or closing a field fails
  ///
  /// In en, this message translates to:
  /// **'Error opening/closing field: {error}'**
  String errorOpeningClosingField(Object error);

  /// Title for the selected map card, showing map name
  ///
  /// In en, this message translates to:
  /// **'{mapName}'**
  String mapCardTitle(Object mapName);

  /// Text for info card when no scenario is selected
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noScenarioInfoCard;

  /// Text for info card when game duration is unlimited
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimitedDurationInfoCard;

  /// Title for the game configuration section
  ///
  /// In en, this message translates to:
  /// **'Game Configuration'**
  String get gameConfigurationTitle;

  /// Label for the select map button
  ///
  /// In en, this message translates to:
  /// **'Choose a Map'**
  String get selectMapButtonLabel;

  /// Label for the select scenarios button
  ///
  /// In en, this message translates to:
  /// **'Choose Scenarios'**
  String get selectScenariosButtonLabel;

  /// Label for the set duration button
  ///
  /// In en, this message translates to:
  /// **'Set Duration'**
  String get setDurationButtonLabel;

  /// Label for the switch to participate as a player
  ///
  /// In en, this message translates to:
  /// **'Participate as player:'**
  String get participateAsPlayerLabel;

  /// Label showing team name in a player list
  ///
  /// In en, this message translates to:
  /// **'Team: {teamName}'**
  String teamLabelPlayerList(Object teamName);

  /// Label identifying the current user as the host
  ///
  /// In en, this message translates to:
  /// **'You (Host)'**
  String get youHostLabel;

  /// Message shown in a loading dialog when starting a game
  ///
  /// In en, this message translates to:
  /// **'Starting game...'**
  String get loadingDialogMessage;

  /// Title for the interactive map editor screen when creating a new map
  ///
  /// In en, this message translates to:
  /// **'Create Interactive Map'**
  String get interactiveMapEditorTitleCreate;

  /// Title for the interactive map editor screen when editing an existing map
  ///
  /// In en, this message translates to:
  /// **'Edit: {mapName}'**
  String interactiveMapEditorTitleEdit(Object mapName);

  /// Tooltip for the save map button
  ///
  /// In en, this message translates to:
  /// **'Save Map'**
  String get saveMapTooltip;

  /// Label for an optional description field
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptionalLabel;

  /// Label for the address search input field
  ///
  /// In en, this message translates to:
  /// **'Search Address'**
  String get searchAddressLabel;

  /// Label for the view mode in map editor
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewModeLabel;

  /// Label for the draw boundary mode in map editor
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get drawBoundaryModeLabel;

  /// Label for the draw zone mode in map editor
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get drawZoneModeLabel;

  /// Label for the place POI mode in map editor
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get placePOIModeLabel;

  /// Button text to define field boundaries
  ///
  /// In en, this message translates to:
  /// **'Define Boundaries'**
  String get defineBoundariesButton;

  /// Button text to undo the last placed point
  ///
  /// In en, this message translates to:
  /// **'Undo Point'**
  String get undoPointButton;

  /// Button text to clear all points or drawings
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAllButton;

  /// Button text to add a new zone
  ///
  /// In en, this message translates to:
  /// **'Add Zone'**
  String get addZoneButton;

  /// Button text to clear the currently drawn zone points
  ///
  /// In en, this message translates to:
  /// **'Clear Current Zone'**
  String get clearCurrentZoneButton;

  /// Message when no zones are defined on the map
  ///
  /// In en, this message translates to:
  /// **'No zone defined.'**
  String get noZoneDefined;

  /// Title for the zone management panel
  ///
  /// In en, this message translates to:
  /// **'Manage Zones'**
  String get manageZonesTitle;

  /// Tooltip for the hide button
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hideTooltip;

  /// Tooltip for the show button
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get showTooltip;

  /// Title for the delete zone confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Zone'**
  String get confirmDeleteZoneTitle;

  /// Confirmation message for deleting a zone
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete zone \"{zoneName}\"?'**
  String confirmDeleteZoneMessage(Object zoneName);

  /// Message when no points of interest are defined
  ///
  /// In en, this message translates to:
  /// **'No strategic point defined.'**
  String get noPOIDefined;

  /// Title for the POI management panel
  ///
  /// In en, this message translates to:
  /// **'Manage Strategic Points'**
  String get managePOIsTitle;

  /// Title for the delete POI confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Strategic Point'**
  String get confirmDeletePOITitle;

  /// Confirmation message for deleting a POI
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete point \"{poiName}\"?'**
  String confirmDeletePOIMessage(Object poiName);

  /// Snackbar message when map name is required
  ///
  /// In en, this message translates to:
  /// **'Please enter a name for the map.'**
  String get mapNameRequiredSnackbar;

  /// Snackbar message when a map is created successfully
  ///
  /// In en, this message translates to:
  /// **'Map created successfully!'**
  String get mapCreatedSuccessSnackbar;

  /// Snackbar message when a map is updated successfully
  ///
  /// In en, this message translates to:
  /// **'Map updated successfully!'**
  String get mapUpdatedSuccessSnackbar;

  /// Snackbar message when saving a map fails
  ///
  /// In en, this message translates to:
  /// **'Error saving map: {error}'**
  String errorSavingMapSnackbar(Object error);

  /// Snackbar message asking to define boundary first
  ///
  /// In en, this message translates to:
  /// **'Please define a field boundary (at least 3 points) before capturing the background.'**
  String get defineBoundaryFirstSnackbar;

  /// Error message for minimum points required for a boundary
  ///
  /// In en, this message translates to:
  /// **'The field boundary must have at least 3 points.'**
  String get boundaryMinPointsError;

  /// Error message for minimum points required for a zone
  ///
  /// In en, this message translates to:
  /// **'A zone must have at least 3 points.'**
  String get zoneMinPointsError;

  /// Title for the redefine boundary warning dialog
  ///
  /// In en, this message translates to:
  /// **'Redefine Boundaries'**
  String get redefineBoundaryWarningTitle;

  /// Warning message when redefining boundaries
  ///
  /// In en, this message translates to:
  /// **'Redefining the field boundaries will erase all existing zones and strategic points. Do you want to continue?'**
  String get redefineBoundaryWarningMessage;

  /// Button text to continue an action
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Success message when boundaries and backgrounds are set
  ///
  /// In en, this message translates to:
  /// **'Field boundaries defined and map backgrounds captured.'**
  String get boundariesDefinedAndBackgroundsCapturedSnackbar;

  /// Snackbar message for geocoding errors
  ///
  /// In en, this message translates to:
  /// **'Geocoding error: {error}'**
  String errorGeocodingSnackbar(Object error);

  /// Instructional text for map interaction
  ///
  /// In en, this message translates to:
  /// **'Tap on the map to define the position'**
  String get tapToDefinePositionInstruction;

  /// No description provided for @poiIconFlag.
  ///
  /// In en, this message translates to:
  /// **'Flag'**
  String get poiIconFlag;

  /// No description provided for @poiIconBomb.
  ///
  /// In en, this message translates to:
  /// **'Bomb'**
  String get poiIconBomb;

  /// No description provided for @poiIconStar.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get poiIconStar;

  /// No description provided for @poiIconPlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get poiIconPlace;

  /// No description provided for @poiIconPinDrop.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get poiIconPinDrop;

  /// No description provided for @poiIconHouse.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get poiIconHouse;

  /// No description provided for @poiIconCabin.
  ///
  /// In en, this message translates to:
  /// **'Cabin'**
  String get poiIconCabin;

  /// No description provided for @poiIconDoor.
  ///
  /// In en, this message translates to:
  /// **'Door'**
  String get poiIconDoor;

  /// No description provided for @poiIconSkull.
  ///
  /// In en, this message translates to:
  /// **'Skull'**
  String get poiIconSkull;

  /// No description provided for @poiIconNavigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get poiIconNavigation;

  /// No description provided for @poiIconTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get poiIconTarget;

  /// No description provided for @poiIconAmmo.
  ///
  /// In en, this message translates to:
  /// **'Ammo'**
  String get poiIconAmmo;

  /// No description provided for @poiIconMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get poiIconMedical;

  /// No description provided for @poiIconRadio.
  ///
  /// In en, this message translates to:
  /// **'Radio'**
  String get poiIconRadio;

  /// No description provided for @poiIconDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get poiIconDefault;

  /// Title for bomb arming dialog
  ///
  /// In en, this message translates to:
  /// **'Arming in progress'**
  String get bombArmingInProgressTitle;

  /// Title for bomb disarming dialog
  ///
  /// In en, this message translates to:
  /// **'Disarming in progress'**
  String get bombDisarmingInProgressTitle;

  /// Instruction in bomb action dialog
  ///
  /// In en, this message translates to:
  /// **'Stay in the zone to continue'**
  String get stayInZoneToContinue;

  /// Warning in bomb action dialog
  ///
  /// In en, this message translates to:
  /// **'Leaving the zone will cancel the action'**
  String get leavingZoneWillCancel;

  /// App bar title for bomb config screen
  ///
  /// In en, this message translates to:
  /// **'Configuration: {scenarioName}'**
  String bombConfigScreenTitle(Object scenarioName);

  /// Section title for general info
  ///
  /// In en, this message translates to:
  /// **'General Information'**
  String get generalInformationLabel;

  /// Subtitle for general info section in bomb config
  ///
  /// In en, this message translates to:
  /// **'Configure the basic information for the Bomb Operation scenario.'**
  String get bombConfigGeneralInfoSubtitle;

  /// Label for field map section
  ///
  /// In en, this message translates to:
  /// **'Field Map'**
  String get fieldMapLabel;

  /// Subtitle for field map section
  ///
  /// In en, this message translates to:
  /// **'Visualize the field map and bomb sites.'**
  String get fieldMapSubtitle;

  /// Label for toggle to show/hide zones
  ///
  /// In en, this message translates to:
  /// **'Show Zones'**
  String get showZonesLabel;

  /// Label for toggle to show/hide POIs
  ///
  /// In en, this message translates to:
  /// **'Show POIs'**
  String get showPOIsLabel;

  /// Message shown while map is loading
  ///
  /// In en, this message translates to:
  /// **'Loading map...'**
  String get loadingMap;

  /// Section title for game settings
  ///
  /// In en, this message translates to:
  /// **'Game Settings'**
  String get gameSettingsLabel;

  /// Subtitle for game settings section in bomb config
  ///
  /// In en, this message translates to:
  /// **'Configure the rules and settings for the Bomb Operation scenario.'**
  String get bombConfigSettingsSubtitle;

  /// Label for bomb timer input
  ///
  /// In en, this message translates to:
  /// **'Bomb Timer (seconds) *'**
  String get bombTimerLabel;

  /// Generic error for a required numeric field
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get valueRequiredError;

  /// Error for minimum seconds required
  ///
  /// In en, this message translates to:
  /// **'Min {value}s'**
  String minSecondsError(Object value);

  /// Label for defuse time input
  ///
  /// In en, this message translates to:
  /// **'Defuse Time (seconds) *'**
  String get defuseTimeLabel;

  /// Label for arming time input
  ///
  /// In en, this message translates to:
  /// **'Arming Time (seconds) *'**
  String get armingTimeLabel;

  /// Helper text for arming time input
  ///
  /// In en, this message translates to:
  /// **'Time required to plant a bomb'**
  String get armingTimeHelperText;

  /// Label for active sites per round input
  ///
  /// In en, this message translates to:
  /// **'Active Sites per Round *'**
  String get activeSitesPerRoundLabel;

  /// Helper text for active sites input
  ///
  /// In en, this message translates to:
  /// **'Number of randomly active bomb sites per round'**
  String get activeSitesHelperText;

  /// Error for minimum count required
  ///
  /// In en, this message translates to:
  /// **'Min {value}'**
  String minCountError(Object value);

  /// Section title for bomb sites
  ///
  /// In en, this message translates to:
  /// **'Bomb Sites'**
  String get bombSitesSectionTitle;

  /// Subtitle for bomb sites section
  ///
  /// In en, this message translates to:
  /// **'Manage the sites where bombs can be planted and defused.'**
  String get bombSitesSectionSubtitle;

  /// Button text to manage bomb sites
  ///
  /// In en, this message translates to:
  /// **'Manage Bomb Sites'**
  String get manageBombSitesButton;

  /// Button text to save settings
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettingsButton;

  /// Error message when saving scenario fails
  ///
  /// In en, this message translates to:
  /// **'Error saving scenario: {error}'**
  String errorSavingScenario(Object error);

  /// Title for new bomb site screen
  ///
  /// In en, this message translates to:
  /// **'New Bomb Site'**
  String get newBombSiteTitle;

  /// Title for edit bomb site screen
  ///
  /// In en, this message translates to:
  /// **'Edit Bomb Site'**
  String get editBombSiteTitle;

  /// Label for bomb site name input
  ///
  /// In en, this message translates to:
  /// **'Site Name *'**
  String get bombSiteNameLabel;

  /// Error for required bomb site name
  ///
  /// In en, this message translates to:
  /// **'Please enter a name for the site'**
  String get siteNameRequiredError;

  /// Label for bomb site radius input
  ///
  /// In en, this message translates to:
  /// **'Radius (meters) *'**
  String get radiusMetersLabel;

  /// Helper text for bomb site radius
  ///
  /// In en, this message translates to:
  /// **'Radius of the zone where the bomb can be planted/defused'**
  String get radiusHelperText;

  /// Error for required bomb site radius
  ///
  /// In en, this message translates to:
  /// **'Please enter a radius'**
  String get radiusRequiredError;

  /// Error for invalid bomb site radius
  ///
  /// In en, this message translates to:
  /// **'Invalid radius'**
  String get invalidRadiusError;

  /// Label for bomb site color selection
  ///
  /// In en, this message translates to:
  /// **'Site Color:'**
  String get siteColorLabel;

  /// Label displaying coordinates
  ///
  /// In en, this message translates to:
  /// **'Position: {lat}, {long}'**
  String positionLabel(Object lat, Object long);

  /// Button text to create a bomb site
  ///
  /// In en, this message translates to:
  /// **'Create Site'**
  String get createSiteButton;

  /// Button text to update a bomb site
  ///
  /// In en, this message translates to:
  /// **'Update Site'**
  String get updateSiteButton;

  /// Success message when bomb site is saved
  ///
  /// In en, this message translates to:
  /// **'Site saved successfully'**
  String get siteSavedSuccess;

  /// Error message when saving bomb site fails
  ///
  /// In en, this message translates to:
  /// **'Error saving site: {error}'**
  String errorSavingSite(Object error);

  /// App bar title for bomb site list screen
  ///
  /// In en, this message translates to:
  /// **'Bomb Sites: {scenarioName}'**
  String bombSiteListScreenTitle(Object scenarioName);

  /// Error message when loading bomb sites fails
  ///
  /// In en, this message translates to:
  /// **'Error loading sites: {error}'**
  String errorLoadingSites(Object error);

  /// Button text/tooltip to add a bomb site
  ///
  /// In en, this message translates to:
  /// **'Add Site'**
  String get addSiteButton;

  /// Message when no bomb sites are defined
  ///
  /// In en, this message translates to:
  /// **'No bomb sites defined'**
  String get noBombSitesDefined;

  /// Instructional message to add bomb sites
  ///
  /// In en, this message translates to:
  /// **'Add sites where bombs can be planted and defused.'**
  String get addSitesInstruction;

  /// Subtitle for bomb site list item
  ///
  /// In en, this message translates to:
  /// **'Radius: {radius}m • Position: {lat}, {long}'**
  String siteDetailsSubtitle(Object radius, Object lat, Object long);

  /// Confirmation message for deleting a bomb site
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete site \"{siteName}\"?'**
  String confirmDeleteSiteMessage(Object siteName);

  /// Success message when bomb site is deleted
  ///
  /// In en, this message translates to:
  /// **'Site deleted successfully'**
  String get siteDeletedSuccess;

  /// Error message when deleting bomb site fails
  ///
  /// In en, this message translates to:
  /// **'Error deleting site: {error}'**
  String errorDeletingSite(Object error);

  /// Points awarded message in treasure popup
  ///
  /// In en, this message translates to:
  /// **'+{points} points'**
  String pointsAwarded(Object points);

  /// Title for QR code scanner screen
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQRCodeTitle;

  /// Error message if game is not active during scan
  ///
  /// In en, this message translates to:
  /// **'Game is not active'**
  String get gameNotActiveError;

  /// Error message during QR scan
  ///
  /// In en, this message translates to:
  /// **'Error during scan: {error}'**
  String scanError(Object error);

  /// Title for treasure found dialog/popup
  ///
  /// In en, this message translates to:
  /// **'Treasure Found!'**
  String get treasureFoundTitle;

  /// Default name for a treasure if not specified
  ///
  /// In en, this message translates to:
  /// **'Treasure'**
  String get defaultTreasureName;

  /// Label showing total score after finding a treasure
  ///
  /// In en, this message translates to:
  /// **'Total score: {score} points'**
  String totalScoreLabel(Object score);

  /// Title for QR codes display screen
  ///
  /// In en, this message translates to:
  /// **'QR Codes - {scenarioName}'**
  String qrCodesScreenTitle(Object scenarioName);

  /// Label for print button
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printButton;

  /// Error message if printing is not supported
  ///
  /// In en, this message translates to:
  /// **'Printing not available on this platform'**
  String get printingNotAvailableError;

  /// Label for direct print button
  ///
  /// In en, this message translates to:
  /// **'Direct Print'**
  String get directPrintButton;

  /// Label for download ZIP button
  ///
  /// In en, this message translates to:
  /// **'Download ZIP'**
  String get downloadZipButton;

  /// Label for share button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareButton;

  /// Default text when sharing QR codes
  ///
  /// In en, this message translates to:
  /// **'QR Codes for {scenarioName}'**
  String qrCodesForScenarioShareText(Object scenarioName);

  /// Instructions on the QR codes display screen
  ///
  /// In en, this message translates to:
  /// **'Print, download, or share these QR codes for your treasure hunt.'**
  String get qrCodesDisplayInstructions;

  /// Default indexed name for a treasure
  ///
  /// In en, this message translates to:
  /// **'Treasure {index}'**
  String defaultTreasureNameIndexed(Object index);

  /// Error message if there are no QR codes to share
  ///
  /// In en, this message translates to:
  /// **'No QR codes to share'**
  String get noQRCodesToShareError;

  /// Error message during content sharing
  ///
  /// In en, this message translates to:
  /// **'Error while sharing: {error}'**
  String sharingError(Object error);

  /// Error message when ZIP file creation fails
  ///
  /// In en, this message translates to:
  /// **'Error creating ZIP: {error}'**
  String zipCreationError(Object error);

  /// Title for the scoreboard screen
  ///
  /// In en, this message translates to:
  /// **'Scores - {scenarioName}'**
  String scoreboardScreenTitle(Object scenarioName);

  /// Error message when scoreboard loading fails
  ///
  /// In en, this message translates to:
  /// **'Error loading scoreboard: {error}'**
  String errorLoadingScoreboard(Object error);

  /// Header text for the scoreboard
  ///
  /// In en, this message translates to:
  /// **'Scoreboard - {scenarioName}'**
  String scoreboardHeader(Object scenarioName);

  /// Label indicating scores are locked
  ///
  /// In en, this message translates to:
  /// **'Scores locked'**
  String get scoresLockedLabel;

  /// Label indicating scores are unlocked
  ///
  /// In en, this message translates to:
  /// **'Scores unlocked'**
  String get scoresUnlockedLabel;

  /// Button text to unlock scores
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockButton;

  /// Button text to lock scores
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lockButton;

  /// Button text to reset scores
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetButton;

  /// Dialog title for reset scores confirmation
  ///
  /// In en, this message translates to:
  /// **'Reset Scores'**
  String get resetScoresTitle;

  /// Confirmation message for resetting scores
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset all scores? This action is irreversible.'**
  String get resetScoresConfirmationMessage;

  /// Placeholder for an unknown team name
  ///
  /// In en, this message translates to:
  /// **'Unknown Team'**
  String get unknownTeamName;

  /// Label showing number of treasures found
  ///
  /// In en, this message translates to:
  /// **'{count} treasures found'**
  String treasuresFoundCount(Object count);

  /// Suffix for points display
  ///
  /// In en, this message translates to:
  /// **'{score} pts'**
  String pointsSuffix(Object score);

  /// Placeholder for an unknown player name
  ///
  /// In en, this message translates to:
  /// **'Unknown Player'**
  String get unknownPlayerName;

  /// Title for the edit treasure screen
  ///
  /// In en, this message translates to:
  /// **'Edit Treasure'**
  String get editTreasureTitle;

  /// Error message when updating treasure fails
  ///
  /// In en, this message translates to:
  /// **'Error updating treasure: {error}'**
  String errorUpdatingTreasure(Object error);

  /// Label for treasure name input
  ///
  /// In en, this message translates to:
  /// **'Treasure Name'**
  String get treasureNameLabel;

  /// Error for required name field
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get nameRequiredError;

  /// Label for treasure value input
  ///
  /// In en, this message translates to:
  /// **'Value (points)'**
  String get valuePointsLabel;

  /// Error for invalid number input
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get invalidNumberError;

  /// Label for treasure symbol selection
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get symbolLabel;

  /// Button text to save changes
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChangesButton;

  /// Title for treasure hunt configuration screen
  ///
  /// In en, this message translates to:
  /// **'Configuration - {scenarioName}'**
  String treasureHuntConfigTitle(Object scenarioName);

  /// Error loading treasure hunt scenario details
  ///
  /// In en, this message translates to:
  /// **'Error loading Treasure Hunt scenario: {error}'**
  String errorLoadingTreasureHuntScenario(Object error);

  /// Section title for treasure hunt setup
  ///
  /// In en, this message translates to:
  /// **'Treasure Hunt Setup'**
  String get treasureHuntSetupTitle;

  /// Label for number of QR codes input
  ///
  /// In en, this message translates to:
  /// **'Number of QR codes'**
  String get numberOfQRCodesLabel;

  /// Helper text for QR code count input
  ///
  /// In en, this message translates to:
  /// **'Between 1 and 50'**
  String get qrCodeCountHelperText;

  /// Error for required number field
  ///
  /// In en, this message translates to:
  /// **'Please enter a number'**
  String get numberRequiredError;

  /// Error for QR code count out of range
  ///
  /// In en, this message translates to:
  /// **'Number must be between 1 and 50'**
  String get qrCodeCountRangeError;

  /// Label for default treasure value input
  ///
  /// In en, this message translates to:
  /// **'Default Value (points)'**
  String get defaultValuePointsLabel;

  /// Label for default treasure symbol selection
  ///
  /// In en, this message translates to:
  /// **'Default Symbol'**
  String get defaultSymbolLabel;

  /// Button text to generate QR codes
  ///
  /// In en, this message translates to:
  /// **'Generate QR Codes'**
  String get generateQRCodesButton;

  /// Error message when treasure creation fails
  ///
  /// In en, this message translates to:
  /// **'Error creating treasures: {error}'**
  String errorCreatingTreasures(Object error);

  /// Button to view existing treasures, shows count
  ///
  /// In en, this message translates to:
  /// **'View Existing Treasures ({count})'**
  String viewExistingTreasuresButton(Object count);

  /// Title for treasures list screen
  ///
  /// In en, this message translates to:
  /// **'Treasures - {scenarioName}'**
  String treasuresScreenTitle(Object scenarioName);

  /// Error message when loading treasures fails
  ///
  /// In en, this message translates to:
  /// **'Error loading treasures: {error}'**
  String errorLoadingTreasures(Object error);

  /// Message when no treasures are found for a scenario
  ///
  /// In en, this message translates to:
  /// **'No treasures found for this scenario'**
  String get noTreasuresFoundForScenario;

  /// Header showing the scenario name
  ///
  /// In en, this message translates to:
  /// **'Scenario: {scenarioName}'**
  String scenarioNameHeader(Object scenarioName);

  /// Label showing the number of treasures
  ///
  /// In en, this message translates to:
  /// **'Number of treasures: {count}'**
  String numberOfTreasuresLabel(Object count);

  /// Subtitle showing treasure value
  ///
  /// In en, this message translates to:
  /// **'Value: {points} points'**
  String treasureValueSubtitle(Object points);

  /// Button text to view QR codes
  ///
  /// In en, this message translates to:
  /// **'View QR Codes'**
  String get viewQRCodesButton;

  /// Dialog title for delete treasure confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete this treasure?'**
  String get confirmDeleteTreasureTitle;

  /// Confirmation message for deleting a treasure
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{treasureName}\"?'**
  String confirmDeleteTreasureMessage(Object treasureName);

  /// Error message when deleting treasure fails
  ///
  /// In en, this message translates to:
  /// **'Error deleting treasure: {error}'**
  String errorDeletingTreasure(Object error);

  /// Tooltip for toggle flash button
  ///
  /// In en, this message translates to:
  /// **'Toggle Flash'**
  String get toggleFlash;

  /// Tooltip for switch camera button
  ///
  /// In en, this message translates to:
  /// **'Switch Camera'**
  String get switchCamera;

  /// No description provided for @mapTab.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTab;

  /// No description provided for @scenariosTab.
  ///
  /// In en, this message translates to:
  /// **'Scenarios'**
  String get scenariosTab;

  /// No description provided for @nonInteractiveMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Non-interactive map'**
  String get nonInteractiveMapTitle;

  /// No description provided for @nonInteractiveMapMessage.
  ///
  /// In en, this message translates to:
  /// **'This map does not have the interactive configuration required for the \'Bomb Operation\' scenario.\n\nYou must first configure this map in the interactive map editor or select another map that is already configured.'**
  String get nonInteractiveMapMessage;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @configureBombOperation.
  ///
  /// In en, this message translates to:
  /// **'Configure Bomb Operation'**
  String get configureBombOperation;

  /// No description provided for @bombOperationDescription.
  ///
  /// In en, this message translates to:
  /// **'Two teams face off:\n🔴 Terrorists – Their mission: activate the bomb in a designated area and start the countdown.\n🔵 Counter-Terrorists – Their goal: find and defuse the bomb before it explodes.\n\n🎯 If the timer reaches zero → imaginary explosion → terrorists win.\n🛡️ Bomb defused in time → counter-terrorists win.\n\n💣 Objective: speed, stealth, and precision. Good luck, soldiers!'**
  String get bombOperationDescription;

  /// No description provided for @bombSite.
  ///
  /// In en, this message translates to:
  /// **'Site'**
  String get bombSite;

  /// No description provided for @recruitmentTitle.
  ///
  /// In en, this message translates to:
  /// **'RECRUITMENT'**
  String get recruitmentTitle;

  /// No description provided for @recruitmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No spam. No commitment. One email for recovery, one username to join a game and play. Mission complete.'**
  String get recruitmentSubtitle;

  /// No description provided for @hostSectionCommandCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'COMMAND CENTER'**
  String get hostSectionCommandCenterTitle;

  /// No description provided for @hostSectionMapManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'MAP MANAGEMENT'**
  String get hostSectionMapManagementTitle;

  /// No description provided for @hostSectionMissionScenariosTitle.
  ///
  /// In en, this message translates to:
  /// **'MISSION SCENARIOS'**
  String get hostSectionMissionScenariosTitle;

  /// No description provided for @hostSectionTeamsPlayersTitle.
  ///
  /// In en, this message translates to:
  /// **'TEAMS & PLAYERS'**
  String get hostSectionTeamsPlayersTitle;

  /// No description provided for @hostSectionGameHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'GAME HISTORY'**
  String get hostSectionGameHistoryTitle;

  /// No description provided for @hostSectionCommandCenterDescription.
  ///
  /// In en, this message translates to:
  /// **'Deploy your HQ, open the field and welcome players. Prepare your saved scenarios, launch games with precise countdown and keep control of real-time progress.'**
  String get hostSectionCommandCenterDescription;

  /// No description provided for @hostSectionMapManagementDescription.
  ///
  /// In en, this message translates to:
  /// **'Create your playing field, zone by zone. Navigate the map, define boundaries, name key areas and place your strategic points of interest. Your battlefield takes shape, as you imagine it.'**
  String get hostSectionMapManagementDescription;

  /// No description provided for @hostSectionMissionScenariosDescription.
  ///
  /// In en, this message translates to:
  /// **'Create your mission scenarios and define each key parameter: objective type, number of targets, duration, activation zones... Whether it\'s a treasure hunt or an explosive operation, you prepare the ground for a custom game.'**
  String get hostSectionMissionScenariosDescription;

  /// No description provided for @hostSectionTeamsPlayersDescription.
  ///
  /// In en, this message translates to:
  /// **'Create your teams, manage numbers and assign roles for each player. Good balance guarantees dynamic and fun games, with missions where everyone has their place.'**
  String get hostSectionTeamsPlayersDescription;

  /// No description provided for @hostSectionGameHistoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Check your game history: scores, stats, key moments. Relive your past sessions, spot what went well (or less well), and adjust your next scenarios for even more fun.'**
  String get hostSectionGameHistoryDescription;

  /// No description provided for @hostSectionCommandCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your connected base camp – everything goes through you, chief.'**
  String get hostSectionCommandCenterSubtitle;

  /// No description provided for @hostSectionMapManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your cartographic arsenal – Draw, name, control.'**
  String get hostSectionMapManagementSubtitle;

  /// No description provided for @hostSectionMissionScenariosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Imagination is the weapon – create custom challenges.'**
  String get hostSectionMissionScenariosSubtitle;

  /// No description provided for @hostSectionTeamsPlayersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tactical distribution – create balanced and intense matches.'**
  String get hostSectionTeamsPlayersSubtitle;

  /// No description provided for @hostSectionGameHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Back to the field – your games, your data.'**
  String get hostSectionGameHistorySubtitle;

  /// No description provided for @audioGameStarted.
  ///
  /// In en, this message translates to:
  /// **'Game started.'**
  String get audioGameStarted;

  /// No description provided for @audioGameEnded.
  ///
  /// In en, this message translates to:
  /// **'Game ended.'**
  String get audioGameEnded;

  /// No description provided for @optionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get optionsTitle;

  /// No description provided for @userNotConnected.
  ///
  /// In en, this message translates to:
  /// **'User not connected'**
  String get userNotConnected;

  /// No description provided for @appLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Application language'**
  String get appLanguageTitle;

  /// No description provided for @interfaceLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Interface language'**
  String get interfaceLanguageLabel;

  /// No description provided for @audioNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio notifications'**
  String get audioNotificationsTitle;

  /// No description provided for @enableAudioNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable audio notifications'**
  String get enableAudioNotifications;

  /// No description provided for @volumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volumeLabel;

  /// No description provided for @audioLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Audio notifications language'**
  String get audioLanguageLabel;

  /// No description provided for @audioTestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tests'**
  String get audioTestsTitle;

  /// No description provided for @testStartButton.
  ///
  /// In en, this message translates to:
  /// **'Test start'**
  String get testStartButton;

  /// No description provided for @testEndButton.
  ///
  /// In en, this message translates to:
  /// **'Test end'**
  String get testEndButton;

  /// No description provided for @playingStatus.
  ///
  /// In en, this message translates to:
  /// **'Playing...'**
  String get playingStatus;

  /// No description provided for @stopButton.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopButton;

  /// No description provided for @bombZoneEntered.
  ///
  /// In en, this message translates to:
  /// **'Zone {zoneName} reached. Beginning bomb arming.'**
  String bombZoneEntered(Object zoneName);

  /// No description provided for @bombArmingTimeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time remaining before activation: {seconds} seconds.'**
  String bombArmingTimeRemaining(Object seconds);

  /// No description provided for @bombStayInZone.
  ///
  /// In en, this message translates to:
  /// **'Stay in the zone to arm the bomb.'**
  String get bombStayInZone;

  /// No description provided for @bombCountdown30.
  ///
  /// In en, this message translates to:
  /// **'Thirty'**
  String get bombCountdown30;

  /// No description provided for @bombCountdown20.
  ///
  /// In en, this message translates to:
  /// **'Twenty'**
  String get bombCountdown20;

  /// No description provided for @bombCountdown10.
  ///
  /// In en, this message translates to:
  /// **'Ten'**
  String get bombCountdown10;

  /// No description provided for @bombCountdown9.
  ///
  /// In en, this message translates to:
  /// **'Nine'**
  String get bombCountdown9;

  /// No description provided for @bombCountdown8.
  ///
  /// In en, this message translates to:
  /// **'Eight'**
  String get bombCountdown8;

  /// No description provided for @bombCountdown7.
  ///
  /// In en, this message translates to:
  /// **'Seven'**
  String get bombCountdown7;

  /// No description provided for @bombCountdown6.
  ///
  /// In en, this message translates to:
  /// **'Six'**
  String get bombCountdown6;

  /// No description provided for @bombCountdown5.
  ///
  /// In en, this message translates to:
  /// **'Five'**
  String get bombCountdown5;

  /// No description provided for @bombCountdown4.
  ///
  /// In en, this message translates to:
  /// **'Four'**
  String get bombCountdown4;

  /// No description provided for @bombCountdown3.
  ///
  /// In en, this message translates to:
  /// **'Three'**
  String get bombCountdown3;

  /// No description provided for @bombCountdown2.
  ///
  /// In en, this message translates to:
  /// **'Two'**
  String get bombCountdown2;

  /// No description provided for @bombCountdown1.
  ///
  /// In en, this message translates to:
  /// **'One'**
  String get bombCountdown1;

  /// No description provided for @bombArmed.
  ///
  /// In en, this message translates to:
  /// **'Bomb in zone {zoneName} armed'**
  String bombArmed(Object zoneName);

  /// No description provided for @bombZoneExited.
  ///
  /// In en, this message translates to:
  /// **'Exited zone {zoneName}. Arming interrupted.'**
  String bombZoneExited(Object zoneName);

  /// No description provided for @bombActiveAlert.
  ///
  /// In en, this message translates to:
  /// **'Bomb active on {zoneName}. Intervention required.'**
  String bombActiveAlert(Object zoneName);

  /// No description provided for @defuseZoneEntered.
  ///
  /// In en, this message translates to:
  /// **'Zone {zoneName} reached. Beginning defusal.'**
  String defuseZoneEntered(Object zoneName);

  /// No description provided for @defuseTimeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time remaining: {seconds} seconds.'**
  String defuseTimeRemaining(Object seconds);

  /// No description provided for @defuseStayInZone.
  ///
  /// In en, this message translates to:
  /// **'Stay in position to complete the operation.'**
  String get defuseStayInZone;

  /// No description provided for @defuseZoneExited.
  ///
  /// In en, this message translates to:
  /// **'Exited zone {zoneName}. Defusal interrupted.'**
  String defuseZoneExited(Object zoneName);

  /// No description provided for @bombDefused.
  ///
  /// In en, this message translates to:
  /// **'Site {zoneName} secured. Bomb defused.'**
  String bombDefused(Object zoneName);

  /// No description provided for @bombExploded.
  ///
  /// In en, this message translates to:
  /// **'Explosion! The bomb on site {zoneName} has been triggered.'**
  String bombExploded(Object zoneName);

  /// No description provided for @bombOperationActive.
  ///
  /// In en, this message translates to:
  /// **'Bomb Operation scenario active - Waiting for role assignment'**
  String get bombOperationActive;

  /// No description provided for @noTeamRole.
  ///
  /// In en, this message translates to:
  /// **'Your team has no assigned role in this scenario'**
  String get noTeamRole;

  /// No description provided for @terroristRole.
  ///
  /// In en, this message translates to:
  /// **'Terrorist'**
  String get terroristRole;

  /// No description provided for @antiTerroristRole.
  ///
  /// In en, this message translates to:
  /// **'Counter-terrorist'**
  String get antiTerroristRole;

  /// No description provided for @unknownRole.
  ///
  /// In en, this message translates to:
  /// **'Unknown role'**
  String get unknownRole;

  /// No description provided for @terroristObjective.
  ///
  /// In en, this message translates to:
  /// **'Objective: Go to a bomb zone to activate detonation'**
  String get terroristObjective;

  /// No description provided for @antiTerroristObjective.
  ///
  /// In en, this message translates to:
  /// **'Objective: Go to the active bomb zone to deactivate it'**
  String get antiTerroristObjective;

  /// No description provided for @observerObjective.
  ///
  /// In en, this message translates to:
  /// **'Objective: Observe the game'**
  String get observerObjective;

  /// No description provided for @youAre.
  ///
  /// In en, this message translates to:
  /// **'You are: {role}'**
  String youAre(Object role);

  /// No description provided for @sitesActivated.
  ///
  /// In en, this message translates to:
  /// **'{activatedCount} sites activated out of {totalSites}'**
  String sitesActivated(Object activatedCount, Object totalSites);

  /// No description provided for @armingTime.
  ///
  /// In en, this message translates to:
  /// **'Arming time: {time}s'**
  String armingTime(Object time);

  /// No description provided for @defuseTime.
  ///
  /// In en, this message translates to:
  /// **'Defuse time: {time}s'**
  String defuseTime(Object time);

  /// No description provided for @bombStats.
  ///
  /// In en, this message translates to:
  /// **'{armedCount} bombs armed • {disarmedCount} defused • {explodedCount} exploded'**
  String bombStats(
      Object armedCount, Object disarmedCount, Object explodedCount);

  /// No description provided for @inZone.
  ///
  /// In en, this message translates to:
  /// **'In zone: {zoneName}'**
  String inZone(Object zoneName);

  /// No description provided for @armedBombs.
  ///
  /// In en, this message translates to:
  /// **'Armed bombs:'**
  String get armedBombs;

  /// No description provided for @bombsToDefuse.
  ///
  /// In en, this message translates to:
  /// **'Bombs to defuse:'**
  String get bombsToDefuse;

  /// No description provided for @victory.
  ///
  /// In en, this message translates to:
  /// **'🏆 Victory!'**
  String get victory;

  /// No description provided for @defeat.
  ///
  /// In en, this message translates to:
  /// **'💀 Defeat!'**
  String get defeat;

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'⚖️ Draw'**
  String get draw;

  /// No description provided for @bombTimerText.
  ///
  /// In en, this message translates to:
  /// **'Bomb at site {siteName} armed - explosion in {time}'**
  String bombTimerText(Object siteName, Object time);

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// No description provided for @individualRanking.
  ///
  /// In en, this message translates to:
  /// **'Individual ranking'**
  String get individualRanking;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @playerName.
  ///
  /// In en, this message translates to:
  /// **'Player {playerId}'**
  String playerName(Object playerId);

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'{score} pts'**
  String points(Object score);

  /// No description provided for @qrCodesFound.
  ///
  /// In en, this message translates to:
  /// **'{found}/{total} QR codes found, total: {points} {symbol}'**
  String qrCodesFound(Object found, Object points, Object symbol, Object total);

  /// No description provided for @scenarioType.
  ///
  /// In en, this message translates to:
  /// **'Type: {type}'**
  String scenarioType(Object type);

  /// No description provided for @teamRanking.
  ///
  /// In en, this message translates to:
  /// **'Team ranking'**
  String get teamRanking;

  /// No description provided for @timeElapsed.
  ///
  /// In en, this message translates to:
  /// **'Time elapsed'**
  String get timeElapsed;

  /// No description provided for @timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time remaining'**
  String get timeRemaining;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @unknownScenario.
  ///
  /// In en, this message translates to:
  /// **'Unknown scenario'**
  String get unknownScenario;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @showFullScreen.
  ///
  /// In en, this message translates to:
  /// **'Show fullscreen'**
  String get showFullScreen;

  /// No description provided for @geolocationError.
  ///
  /// In en, this message translates to:
  /// **'Geolocation error: {error}'**
  String geolocationError(Object error);

  /// No description provided for @mapOpenError.
  ///
  /// In en, this message translates to:
  /// **'Error opening map: {error}'**
  String mapOpenError(Object error);

  /// No description provided for @fullScreenMapError.
  ///
  /// In en, this message translates to:
  /// **'Error opening fullscreen map: {error}'**
  String fullScreenMapError(Object error);

  /// No description provided for @noMapSelected.
  ///
  /// In en, this message translates to:
  /// **'No map selected'**
  String get noMapSelected;

  /// No description provided for @noFieldOpen.
  ///
  /// In en, this message translates to:
  /// **'No field open'**
  String get noFieldOpen;

  /// No description provided for @fieldNotAccessible.
  ///
  /// In en, this message translates to:
  /// **'Field not accessible'**
  String get fieldNotAccessible;

  /// No description provided for @gameReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to play'**
  String get gameReady;

  /// No description provided for @joinCurrentGame.
  ///
  /// In en, this message translates to:
  /// **'Join current game'**
  String get joinCurrentGame;

  /// No description provided for @leaveCurrentField.
  ///
  /// In en, this message translates to:
  /// **'Leave current field'**
  String get leaveCurrentField;

  /// No description provided for @manageTeam.
  ///
  /// In en, this message translates to:
  /// **'Manage team'**
  String get manageTeam;

  /// No description provided for @previousFields.
  ///
  /// In en, this message translates to:
  /// **'Previous fields'**
  String get previousFields;

  /// No description provided for @noFieldHistory.
  ///
  /// In en, this message translates to:
  /// **'No field history available'**
  String get noFieldHistory;

  /// No description provided for @reconnectToField.
  ///
  /// In en, this message translates to:
  /// **'Reconnect to field'**
  String get reconnectToField;

  /// No description provided for @unknownSession.
  ///
  /// In en, this message translates to:
  /// **'Unknown session'**
  String get unknownSession;

  /// No description provided for @sessionStartedOn.
  ///
  /// In en, this message translates to:
  /// **'Started on {date}'**
  String sessionStartedOn(Object date);

  /// No description provided for @gameSessionDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Session details'**
  String get gameSessionDetailsTitle;

  /// No description provided for @gameReplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Game replay'**
  String get gameReplayTitle;

  /// No description provided for @noGameSessionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No game sessions available'**
  String get noGameSessionsAvailable;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @favoritesTab.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTab;

  /// No description provided for @favoritesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Feature coming soon'**
  String get favoritesComingSoon;

  /// No description provided for @alreadyInvited.
  ///
  /// In en, this message translates to:
  /// **'Already invited'**
  String get alreadyInvited;

  /// No description provided for @receivedInvitations.
  ///
  /// In en, this message translates to:
  /// **'Received invitations'**
  String get receivedInvitations;

  /// No description provided for @invitationsRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Invitations refreshed'**
  String get invitationsRefreshed;

  /// No description provided for @invitationPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get invitationPending;

  /// No description provided for @invitationAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get invitationAccepted;

  /// No description provided for @invitationDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get invitationDeclined;

  /// No description provided for @invitationCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get invitationCanceled;

  /// No description provided for @invitationExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get invitationExpired;

  /// No description provided for @cancelInvitation.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelInvitation;

  /// No description provided for @visitingTerrain.
  ///
  /// In en, this message translates to:
  /// **'Visiting {terrainName}'**
  String visitingTerrain(Object terrainName);

  /// No description provided for @returnToHostMode.
  ///
  /// In en, this message translates to:
  /// **'Return to host mode'**
  String get returnToHostMode;

  /// No description provided for @returnedToHostMode.
  ///
  /// In en, this message translates to:
  /// **'Successfully returned to host mode'**
  String get returnedToHostMode;

  /// No description provided for @errorReturningToHostMode.
  ///
  /// In en, this message translates to:
  /// **'Error returning to host mode'**
  String get errorReturningToHostMode;

  /// No description provided for @hostVisitorMode.
  ///
  /// In en, this message translates to:
  /// **'Visitor mode'**
  String get hostVisitorMode;

  /// No description provided for @connectedAsVisitor.
  ///
  /// In en, this message translates to:
  /// **'Connected as visitor'**
  String get connectedAsVisitor;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to a field to get started'**
  String get welcomeSubtitle;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Error {message}'**
  String genericError(Object message);

  /// No description provided for @invitationSentTo.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent to {username}'**
  String invitationSentTo(Object username);

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String minutesAgo(Object count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(Object count);

  /// No description provided for @shortDate.
  ///
  /// In en, this message translates to:
  /// **'{day}/{month}'**
  String shortDate(Object day, Object month);

  /// No description provided for @treasureFound.
  ///
  /// In en, this message translates to:
  /// **'{username} found {treasureName}!'**
  String treasureFound(Object treasureName, Object username);

  /// No description provided for @seeScores.
  ///
  /// In en, this message translates to:
  /// **'See scores'**
  String get seeScores;

  /// No description provided for @fieldOpened.
  ///
  /// In en, this message translates to:
  /// **'{ownerUsername}\'s field is now open'**
  String fieldOpened(Object ownerUsername);

  /// No description provided for @fieldClosedBy.
  ///
  /// In en, this message translates to:
  /// **'{ownerUsername}\'s field has been closed'**
  String fieldClosedBy(Object ownerUsername);

  /// No description provided for @invitationDeclinedBy.
  ///
  /// In en, this message translates to:
  /// **'{username} declined the invitation'**
  String invitationDeclinedBy(Object username);

  /// No description provided for @playerJoinedField.
  ///
  /// In en, this message translates to:
  /// **'{username} joined the field!'**
  String playerJoinedField(Object username);

  /// No description provided for @invitationReceivedBody.
  ///
  /// In en, this message translates to:
  /// **'{sender} invites you to join the field \"{field}\"'**
  String invitationReceivedBody(Object field, Object sender);

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @playerLeftField.
  ///
  /// In en, this message translates to:
  /// **'{username} left the field'**
  String playerLeftField(Object username);

  /// No description provided for @scenariosFieldUpdated.
  ///
  /// In en, this message translates to:
  /// **'Scenarios updated on the field'**
  String get scenariosFieldUpdated;

  /// No description provided for @teamCreated.
  ///
  /// In en, this message translates to:
  /// **'New team created: {teamName}'**
  String teamCreated(Object teamName);

  /// No description provided for @teamDeleted.
  ///
  /// In en, this message translates to:
  /// **'A team has been deleted.'**
  String get teamDeleted;

  /// No description provided for @disconnectedFieldByHost.
  ///
  /// In en, this message translates to:
  /// **'You have been disconnected from the field by the host'**
  String get disconnectedFieldByHost;

  /// No description provided for @playerDisconnectedOther.
  ///
  /// In en, this message translates to:
  /// **'{username} has been disconnected from the field'**
  String playerDisconnectedOther(Object username);

  /// No description provided for @invitationFromAndRole.
  ///
  /// In en, this message translates to:
  /// **'Invitation {role} {username}'**
  String invitationFromAndRole(Object role, Object username);

  /// No description provided for @roleTo.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get roleTo;

  /// No description provided for @roleFrom.
  ///
  /// In en, this message translates to:
  /// **'from'**
  String get roleFrom;

  /// No description provided for @pendingInvitationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending invitations {label}'**
  String pendingInvitationsLabel(Object label);

  /// No description provided for @mustBeHostAndFieldOpen.
  ///
  /// In en, this message translates to:
  /// **'You must be a host with an open field to send invitations'**
  String get mustBeHostAndFieldOpen;

  /// No description provided for @errorProcessingInvitation.
  ///
  /// In en, this message translates to:
  /// **'Error processing the invitation'**
  String get errorProcessingInvitation;

  /// No description provided for @connectedToFieldAsVisitor.
  ///
  /// In en, this message translates to:
  /// **'Connected to the field {fieldName} as a visitor'**
  String connectedToFieldAsVisitor(Object fieldName);

  /// No description provided for @errorConnectingToField.
  ///
  /// In en, this message translates to:
  /// **'Error connecting to the field'**
  String get errorConnectingToField;

  /// No description provided for @assignRoleEachTeam.
  ///
  /// In en, this message translates to:
  /// **'Please assign a role to each team.'**
  String get assignRoleEachTeam;

  /// No description provided for @requireTAndCTeams.
  ///
  /// In en, this message translates to:
  /// **'There must be at least one Terrorist team and one Counter-Terrorist team.'**
  String get requireTAndCTeams;

  /// No description provided for @bombAssignRolesTitle.
  ///
  /// In en, this message translates to:
  /// **'Role assignment for Bomb Operation'**
  String get bombAssignRolesTitle;

  /// No description provided for @bombAssignRolesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which team will be Terrorist (attack) and which will be Counter-Terrorist (defense).'**
  String get bombAssignRolesSubtitle;

  /// No description provided for @confirmRoles.
  ///
  /// In en, this message translates to:
  /// **'Confirm roles'**
  String get confirmRoles;

  /// No description provided for @terroristAttackLabel.
  ///
  /// In en, this message translates to:
  /// **'Terrorist (Attack)'**
  String get terroristAttackLabel;

  /// No description provided for @counterTerroristDefenseLabel.
  ///
  /// In en, this message translates to:
  /// **'Counter-Terrorist (Defense)'**
  String get counterTerroristDefenseLabel;

  /// No description provided for @gameStartedToast.
  ///
  /// In en, this message translates to:
  /// **'The game has started!'**
  String get gameStartedToast;

  /// No description provided for @gameEndedToast.
  ///
  /// In en, this message translates to:
  /// **'The game has ended.'**
  String get gameEndedToast;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @initializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get initializing;

  /// No description provided for @selectGameDuration.
  ///
  /// In en, this message translates to:
  /// **'Select game duration'**
  String get selectGameDuration;

  /// No description provided for @popularDurations.
  ///
  /// In en, this message translates to:
  /// **'Popular durations'**
  String get popularDurations;

  /// No description provided for @customDuration.
  ///
  /// In en, this message translates to:
  /// **'Custom duration'**
  String get customDuration;

  /// No description provided for @enterMinutes.
  ///
  /// In en, this message translates to:
  /// **'Enter minutes'**
  String get enterMinutes;

  /// No description provided for @unlimitedDurationSet.
  ///
  /// In en, this message translates to:
  /// **'Duration set to unlimited'**
  String get unlimitedDurationSet;

  /// No description provided for @durationSetToMinutes.
  ///
  /// In en, this message translates to:
  /// **'Duration set to {minutes} minutes'**
  String durationSetToMinutes(String minutes);

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get min;

  /// No description provided for @h.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get h;

  /// No description provided for @refreshFavorites.
  ///
  /// In en, this message translates to:
  /// **'Refresh favorites'**
  String get refreshFavorites;

  /// No description provided for @loadingFavorites.
  ///
  /// In en, this message translates to:
  /// **'Loading favorites...'**
  String get loadingFavorites;

  /// No description provided for @errorLoadingFavorites.
  ///
  /// In en, this message translates to:
  /// **'Error loading favorites'**
  String get errorLoadingFavorites;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorite players'**
  String get noFavorites;

  /// No description provided for @markPlayersAsFavorites.
  ///
  /// In en, this message translates to:
  /// **'Mark players as favorites by clicking the star in other tabs'**
  String get markPlayersAsFavorites;

  /// No description provided for @allFavoritesConnected.
  ///
  /// In en, this message translates to:
  /// **'All your favorites are already connected!'**
  String get allFavoritesConnected;

  /// No description provided for @favoritesInGame.
  ///
  /// In en, this message translates to:
  /// **'{count} favorite player(s) in the game'**
  String favoritesInGame(Object count);

  /// No description provided for @unknownPlayer.
  ///
  /// In en, this message translates to:
  /// **'Unknown player'**
  String get unknownPlayer;

  /// No description provided for @invitationSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent'**
  String get invitationSent;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @invited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get invited;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @playerAlreadyInvited.
  ///
  /// In en, this message translates to:
  /// **'⚠️ {playerName} is already invited'**
  String playerAlreadyInvited(Object playerName);

  /// No description provided for @errorSendingInvitation.
  ///
  /// In en, this message translates to:
  /// **'❌ Error sending invitation to {playerName}'**
  String errorSendingInvitation(Object playerName);

  /// No description provided for @targetEliminationConfig.
  ///
  /// In en, this message translates to:
  /// **'Target Elimination Configuration'**
  String get targetEliminationConfig;

  /// No description provided for @targetEliminationScenario.
  ///
  /// In en, this message translates to:
  /// **'Target Elimination (QR Codes)'**
  String get targetEliminationScenario;

  /// No description provided for @targetEliminationDescription.
  ///
  /// In en, this message translates to:
  /// **'Eliminate your targets by scanning their QR code'**
  String get targetEliminationDescription;

  /// No description provided for @gameRules.
  ///
  /// In en, this message translates to:
  /// **'Game Rules'**
  String get gameRules;

  /// No description provided for @gameMode.
  ///
  /// In en, this message translates to:
  /// **'Game Mode'**
  String get gameMode;

  /// No description provided for @soloMode.
  ///
  /// In en, this message translates to:
  /// **'Solo'**
  String get soloMode;

  /// No description provided for @teamMode.
  ///
  /// In en, this message translates to:
  /// **'Team Mode'**
  String get teamMode;

  /// No description provided for @friendlyFire.
  ///
  /// In en, this message translates to:
  /// **'Friendly Fire'**
  String get friendlyFire;

  /// No description provided for @friendlyFireDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow elimination of teammates'**
  String get friendlyFireDescription;

  /// No description provided for @parameters.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get parameters;

  /// No description provided for @pointsPerElimination.
  ///
  /// In en, this message translates to:
  /// **'Points per elimination'**
  String get pointsPerElimination;

  /// No description provided for @immunityCooldownMinutes.
  ///
  /// In en, this message translates to:
  /// **'Immunity cooldown (minutes)'**
  String get immunityCooldownMinutes;

  /// No description provided for @numberOfQRCodes.
  ///
  /// In en, this message translates to:
  /// **'Number of QR codes to generate'**
  String get numberOfQRCodes;

  /// No description provided for @announcementTemplate.
  ///
  /// In en, this message translates to:
  /// **'Announcement template'**
  String get announcementTemplate;

  /// No description provided for @announcementTemplateHelp.
  ///
  /// In en, this message translates to:
  /// **'Use {killer}, {victim}, {killerTeam}, {victimTeam}'**
  String announcementTemplateHelp(
      Object killer, Object killerTeam, Object victim, Object victimTeam);

  /// No description provided for @qrCodeGeneration.
  ///
  /// In en, this message translates to:
  /// **'QR Code Generation'**
  String get qrCodeGeneration;

  /// No description provided for @generateQRCodes.
  ///
  /// In en, this message translates to:
  /// **'Generate QR Codes'**
  String get generateQRCodes;

  /// No description provided for @downloadPDF.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPDF;

  /// No description provided for @shareQRCodes.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareQRCodes;

  /// No description provided for @printQRCodes.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printQRCodes;

  /// No description provided for @youAreTargetNumber.
  ///
  /// In en, this message translates to:
  /// **'You are target number {number} for elimination'**
  String youAreTargetNumber(Object number);

  /// No description provided for @waitingForTargetAssignment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for target assignment...'**
  String get waitingForTargetAssignment;

  /// No description provided for @myQRCode.
  ///
  /// In en, this message translates to:
  /// **'My QR Code'**
  String get myQRCode;

  /// No description provided for @scanQRCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQRCode;

  /// No description provided for @showMyQRCode.
  ///
  /// In en, this message translates to:
  /// **'Show My QR'**
  String get showMyQRCode;

  /// No description provided for @kills.
  ///
  /// In en, this message translates to:
  /// **'Kills'**
  String get kills;

  /// No description provided for @deaths.
  ///
  /// In en, this message translates to:
  /// **'Deaths'**
  String get deaths;

  /// No description provided for @killDeathRatio.
  ///
  /// In en, this message translates to:
  /// **'K/D Ratio'**
  String get killDeathRatio;

  /// No description provided for @recentEliminations.
  ///
  /// In en, this message translates to:
  /// **'Recent Eliminations'**
  String get recentEliminations;

  /// No description provided for @noRecentEliminations.
  ///
  /// In en, this message translates to:
  /// **'No recent eliminations'**
  String get noRecentEliminations;

  /// No description provided for @playerEliminated.
  ///
  /// In en, this message translates to:
  /// **'{killer} eliminated {victim}'**
  String playerEliminated(Object killer, Object victim);

  /// No description provided for @youEliminatedPlayer.
  ///
  /// In en, this message translates to:
  /// **'You eliminated {victim}'**
  String youEliminatedPlayer(Object victim);

  /// No description provided for @youWereEliminated.
  ///
  /// In en, this message translates to:
  /// **'You were eliminated by {killer}'**
  String youWereEliminated(Object killer);

  /// No description provided for @playerInCooldown.
  ///
  /// In en, this message translates to:
  /// **'{victim} is still immune for {time}'**
  String playerInCooldown(Object time, Object victim);

  /// No description provided for @friendlyFireBlocked.
  ///
  /// In en, this message translates to:
  /// **'Friendly fire blocked: {victim} is on your team'**
  String friendlyFireBlocked(Object victim);

  /// No description provided for @cannotEliminateSelf.
  ///
  /// In en, this message translates to:
  /// **'You cannot eliminate yourself'**
  String get cannotEliminateSelf;

  /// No description provided for @qrCodeNotRecognized.
  ///
  /// In en, this message translates to:
  /// **'QR code not recognized'**
  String get qrCodeNotRecognized;

  /// No description provided for @scenarioNotActive.
  ///
  /// In en, this message translates to:
  /// **'Scenario is not active'**
  String get scenarioNotActive;

  /// No description provided for @scoresLocked.
  ///
  /// In en, this message translates to:
  /// **'Scores are locked'**
  String get scoresLocked;

  /// No description provided for @alreadyEliminated.
  ///
  /// In en, this message translates to:
  /// **'Target already eliminated recently'**
  String get alreadyEliminated;

  /// No description provided for @errorScanningQR.
  ///
  /// In en, this message translates to:
  /// **'Error scanning QR code'**
  String get errorScanningQR;

  /// No description provided for @configurationSaved.
  ///
  /// In en, this message translates to:
  /// **'Configuration saved'**
  String get configurationSaved;

  /// No description provided for @errorSavingConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Error saving configuration'**
  String get errorSavingConfiguration;

  /// No description provided for @invalidPoints.
  ///
  /// In en, this message translates to:
  /// **'Invalid points'**
  String get invalidPoints;

  /// No description provided for @invalidCooldown.
  ///
  /// In en, this message translates to:
  /// **'Invalid cooldown'**
  String get invalidCooldown;

  /// No description provided for @scoreboard.
  ///
  /// In en, this message translates to:
  /// **'Scoreboard'**
  String get scoreboard;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @topKillers.
  ///
  /// In en, this message translates to:
  /// **'Top Killers'**
  String get topKillers;

  /// No description provided for @teamScores.
  ///
  /// In en, this message translates to:
  /// **'Team Scores'**
  String get teamScores;

  /// No description provided for @individualScores.
  ///
  /// In en, this message translates to:
  /// **'Individual Scores'**
  String get individualScores;

  /// No description provided for @killer.
  ///
  /// In en, this message translates to:
  /// **'Killer'**
  String get killer;

  /// No description provided for @killerTeam.
  ///
  /// In en, this message translates to:
  /// **'Killer team'**
  String get killerTeam;

  /// No description provided for @victim.
  ///
  /// In en, this message translates to:
  /// **'Victim'**
  String get victim;

  /// No description provided for @victimTeam.
  ///
  /// In en, this message translates to:
  /// **'Victim team'**
  String get victimTeam;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'it',
        'ja',
        'nl',
        'no',
        'pl',
        'pt',
        'sv'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'nl':
      return AppLocalizationsNl();
    case 'no':
      return AppLocalizationsNo();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'sv':
      return AppLocalizationsSv();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
