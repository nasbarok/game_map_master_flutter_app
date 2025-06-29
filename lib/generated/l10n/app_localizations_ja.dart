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
}
