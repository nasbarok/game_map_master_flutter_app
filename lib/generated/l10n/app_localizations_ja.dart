// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Game Map Master';

  @override
  String get selectLanguage => '言語を選択';

  @override
  String get cancel => 'キャンセル';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get save => '保存';

  @override
  String get delete => '削除';

  @override
  String get edit => '編集';

  @override
  String get create => '作成';

  @override
  String get loading => '読み込み中...';

  @override
  String get error => 'エラー';

  @override
  String get success => '成功';

  @override
  String get warning => '警告';

  @override
  String get info => '情報';

  @override
  String get connectionInProgress => '接続中...';

  @override
  String get sendingCredentials => 'AuthServiceに認証情報を送信中...';

  @override
  String get connectionSuccessful => '接続成功。セッション復元を開始...';

  @override
  String get sessionPotentiallyRestored => 'フィールドセッションが復元された可能性があります。';

  @override
  String get automaticReconnection => 'ユーザーのフィールドへの自動再接続...';

  @override
  String get rejoinedFieldSuccessfully => 'フィールドへの再参加に成功。セッションを再読み込み...';

  @override
  String get userAlreadyConnected => 'ユーザーは既にフィールドに接続されています。';

  @override
  String get noActiveFieldOrUser => 'アクティブなフィールドがないか、ユーザーが定義されていません。';

  @override
  String get automaticReconnectionError => '自動再接続試行中にエラーが発生しました';

  @override
  String get username => 'ユーザー名';

  @override
  String get password => 'パスワード';

  @override
  String get login => 'ログイン';

  @override
  String get register => '登録';

  @override
  String get email => 'メール';

  @override
  String get confirmPassword => 'パスワード確認';

  @override
  String get firstName => '名';

  @override
  String get lastName => '姓';

  @override
  String get fieldManagement => 'フィールド管理';

  @override
  String get mapsManagement => 'マップ管理';

  @override
  String get scenariosManagement => 'シナリオ管理';

  @override
  String get playersManagement => 'プレイヤー管理';

  @override
  String get openField => 'フィールドを開く';

  @override
  String get closeField => 'フィールドを閉じる';

  @override
  String get startGame => 'ゲーム開始';

  @override
  String get stopGame => 'ゲーム停止';

  @override
  String get gameTime => 'ゲーム時間';

  @override
  String get selectMap => 'マップを選択';

  @override
  String get selectScenarios => 'シナリオを選択';

  @override
  String get connectedPlayers => '接続中のプレイヤー';

  @override
  String get teams => 'チーム';

  @override
  String get createTeam => 'チーム作成';

  @override
  String get teamName => 'チーム名';

  @override
  String get joinTeam => 'チームに参加';

  @override
  String get leaveTeam => 'チームを離れる';

  @override
  String get invitePlayers => 'プレイヤーを招待';

  @override
  String get searchPlayers => 'プレイヤーを検索';

  @override
  String get sendInvitation => '招待を送信';

  @override
  String get acceptInvitation => '招待を受諾';

  @override
  String get declineInvitation => '招待を拒否';

  @override
  String get invitations => '招待';

  @override
  String get noInvitations => '招待なし';

  @override
  String get mapName => 'マップ名';

  @override
  String get mapDescription => 'マップ説明';

  @override
  String get createMap => 'マップ作成';

  @override
  String get editMap => 'マップ編集';

  @override
  String get deleteMap => 'マップ削除';

  @override
  String get scenarioName => 'シナリオ名';

  @override
  String get scenarioDescription => 'シナリオ説明';

  @override
  String get createScenario => 'シナリオ作成';

  @override
  String get editScenario => 'シナリオ編集';

  @override
  String get deleteScenario => 'シナリオ削除';

  @override
  String get treasureHunt => '宝探し';

  @override
  String get bombDefusal => '爆弾解除';

  @override
  String get captureTheFlag => 'フラッグ奪取';

  @override
  String get gpsQuality => 'GPS品質';

  @override
  String get speed => '速度';

  @override
  String get stationary => '静止';

  @override
  String get walking => '歩行';

  @override
  String get running => '走行';

  @override
  String get tactical => '戦術的';

  @override
  String get immobile => '不動';

  @override
  String get gameHistory => 'ゲーム履歴';

  @override
  String get gameReplay => 'ゲームリプレイ';

  @override
  String get sessionDetails => 'セッション詳細';

  @override
  String get duration => '継続時間';

  @override
  String get startTime => '開始時刻';

  @override
  String get endTime => '終了時刻';

  @override
  String get participants => '参加者';

  @override
  String get settings => '設定';

  @override
  String get language => '言語';

  @override
  String get notifications => '通知';

  @override
  String get sound => '音';

  @override
  String get vibration => '振動';

  @override
  String get about => 'について';

  @override
  String get version => 'バージョン';

  @override
  String get logout => 'ログアウト';

  @override
  String get confirmLogout => 'ログアウトしてもよろしいですか？';

  @override
  String get networkError => 'ネットワークエラー。接続を確認してください。';

  @override
  String get serverError => 'サーバーエラー。後でもう一度お試しください。';

  @override
  String get invalidCredentials => '無効なユーザー名またはパスワード。';

  @override
  String get fieldRequired => 'このフィールドは必須です。';

  @override
  String get emailInvalid => '有効なメールアドレスを入力してください。';

  @override
  String get passwordTooShort => 'パスワードは6文字以上である必要があります。';

  @override
  String get passwordsDoNotMatch => 'パスワードが一致しません。';

  @override
  String get welcomeMessage => 'Game Map Masterへようこそ！';

  @override
  String get gameInProgress => 'ゲーム進行中';

  @override
  String get gameFinished => 'ゲーム終了';

  @override
  String get waitingForPlayers => 'プレイヤー待機中';

  @override
  String get fieldClosed => 'フィールド閉鎖';

  @override
  String get fieldOpen => 'フィールド開放';

  @override
  String get promptUsername => 'ユーザー名を入力してください';

  @override
  String get promptPassword => 'パスワードを入力してください';

  @override
  String get registerTitle => '登録';

  @override
  String get createAccount => 'アカウントを作成';

  @override
  String get usernameLabel => 'ユーザー名';

  @override
  String get usernamePrompt => 'ユーザー名を入力してください';

  @override
  String get emailLabel => 'メール';

  @override
  String get emailPrompt => 'メールアドレスを入力してください';

  @override
  String get passwordLabel => 'パスワード';

  @override
  String get passwordPrompt => 'パスワードを入力してください';

  @override
  String get confirmPasswordLabel => 'パスワード確認';

  @override
  String get confirmPasswordPrompt => 'パスワードを確認してください';

  @override
  String get firstNameLabel => '名';

  @override
  String get lastNameLabel => '姓';

  @override
  String get phoneNumberLabel => '電話番号';

  @override
  String get roleLabel => '役割';

  @override
  String get rolePrompt => '役割を選択してください';

  @override
  String get roleHost => '主催者';

  @override
  String get roleGamer => 'プレイヤー';

  @override
  String get registerButton => '登録';

  @override
  String get alreadyRegistered => '既に登録済みですか？ ログイン';

  @override
  String get registrationSuccess => '登録が成功しました！ログインできます。';

  @override
  String get registrationFailure => '登録に失敗しました。もう一度お試しください。';

  @override
  String get loginFailed => 'ログインに失敗しました。認証情報を確認してください。';

  @override
  String get splashTitle => 'Game Map Master';

  @override
  String get splashSubtitle => 'Créez et jouez des scénarios 2.0';

  @override
  String get splashScreenSubtitle => '2.0シナリオを作成してプレイ';

  @override
  String get gameLobbyTitle => 'ゲームロビー';

  @override
  String get terrainTab => 'フィールド';

  @override
  String get playersTab => 'プレイヤー';

  @override
  String mapLabel(Object mapName) {
    return 'マップ: $mapName';
  }

  @override
  String get unknownMap => '不明';

  @override
  String get sessionsHistoryTooltip => 'セッション履歴';

  @override
  String get noAssociatedField => '関連するフィールドが見つかりません';

  @override
  String remainingTimeLabel(Object time) {
    return '残り時間: $time';
  }

  @override
  String get gameInProgressTitle => 'ゲーム進行中';

  @override
  String get gameInProgressInstructions =>
      'ホストの指示に従い、チームと協力してシナリオの目標を達成してください。';

  @override
  String get joinGameButton => 'ゲームに参加';

  @override
  String get waitingForGameStartTitle => 'ゲーム開始待ち';

  @override
  String get waitingForGameStartInstructions =>
      'ホストがまだゲームを開始していません。準備を整え、チームに参加してお待ちください。';

  @override
  String get leaveFieldButton => 'フィールドを退出';

  @override
  String get noScenarioSelected => 'シナリオが選択されていません';

  @override
  String get selectedScenariosLabel => '選択されたシナリオ：';

  @override
  String treasureHuntScenarioDetails(Object count, Object symbol) {
    return '宝探し: $count QRコード ($symbol)';
  }

  @override
  String get noDescription => '説明なし';

  @override
  String loadingError(Object error) {
    return 'エラー: $error';
  }

  @override
  String get noFieldsVisited => '訪問したフィールドがありません';

  @override
  String get waitForInvitation => 'フィールドに参加するために招待を待っています';

  @override
  String fieldOpenedOn(Object date) {
    return '$date にオープン';
  }

  @override
  String get unknownOpeningDate => '不明なオープン日';

  @override
  String fieldClosedOn(Object date) {
    return '$date にクローズ';
  }

  @override
  String get stillActive => 'まだアクティブ';

  @override
  String ownerLabel(Object username) {
    return '所有者: $username';
  }

  @override
  String get unknownOwner => '不明な所有者';

  @override
  String get fieldStatusOpen => 'オープン';

  @override
  String get fieldStatusClosed => 'クローズ';

  @override
  String get joinButton => '参加する';

  @override
  String get deleteFromHistoryTooltip => '履歴から削除';

  @override
  String get youJoinedFieldSuccess => 'フィールドに参加しました';

  @override
  String get youLeftField => 'フィールドを離れました';

  @override
  String get notConnectedToField => 'どのフィールドにも接続していません';

  @override
  String connectedPlayersCount(Object count) {
    return '接続中のプレイヤー ($count)';
  }

  @override
  String get noPlayerConnected => '接続中のプレイヤーはいません';

  @override
  String get noTeam => 'チームなし';

  @override
  String get youLabel => 'あなた';

  @override
  String get yourTeamLabel => 'あなたのチーム';

  @override
  String get manageTeamsButton => 'チーム管理';

  @override
  String get changeTeamTitle => 'チームを変更';

  @override
  String playersCountSuffix(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'プレイヤー',
      one: 'プレイヤー',
      zero: 'プレイヤー',
    );
    return '$_temp0';
  }

  @override
  String get leaveFieldConfirmationTitle => 'フィールドを離れますか？';

  @override
  String get leaveFieldConfirmationMessage => 'このフィールドを離れますか？閉じられた場合、再参加できません。';

  @override
  String get leaveButton => '退出';

  @override
  String get deleteFieldHistoryTitle => 'このフィールドを削除しますか？';

  @override
  String get deleteFieldHistoryMessage => 'このフィールドを履歴から削除してもよろしいですか？';

  @override
  String get fieldDeletedFromHistory => 'フィールドが履歴から削除されました';

  @override
  String get errorDeletingField => '削除中にエラーが発生しました';

  @override
  String get cannotJoinGame => 'ゲームに参加できません';

  @override
  String get joinTeamTitle => 'チームに参加';

  @override
  String errorLoadingTeams(Object error) {
    return 'チームの読み込み中にエラー: $error';
  }

  @override
  String get retryButton => '再試行';

  @override
  String get noTeamsAvailableTitle => 'チームがありません';

  @override
  String get noTeamsAvailableMessage => '主催者にチームを作成してもらってください';

  @override
  String get refreshButton => '更新';

  @override
  String joinedTeamSuccess(Object teamName) {
    return '$teamName チームに参加しました';
  }

  @override
  String get teamManagementTitle => 'チーム管理';

  @override
  String get errorLoadingTeamsAlt => 'チームの読み込みエラー';

  @override
  String get joinedTeamSuccessAlt => 'チームに正常に参加しました';

  @override
  String errorJoiningTeam(Object error) {
    return 'チーム参加エラー: $error';
  }

  @override
  String get noTeamsAvailableHostMessage => 'ホストがチームを作成するのを待っています';

  @override
  String get yourTeamChip => 'あなたのチーム';

  @override
  String get noPlayersConnectedMessage => '接続されたプレイヤーはここに表示されます';

  @override
  String get gameMapScreenTitle => 'ゲームマップ';

  @override
  String get fullscreenTooltip => '全画面表示';

  @override
  String get satelliteViewTooltip => '衛星ビュー';

  @override
  String get standardViewTooltip => '標準ビュー';

  @override
  String bombTimeRemaining(Object time) {
    return '爆弾: $time';
  }

  @override
  String get centerOnLocationTooltip => '現在地に中心を合わせる';

  @override
  String errorCenteringLocation(Object error) {
    return '現在地への中心合わせエラー: $error';
  }

  @override
  String playerMarkerLabel(Object playerName) {
    return 'プレイヤー $playerName';
  }

  @override
  String get gameSessionScreenTitle => 'ゲームセッション';

  @override
  String errorLoadingSessionData(Object error) {
    return 'セッションデータ読み込みエラー: $error';
  }

  @override
  String get endGameTooltip => 'ゲーム終了';

  @override
  String get refreshTooltip => '更新';

  @override
  String get bombScenarioLoading => '爆弾シナリオを読み込み中...';

  @override
  String get qrScannerButtonActive => 'QRコードをスキャン';

  @override
  String get noActiveTreasureHunt => 'アクティブな宝探しシナリオがありません';

  @override
  String get gameEndedMessage => 'ゲームが終了しました。';

  @override
  String errorEndingGame(Object error) {
    return 'ゲーム終了中にエラー: $error';
  }

  @override
  String get noScoresYet => 'スコアはまだありません';

  @override
  String treasureFoundNotification(
      Object username, Object teamName, Object points, Object symbol) {
    return '$username (チーム $teamName) が$pointsポイントの宝物を見つけました！ ($symbol)';
  }

  @override
  String treasureFoundNotificationNoTeam(
      Object username, Object points, Object symbol) {
    return '$username が$pointsポイントの宝物を見つけました！ ($symbol)';
  }

  @override
  String fieldSessionsTitle(Object fieldName) {
    return 'セッション - $fieldName';
  }

  @override
  String get unknownField => '不明なフィールド';

  @override
  String get gameSessionsTitle => 'ゲームセッション';

  @override
  String errorLoadingData(Object error) {
    return 'データ読み込みエラー: $error';
  }

  @override
  String get noGameSessionsForField => 'このフィールドに利用可能なセッションはありません';

  @override
  String sessionListItemTitle(Object index) {
    return 'セッション #$index';
  }

  @override
  String sessionStatusLabel(Object status) {
    return 'ステータス: $status';
  }

  @override
  String sessionTimeLabel(Object startTime, Object endTime) {
    return '開始: $startTime - 終了: $endTime';
  }

  @override
  String sessionStartTimeLabel(Object startTime) {
    return '開始: $startTime';
  }

  @override
  String get deleteSessionSuccess => 'ゲームセッションを削除しました';

  @override
  String get confirmation => '確認';

  @override
  String get deleteSessionConfirmationMessage => 'このゲームセッションを削除してもよろしいですか？';

  @override
  String get replayScreenTitle => 'セッションリプレイ';

  @override
  String get scenarioSummaryTitle => 'シナリオ概要';

  @override
  String get scenarioInfoNotAvailable => '情報はありません';

  @override
  String playbackSpeedLabel(Object speed) {
    return '速度: $speed倍';
  }

  @override
  String errorLoadingHistory(Object error) {
    return '履歴の読み込み中にエラーが発生しました: $error';
  }

  @override
  String get sessionDetailsScreenTitle => 'セッション詳細';

  @override
  String sessionTitleWithIndex(Object index) {
    return 'セッション #$index';
  }

  @override
  String get noSessionFound => 'セッションが見つかりません';

  @override
  String get viewSessionsForFieldTooltip => 'このフィールドのセッションを表示';

  @override
  String fieldLabel(Object fieldName) {
    return 'フィールド: $fieldName';
  }

  @override
  String endTimeLabel(Object time) {
    return '終了: $time';
  }

  @override
  String participantsLabel(Object count) {
    return '参加者: $count';
  }

  @override
  String get viewReplayButton => 'リプレイを見る';

  @override
  String get scenariosLabel => 'シナリオ';

  @override
  String get scenarioNameDefault => '名前なしシナリオ';

  @override
  String get treasureHuntScoreboardTitle => '宝探しスコアボード';

  @override
  String get bombOperationResultsTitle => '爆弾作戦結果';

  @override
  String get teamScoresLabel => 'チームスコア';

  @override
  String get individualScoresLabel => '個人スコア';

  @override
  String get rankLabel => '順位';

  @override
  String get nameLabel => '名前';

  @override
  String get treasuresLabel => '宝物';

  @override
  String get scoreLabel => 'スコア';

  @override
  String get terroristsTeam => 'テロリスト';

  @override
  String get counterTerroristsTeam => '対テロ部隊';

  @override
  String get armedSitesLabel => '武装サイト';

  @override
  String get explodedSitesLabel => '爆発済サイト';

  @override
  String get activeSitesLabel => 'アクティブサイト';

  @override
  String get disarmedSitesLabel => '解除済サイト';

  @override
  String get terroristsWinResult => '🔥 テロリスト勝利';

  @override
  String get counterTerroristsWinResult => '🛡️ 対テロ勝利';

  @override
  String get drawResult => '🤝 引き分け';

  @override
  String get detailedStatsLabel => '詳細統計';

  @override
  String get statisticLabel => '統計';

  @override
  String get valueLabel => '値';

  @override
  String get totalSitesStat => '総サイト数';

  @override
  String get bombTimerStat => '爆弾タイマー';

  @override
  String get defuseTimeStat => '解除時間';

  @override
  String get armingTimeStat => '設置時間';

  @override
  String get historyScreenTitleField => 'フィールド履歴';

  @override
  String get historyScreenTitleGeneric => 'フィールド全履歴';

  @override
  String get noFieldsAvailable => '利用可能なフィールドがありません';

  @override
  String get deleteFieldTooltip => 'このフィールドを削除';

  @override
  String deleteFieldConfirmationMessage(Object fieldName) {
    return 'フィールド「$fieldName」とその履歴を削除してもよろしいですか？';
  }

  @override
  String fieldDeletedSuccess(Object fieldName) {
    return 'フィールド「$fieldName」を削除しました';
  }

  @override
  String get newFieldTitle => '新しいフィールド';

  @override
  String get editFieldTitle => 'フィールド編集';

  @override
  String get fieldNameLabel => 'フィールド名 *';

  @override
  String get fieldDescriptionLabel => '説明';

  @override
  String get fieldAddressLabel => '住所';

  @override
  String get latitudeLabel => '緯度';

  @override
  String get longitudeLabel => '経度';

  @override
  String get widthLabel => '幅 (m)';

  @override
  String get lengthLabel => '長さ (m)';

  @override
  String get createFieldButton => 'フィールドを作成';

  @override
  String get updateFieldButton => 'フィールドを更新';

  @override
  String get fieldRequiredError => 'フィールド名を入力してください';

  @override
  String get fieldSavedSuccess => 'フィールドが正常に保存されました';

  @override
  String get newMapTitle => '新しいマップ';

  @override
  String get scaleLabel => 'スケール (m/ピクセル)';

  @override
  String get mapNameRequiredError => 'マップ名を入力してください';

  @override
  String get invalidScaleError => '有効なスケールを入力してください';

  @override
  String get interactiveMapAddressLabel => 'フィールド住所';

  @override
  String get defineInteractiveMapButton => 'インタラクティブマップを定義';

  @override
  String get editInteractiveMapButton => 'インタラクティブマップを編集';

  @override
  String get mapSavedSuccess => 'マップが正常に保存されました';

  @override
  String get updateMapButton => 'マップを更新';

  @override
  String get hostDashboardTitle => 'ホストダッシュボード';

  @override
  String get historyTab => '履歴';

  @override
  String get invitationReceivedTitle => '招待を受信';

  @override
  String invitationReceivedMessage(Object username, Object mapName) {
    return '$username から「$mapName」マップへの招待が届きました。';
  }

  @override
  String get noActionForFieldTabSnackbar => '「マップ」タブでマップを作成または編集してください';

  @override
  String get openFieldFirstSnackbar => '先にフィールドを開いてください';

  @override
  String get noMapAvailable => 'マップなし';

  @override
  String get createMapPrompt => 'マップを作成して開始しましょう';

  @override
  String get noScenarioAvailable => 'シナリオなし';

  @override
  String get createScenarioPrompt => 'シナリオを作成して開始しましょう';

  @override
  String get scoreboardButton => 'スコアボード';

  @override
  String get confirmDeleteTitle => '削除の確認';

  @override
  String get confirmDeleteMapMessage => 'このマップを削除してもよろしいですか？';

  @override
  String get mapDeletedSuccess => 'マップが削除されました';

  @override
  String errorDeletingMap(Object error) {
    return 'マップ削除中にエラーが発生しました: $error';
  }

  @override
  String get confirmDeleteScenarioMessage => 'このシナリオを削除してもよろしいですか？';

  @override
  String get scenarioDeletedSuccess => 'シナリオが削除されました';

  @override
  String get noTeamsCreated => 'チームなし';

  @override
  String get createTeamPrompt => 'チームを作成して開始しましょう';

  @override
  String get playersUnavailableTitle => 'プレイヤー管理が利用できません';

  @override
  String get goToFieldTabButton => 'フィールドタブへ移動';

  @override
  String errorLoadingMaps(Object error) {
    return 'マップ読み込みエラー: $error';
  }

  @override
  String errorLoadingScenarios(Object error) {
    return 'シナリオ読み込みエラー: $error';
  }

  @override
  String get searchTab => '検索';

  @override
  String get searchPlayersHint => 'ユーザー名を入力';

  @override
  String get noResultsFound => '結果がありません。別の検索を試してください。';

  @override
  String get inviteButton => '招待する';

  @override
  String invitationFrom(Object username) {
    return '$username からの招待';
  }

  @override
  String mapLabelShort(Object mapName) {
    return 'マップ: $mapName';
  }

  @override
  String get invitationsSentTitle => '送信した招待';

  @override
  String get noInvitationsSent => '送信した招待はありません';

  @override
  String invitationTo(Object username) {
    return '$username への招待';
  }

  @override
  String get statusPending => '保留中';

  @override
  String get statusAccepted => '承認済み';

  @override
  String get statusDeclined => '辞退済み';

  @override
  String get unassignedPlayersLabel => '未割り当てプレイヤー';

  @override
  String get assignTeamHint => '割り当て';

  @override
  String get kickPlayerTooltip => 'プレイヤーをキック';

  @override
  String get removeFromTeamTooltip => 'チームから削除';

  @override
  String playerKickedSuccess(Object playerName) {
    return '$playerName がゲームから削除されました';
  }

  @override
  String errorKickingPlayer(Object error) {
    return 'プレイヤーの削除中にエラー: $error';
  }

  @override
  String get playerManagementUnavailableTitle => 'プレイヤー管理は利用できません';

  @override
  String get newTeamButton => '新しいチーム';

  @override
  String get saveConfigurationButton => '設定を保存';

  @override
  String get saveConfigurationDialogTitle => '設定を保存';

  @override
  String get configurationNameLabel => '設定名';

  @override
  String get configurationSavedSuccess => '設定が保存されました';

  @override
  String get addPlayersToTeamDialogTitle => 'プレイヤーを追加';

  @override
  String get alreadyInTeamLabel => 'すでにチームに所属';

  @override
  String get addButton => '追加';

  @override
  String get renameTeamDialogTitle => 'チーム名を変更';

  @override
  String get newTeamNameLabel => '新しい名前';

  @override
  String get renameButton => '名前を変更';

  @override
  String qrCodeForScenarioTitle(Object scenarioName) {
    return '$scenarioName のQRコード';
  }

  @override
  String errorGeneratingQRCode(Object error) {
    return 'QRコード生成エラー: $error';
  }

  @override
  String get scanToJoinMessage => 'このQRをスキャンしてゲームに参加';

  @override
  String invitationCodeLabel(Object code) {
    return '招待コード: $code';
  }

  @override
  String get codeValidForHour => 'このコードは1時間有効です';

  @override
  String get generateNewCodeButton => '新しいコードを生成';

  @override
  String get newScenarioTitle => '新しいシナリオ';

  @override
  String get scenarioTypeLabel => 'シナリオタイプ *';

  @override
  String get scenarioTypeBombOperation => '爆弾作戦';

  @override
  String get scenarioTypeDomination => '支配';

  @override
  String get scenarioNameRequiredError => 'シナリオ名を入力してください';

  @override
  String get scenarioTypeRequiredError => 'シナリオタイプを選択してください';

  @override
  String get mapRequiredError => 'マップを選択してください';

  @override
  String get interactiveMapRequiredError =>
      'このマップはインタラクティブ構成がありません。別のマップを選択するか、エディターで設定してください。';

  @override
  String get scenarioSavedSuccess => 'シナリオが保存されました';

  @override
  String get updateScenarioButton => 'シナリオを更新';

  @override
  String get configureTreasureHuntButton => '宝探しを設定';

  @override
  String get configureBombOperationButton => '爆弾作戦を設定';

  @override
  String get noMapAvailableError => '利用可能なマップがありません。まずマップを作成してください。';

  @override
  String get interactiveMapAvailableLegend => 'インタラクティブマップ利用可能';

  @override
  String get selectMapFirstError => '先にマップを選択してください。';

  @override
  String get selectScenariosDialogTitle => 'シナリオを選択';

  @override
  String get noScenariosAvailableDialogMessage =>
      '利用可能なシナリオがありません。\nまずシナリオを作成してください。';

  @override
  String get validateButton => '確認';

  @override
  String get newTeamScreenTitle => '新しいチーム';

  @override
  String get editTeamTitle => 'チームを編集';

  @override
  String get teamColorLabel => 'チームカラー';

  @override
  String get colorRed => '赤';

  @override
  String get colorBlue => '青';

  @override
  String get colorGreen => '緑';

  @override
  String get colorYellow => '黄';

  @override
  String get colorOrange => 'オレンジ';

  @override
  String get colorPurple => '紫';

  @override
  String get colorBlack => '黒';

  @override
  String get colorWhite => '白';

  @override
  String get teamNameRequiredError => 'チーム名を入力してください';

  @override
  String get teamSavedSuccess => 'チームが保存されました';

  @override
  String get updateTeamButton => 'チームを更新';

  @override
  String get selectMapError => 'まずマップを選択してください';

  @override
  String get scenariosSelectedSuccess => 'シナリオが選択されました';

  @override
  String durationSetSuccess(Object hours, Object minutes) {
    return '設定された時間: $hours時間 $minutes分';
  }

  @override
  String errorStartingGame(Object error) {
    return 'ゲーム開始中にエラーが発生しました: $error';
  }

  @override
  String get gameStartedSuccess => 'ゲームが開始されました！';

  @override
  String get bombScenarioRequiresTwoTeamsError => '爆弾シナリオには正確に2つのチームが必要です。';

  @override
  String get bombConfigurationCancelled => '設定がキャンセルされました。';

  @override
  String get bombConfigurationTitle => '爆弾シナリオ設定';

  @override
  String mapSelectedSuccess(Object mapName) {
    return 'マップ「$mapName」が選択されました';
  }

  @override
  String fieldOpenedSuccess(Object fieldName) {
    return 'フィールドが開かれました: $fieldName';
  }

  @override
  String get fieldClosedSuccess => 'フィールドが閉じられました';

  @override
  String errorOpeningClosingField(Object error) {
    return 'フィールドの開閉時にエラーが発生しました: $error';
  }

  @override
  String mapCardTitle(Object mapName) {
    return '$mapName';
  }

  @override
  String get noScenarioInfoCard => 'なし';

  @override
  String get unlimitedDurationInfoCard => '無制限';

  @override
  String get gameConfigurationTitle => 'ゲーム設定';

  @override
  String get selectMapButtonLabel => 'マップを選択';

  @override
  String get selectScenariosButtonLabel => 'シナリオを選択';

  @override
  String get setDurationButtonLabel => '時間を設定';

  @override
  String get participateAsPlayerLabel => 'プレイヤーとして参加:';

  @override
  String teamLabelPlayerList(Object teamName) {
    return 'チーム: $teamName';
  }

  @override
  String get youHostLabel => 'あなた (ホスト)';

  @override
  String get loadingDialogMessage => 'ゲームを開始中...';

  @override
  String get interactiveMapEditorTitleCreate => 'インタラクティブマップを作成';

  @override
  String interactiveMapEditorTitleEdit(Object mapName) {
    return '編集: $mapName';
  }

  @override
  String get saveMapTooltip => 'マップを保存';

  @override
  String get descriptionOptionalLabel => '説明（任意）';

  @override
  String get searchAddressLabel => '住所を検索';

  @override
  String get viewModeLabel => 'ビュー';

  @override
  String get drawBoundaryModeLabel => 'フィールド';

  @override
  String get drawZoneModeLabel => 'ゾーン';

  @override
  String get placePOIModeLabel => 'ポイント';

  @override
  String get defineBoundariesButton => '境界を定義';

  @override
  String get undoPointButton => 'ポイントを元に戻す';

  @override
  String get clearAllButton => 'すべてクリア';

  @override
  String get addZoneButton => 'ゾーンを追加';

  @override
  String get clearCurrentZoneButton => '現在のゾーンをクリア';

  @override
  String get noZoneDefined => 'ゾーンが定義されていません。';

  @override
  String get manageZonesTitle => 'ゾーン管理';

  @override
  String get hideTooltip => '非表示';

  @override
  String get showTooltip => '表示';

  @override
  String get confirmDeleteZoneTitle => 'ゾーンを削除';

  @override
  String confirmDeleteZoneMessage(Object zoneName) {
    return 'ゾーン「$zoneName」を削除してもよろしいですか？';
  }

  @override
  String get noPOIDefined => '戦略ポイントが定義されていません。';

  @override
  String get managePOIsTitle => '戦略ポイントの管理';

  @override
  String get confirmDeletePOITitle => '戦略ポイントを削除';

  @override
  String confirmDeletePOIMessage(Object poiName) {
    return 'ポイント「$poiName」を削除してもよろしいですか？';
  }

  @override
  String get mapNameRequiredSnackbar => 'マップ名を入力してください。';

  @override
  String get mapCreatedSuccessSnackbar => 'マップが作成されました！';

  @override
  String get mapUpdatedSuccessSnackbar => 'マップが更新されました！';

  @override
  String errorSavingMapSnackbar(Object error) {
    return 'マップの保存中にエラーが発生しました: $error';
  }

  @override
  String get defineBoundaryFirstSnackbar =>
      '背景をキャプチャする前に、まずフィールド境界（3点以上）を定義してください。';

  @override
  String get boundaryMinPointsError => 'フィールド境界は少なくとも3点が必要です。';

  @override
  String get zoneMinPointsError => 'ゾーンは少なくとも3点が必要です。';

  @override
  String get redefineBoundaryWarningTitle => '境界の再定義';

  @override
  String get redefineBoundaryWarningMessage =>
      'フィールド境界を再定義すると、既存のゾーンや戦略ポイントがすべて削除されます。続行しますか？';

  @override
  String get continueButton => '続行';

  @override
  String get boundariesDefinedAndBackgroundsCapturedSnackbar =>
      'フィールド境界を定義し、マップ背景をキャプチャしました。';

  @override
  String errorGeocodingSnackbar(Object error) {
    return 'ジオコーディングエラー: $error';
  }

  @override
  String get tapToDefinePositionInstruction => 'マップをタップして位置を定義してください';

  @override
  String get poiIconFlag => '旗';

  @override
  String get poiIconBomb => '爆弾';

  @override
  String get poiIconStar => '星';

  @override
  String get poiIconPlace => '場所';

  @override
  String get poiIconPinDrop => 'ピン';

  @override
  String get poiIconHouse => '家';

  @override
  String get poiIconCabin => '小屋';

  @override
  String get poiIconDoor => 'ドア';

  @override
  String get poiIconSkull => 'ドクロ';

  @override
  String get poiIconNavigation => 'ナビゲーション';

  @override
  String get poiIconTarget => 'ターゲット';

  @override
  String get poiIconAmmo => '弾薬';

  @override
  String get poiIconMedical => '医療';

  @override
  String get poiIconRadio => '無線';

  @override
  String get poiIconDefault => 'デフォルト';

  @override
  String get bombArmingInProgressTitle => '爆弾設置中';

  @override
  String get bombDisarmingInProgressTitle => '爆弾解除中';

  @override
  String get stayInZoneToContinue => '続行するにはゾーン内に留まってください';

  @override
  String get leavingZoneWillCancel => 'ゾーンを離れるとアクションがキャンセルされます';

  @override
  String bombConfigScreenTitle(Object scenarioName) {
    return '設定: $scenarioName';
  }

  @override
  String get generalInformationLabel => '一般情報';

  @override
  String get bombConfigGeneralInfoSubtitle => 'Bomb Operationシナリオの基本情報を設定します。';

  @override
  String get fieldMapLabel => 'フィールドマップ';

  @override
  String get fieldMapSubtitle => 'フィールドマップと爆弾地点を表示します。';

  @override
  String get showZonesLabel => 'ゾーンを表示';

  @override
  String get showPOIsLabel => 'POIを表示';

  @override
  String get loadingMap => 'マップを読み込み中...';

  @override
  String get gameSettingsLabel => 'ゲーム設定';

  @override
  String get bombConfigSettingsSubtitle => 'Bomb Operationシナリオのルールと設定を構成します。';

  @override
  String get bombTimerLabel => '爆弾タイマー（秒）*';

  @override
  String get valueRequiredError => '必須';

  @override
  String minSecondsError(Object value) {
    return '最小 ${value}s';
  }

  @override
  String get defuseTimeLabel => '解除時間（秒）*';

  @override
  String get armingTimeLabel => '設置時間（秒）*';

  @override
  String get armingTimeHelperText => '爆弾を設置するのに必要な時間';

  @override
  String get activeSitesPerRoundLabel => 'ラウンドごとのアクティブ地点 *';

  @override
  String get activeSitesHelperText => 'ラウンドごとにランダムにアクティブになる爆弾地点の数';

  @override
  String minCountError(Object value) {
    return '最小 $value';
  }

  @override
  String get bombSitesSectionTitle => '爆弾サイト';

  @override
  String get bombSitesSectionSubtitle => '爆弾を設置または解除できる場所を管理します。';

  @override
  String get manageBombSitesButton => '爆弾サイトを管理';

  @override
  String get saveSettingsButton => '設定を保存';

  @override
  String errorSavingScenario(Object error) {
    return 'シナリオ保存エラー: $error';
  }

  @override
  String get newBombSiteTitle => '新しい爆弾サイト';

  @override
  String get editBombSiteTitle => '爆弾サイトを編集';

  @override
  String get bombSiteNameLabel => 'サイト名 *';

  @override
  String get siteNameRequiredError => 'サイト名を入力してください';

  @override
  String get radiusMetersLabel => '半径（メートル）*';

  @override
  String get radiusHelperText => '爆弾を設置/解除できるゾーンの半径';

  @override
  String get radiusRequiredError => '半径を入力してください';

  @override
  String get invalidRadiusError => '無効な半径';

  @override
  String get siteColorLabel => 'サイトカラー:';

  @override
  String positionLabel(Object lat, Object long) {
    return '位置: $lat, $long';
  }

  @override
  String get createSiteButton => 'サイト作成';

  @override
  String get updateSiteButton => 'サイト更新';

  @override
  String get siteSavedSuccess => 'サイトが正常に保存されました';

  @override
  String errorSavingSite(Object error) {
    return 'サイト保存エラー: $error';
  }

  @override
  String bombSiteListScreenTitle(Object scenarioName) {
    return '爆弾設置場所: $scenarioName';
  }

  @override
  String errorLoadingSites(Object error) {
    return 'サイトの読み込み中にエラーが発生しました: $error';
  }

  @override
  String get addSiteButton => 'サイトを追加';

  @override
  String get noBombSitesDefined => '爆弾設置場所が定義されていません';

  @override
  String get addSitesInstruction => '爆弾を設置および解除できる場所を追加してください。';

  @override
  String siteDetailsSubtitle(Object radius, Object lat, Object long) {
    return '半径: ${radius}m • 位置: $lat, $long';
  }

  @override
  String confirmDeleteSiteMessage(Object siteName) {
    return 'サイト「$siteName」を削除してもよろしいですか？';
  }

  @override
  String get siteDeletedSuccess => 'サイトが正常に削除されました';

  @override
  String errorDeletingSite(Object error) {
    return 'サイトの削除中にエラーが発生しました: $error';
  }

  @override
  String pointsAwarded(Object points) {
    return '+$points ポイント';
  }

  @override
  String get scanQRCodeTitle => 'QRコードをスキャン';

  @override
  String get gameNotActiveError => 'ゲームがアクティブではありません';

  @override
  String scanError(Object error) {
    return 'スキャン中にエラーが発生しました: $error';
  }

  @override
  String get treasureFoundTitle => '宝物を発見！';

  @override
  String get defaultTreasureName => '宝物';

  @override
  String totalScoreLabel(Object score) {
    return '合計スコア: $score ポイント';
  }

  @override
  String qrCodesScreenTitle(Object scenarioName) {
    return 'QRコード - $scenarioName';
  }

  @override
  String get printButton => '印刷';

  @override
  String get printingNotAvailableError => 'このプラットフォームでは印刷できません';

  @override
  String get directPrintButton => '直接印刷';

  @override
  String get downloadZipButton => 'ZIPをダウンロード';

  @override
  String get shareButton => '共有';

  @override
  String qrCodesForScenarioShareText(Object scenarioName) {
    return '$scenarioNameのQRコード';
  }

  @override
  String get qrCodesDisplayInstructions => '宝探し用のQRコードを印刷、ダウンロード、または共有してください。';

  @override
  String defaultTreasureNameIndexed(Object index) {
    return '宝物 $index';
  }

  @override
  String get noQRCodesToShareError => '共有するQRコードがありません';

  @override
  String sharingError(Object error) {
    return '共有中にエラーが発生しました: $error';
  }

  @override
  String zipCreationError(Object error) {
    return 'ZIP作成中にエラーが発生しました: $error';
  }

  @override
  String scoreboardScreenTitle(Object scenarioName) {
    return 'スコア - $scenarioName';
  }

  @override
  String errorLoadingScoreboard(Object error) {
    return 'スコアボードの読み込み中にエラーが発生しました: $error';
  }

  @override
  String scoreboardHeader(Object scenarioName) {
    return 'スコアボード - $scenarioName';
  }

  @override
  String get scoresLockedLabel => 'スコアがロックされています';

  @override
  String get scoresUnlockedLabel => 'スコアがロック解除されています';

  @override
  String get unlockButton => 'ロック解除';

  @override
  String get lockButton => 'ロック';

  @override
  String get resetButton => 'リセット';

  @override
  String get resetScoresTitle => 'スコアをリセット';

  @override
  String get resetScoresConfirmationMessage =>
      'すべてのスコアをリセットしてもよろしいですか？この操作は取り消せません。';

  @override
  String get unknownTeamName => '不明なチーム';

  @override
  String treasuresFoundCount(Object count) {
    return '$count 個の宝物を発見';
  }

  @override
  String pointsSuffix(Object score) {
    return '$score 点';
  }

  @override
  String get unknownPlayerName => '不明なプレイヤー';

  @override
  String get editTreasureTitle => '宝物を編集';

  @override
  String errorUpdatingTreasure(Object error) {
    return '宝物の更新中にエラーが発生しました: $error';
  }

  @override
  String get treasureNameLabel => '宝物の名前';

  @override
  String get nameRequiredError => '名前を入力してください';

  @override
  String get valuePointsLabel => '価値（ポイント）';

  @override
  String get invalidNumberError => '有効な数字を入力してください';

  @override
  String get symbolLabel => 'シンボル';

  @override
  String get saveChangesButton => '変更を保存';

  @override
  String treasureHuntConfigTitle(Object scenarioName) {
    return '設定 - $scenarioName';
  }

  @override
  String errorLoadingTreasureHuntScenario(Object error) {
    return '宝探しシナリオの読み込みエラー: $error';
  }

  @override
  String get treasureHuntSetupTitle => '宝探しの設定';

  @override
  String get numberOfQRCodesLabel => 'QRコードの数';

  @override
  String get qrCodeCountHelperText => '1から50の間';

  @override
  String get numberRequiredError => '数字を入力してください';

  @override
  String get qrCodeCountRangeError => '数値は1から50の間である必要があります';

  @override
  String get defaultValuePointsLabel => 'デフォルト値（ポイント）';

  @override
  String get defaultSymbolLabel => 'デフォルトシンボル';

  @override
  String get generateQRCodesButton => 'QRコードを生成';

  @override
  String errorCreatingTreasures(Object error) {
    return '宝物の作成中にエラーが発生しました: $error';
  }

  @override
  String viewExistingTreasuresButton(Object count) {
    return '既存の宝物を表示 ($count)';
  }

  @override
  String treasuresScreenTitle(Object scenarioName) {
    return '宝物 - $scenarioName';
  }

  @override
  String errorLoadingTreasures(Object error) {
    return '宝物の読み込み中にエラーが発生しました: $error';
  }

  @override
  String get noTreasuresFoundForScenario => 'このシナリオに宝物が見つかりませんでした';

  @override
  String scenarioNameHeader(Object scenarioName) {
    return 'シナリオ: $scenarioName';
  }

  @override
  String numberOfTreasuresLabel(Object count) {
    return '宝物の数: $count';
  }

  @override
  String treasureValueSubtitle(Object points) {
    return '価値: $points ポイント';
  }

  @override
  String get viewQRCodesButton => 'QRコードを表示';

  @override
  String get confirmDeleteTreasureTitle => 'この宝物を削除しますか？';

  @override
  String confirmDeleteTreasureMessage(Object treasureName) {
    return '「$treasureName」を削除してもよろしいですか？';
  }

  @override
  String errorDeletingTreasure(Object error) {
    return '宝物の削除中にエラーが発生しました: $error';
  }

  @override
  String get toggleFlash => 'フラッシュ切替';

  @override
  String get switchCamera => 'カメラを切り替え';

  @override
  String get mapTab => 'マップ';

  @override
  String get scenariosTab => 'シナリオ';

  @override
  String get nonInteractiveMapTitle => 'インタラクティブではないマップ';

  @override
  String get nonInteractiveMapMessage =>
      'このマップは「爆弾作戦」シナリオに必要なインタラクティブ設定がされていません。\n\nまず、インタラクティブマップエディターでこのマップを設定するか、すでに設定済みの他のマップを選択してください。';

  @override
  String get backButton => '戻る';

  @override
  String get configureBombOperation => '爆弾作戦を設定';

  @override
  String get bombOperationDescription =>
      '2チームが対決します：\n🔴 テロリスト – 任務：指定エリアで爆弾を起動し、カウントダウンを開始する。\n🔵 対テロ部隊 – 目的：爆発前に爆弾を見つけて解除する。\n\n🎯 タイマーがゼロになると → 仮想爆発 → テロリストの勝利。\n🛡️ 爆弾が時間内に解除されると → 対テロ部隊の勝利。\n\n💣 目標：スピード、ステルス、正確さ。幸運を祈る、兵士諸君！';

  @override
  String get bombSite => 'サイト';

  @override
  String get recruitmentTitle => '募集';

  @override
  String get recruitmentSubtitle =>
      'スパムなし。義務なし。回復用のメール1つ、ゲーム参加用のユーザー名1つ。ミッション完了。';

  @override
  String get hostSectionCommandCenterTitle => '司令センター';

  @override
  String get hostSectionMapManagementTitle => 'マップ管理';

  @override
  String get hostSectionMissionScenariosTitle => 'ミッションシナリオ';

  @override
  String get hostSectionTeamsPlayersTitle => 'チーム＆プレイヤー';

  @override
  String get hostSectionGameHistoryTitle => 'ゲーム履歴';

  @override
  String get hostSectionCommandCenterDescription =>
      '本部を展開し、フィールドを開いてプレイヤーを迎え入れましょう。保存されたシナリオを準備し、正確なカウントダウンでゲームを開始し、リアルタイムの進行をコントロールしましょう。';

  @override
  String get hostSectionMapManagementDescription =>
      'ゾーンごとにプレイフィールドを作成します。マップをナビゲートし、境界を定義し、重要なエリアに名前を付け、戦略的な関心ポイントを配置します。あなたの戦場が、想像通りに形作られます。';

  @override
  String get hostSectionMissionScenariosDescription =>
      'ミッションシナリオを作成し、各重要パラメータを定義します：目標タイプ、ターゲット数、持続時間、アクティベーションゾーン...宝探しでも爆発的な作戦でも、カスタムゲームの土台を準備します。';

  @override
  String get hostSectionTeamsPlayersDescription =>
      'チームを作成し、人数を管理し、各プレイヤーに役割を割り当てます。良いバランスは、全員が自分の場所を持つミッションで、ダイナミックで楽しいゲームを保証します。';

  @override
  String get hostSectionGameHistoryDescription =>
      'ゲーム履歴を確認：スコア、統計、重要な瞬間。過去のセッションを追体験し、うまくいったこと（またはそうでなかったこと）を見つけ、さらに楽しくするために次のシナリオを調整します。';

  @override
  String get hostSectionCommandCenterSubtitle =>
      '接続されたベースキャンプ - すべてはあなたを通る、チーフ。';

  @override
  String get hostSectionMapManagementSubtitle => 'あなたの地図作成兵器庫 - 描き、名前を付け、制御する。';

  @override
  String get hostSectionMissionScenariosSubtitle => '想像力が武器 - カスタムチャレンジを作成する。';

  @override
  String get hostSectionTeamsPlayersSubtitle => '戦術的配分 - バランスの取れた激しいマッチを作成する。';

  @override
  String get hostSectionGameHistorySubtitle => 'フィールドに戻る - あなたのゲーム、あなたのデータ。';

  @override
  String get audioGameStarted => 'Game started. Good luck everyone.';

  @override
  String get audioGameEnded => 'Game ended. Thank you for playing.';
}
