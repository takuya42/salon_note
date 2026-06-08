# Web予約プッシュ通知 監査レポート

## 結論

コード上で確認できた主な問題は次の2点です。

1. iOSではAPNsトークンが発行される前にFCMトークンを取得すると失敗します。従来実装は権限要求直後に `getToken()` を一度呼ぶため、`apns-token-not-set` 相当の競合が起きた場合にFirestoreへ有効な実機トークンを保存できない可能性がありました。
2. Cloud Functionsは一部または全件失敗でも常に `Sent web reservation notification` を出していました。`failureCount` は「関数の失敗」ではなく、マルチキャスト対象トークンごとのFCM受付失敗数です。

今回、APNsトークンを確認してからFCMトークンを取得し、権限状態・APNs/FCMトークン末尾・トークン更新エラーを診断ログへ出すようにしました。Functions側は失敗レスポンスをトークンの配列位置と対応付け、トークン全体を漏らさずエラーコードを出し、失敗がある場合は成功ログを出さないようにしました。

ただし、リポジトリだけではFirebase Consoleに登録されたAPNsキーの Key ID / Team ID / 対象Firebase iOSアプリ、Apple DeveloperのApp IDとプロビジョニングプロファイル、実機の通知設定は検証できません。最終原因は修正後の `FCM delivery failed` の `code` と実機ログで確定してください。

## 項目別確認

### 1. FCM送信処理

- `sendEachForMulticast` に渡す `notification`、`data`、Android channelは妥当です。
- APNs可視通知として `apns-push-type: alert` と `apns-priority: 10` を明示しました。
- `response.responses` は入力した `tokens` と同じ順序なので、インデックスによる対応付けは正しいです。
- `successCount` はFCMが送信要求を受け付けた件数で、端末への表示完了を保証する値ではありません。

### 2. `response.responses` のエラーログ

従来のインデックス対応は正しかったものの、以下が問題でした。

- FCMトークン全体をログに出していた。
- `failureCount > 0` でも最後に成功を示すメッセージを出していた。
- 集計ログから対象トークン数が分からなかった。

修正後は、失敗ごとに `index`、`tokenSuffix`、`code`、`message` を記録し、集計に `tokenCount`、`successCount`、`failureCount` を記録します。

### 3. APNs / Xcode設定

リポジトリ内で確認できる項目は次のとおりです。

- `Runner.entitlements` に `aps-environment=development` があります。
- 全Runnerビルド構成で `CODE_SIGN_ENTITLEMENTS=Runner/Runner.entitlements` が指定されています。
- `Info.plist` に `UIBackgroundModes` の `remote-notification` があります。
- Bundle IDはXcode設定と `GoogleService-Info.plist` の双方で `com.kono.salonnote` です。
- `GoogleService-Info.plist` はRunnerのResourcesへ追加されています。

実機配布ビルドでは、署名後アプリの `aps-environment` が `production` になっていることを確認してください。ソースの値だけでなく、Archiveの署名済みentitlementsと配布用プロビジョニングプロファイルを確認する必要があります。

Firebase Consoleでは、プロジェクト `salon-note` のiOSアプリ `com.kono.salonnote` に対してAPNs認証キーが登録され、Key IDとApple Team IDが正しいことを確認してください。`messaging/third-party-auth-error` の場合は、このAPNsキー（失効、別Team、未登録）が第一候補です。

### 4. Flutter `FirebaseMessaging` 初期化

`main.dart` はWidgets binding、Firebase初期化、通知サービス初期化の順で待機しており、基本順序は正しいです。バックグラウンドハンドラーもトップレベル関数かつentry-point指定済みです。

修正後は次も保証します。

- FCM auto-initを明示的に有効化。
- 通知権限の結果をログ出力。
- AppleプラットフォームではAPNsトークンを最大10秒待ってからFCM `getToken()` を実行。
- FCMトークン更新ストリームのエラーをログ出力。
- ローカル通知プラグインから重複して権限ダイアログを要求せず、Firebase Messagingへ権限要求を一本化。

### 5. 通知権限

`PushNotificationService.initialize()` は `main.dart` から非Web環境で呼ばれ、その中で `requestPermission(alert: true, badge: true, sound: true)` が呼ばれます。権限要求自体は実装済みです。

実機ではログの `Notification permission status` が `authorized` または `provisional` であることを確認してください。`denied` の場合、再度APIを呼んでもシステムダイアログは通常再表示されないため、iOSの「設定 > 通知 > Salon Note」で許可するか、アプリを削除して再インストールして検証します。

### 6. iOS実機で必要な確認

1. Apple DeveloperのIdentifier `com.kono.salonnote` でPush Notifications capabilityが有効。
2. 実機を署名するDevelopmentプロファイルに `aps-environment=development` が含まれる。
3. TestFlight/App Store用プロファイルに `aps-environment=production` が含まれる。
4. Firebase ConsoleのAPNsキーが同じApple Teamに属し、失効していない。
5. 実機で通知を許可し、集中モード・通知要約・アプリ個別通知設定を確認。
6. 起動ログにAPNsトークンとFCMトークンの登録ログが出る。
7. 実機で生成された最新FCMトークンが、ログイン中ownerの `users/{uid}` に保存される。
8. `shops/{shopId}.ownerId` がその同じuidを指す。
9. アプリをバックグラウンドにしてFirebase Consoleから最新FCMトークンへテスト送信する。
10. その後にWeb予約を作成し、Functionsのトークン別エラーコードを確認する。

### 7. AppDelegate / APNs Token登録

`Info.plist` に `FirebaseAppDelegateProxyEnabled=false` はなく、Firebase MessagingのAppDelegate swizzlingは無効化されていません。この構成ではFirebase MessagingプラグインがAPNs登録とAPNsトークンからFCMトークンへの関連付けを処理するため、AppDelegateへ手動の `Messaging.messaging().apnsToken = deviceToken` を追加する必要はありません。

手動処理を追加するのはswizzlingを明示的に無効化する場合だけです。現在のAppDelegateは `GeneratedPluginRegistrant` と `super.application(...)` を呼んでおり、プラグイン連携を阻害するコードは見当たりません。

### 8. `failureCount` の原因判定

`failureCount` が増える直接原因は、`response.responses` 内の `success=false` です。修正後ログの `code` により次のように判定します。

- `messaging/registration-token-not-registered`: アプリ削除、再インストール、トークン更新などで古くなったトークン。コードは該当トークンをFirestore配列から削除します。
- `messaging/invalid-registration-token`: 壊れた、切り詰めた、またはFCMトークンではない値。コードは該当トークンを削除します。
- `messaging/third-party-auth-error`: APNs認証キー/証明書が未登録、無効、失効、Team不一致。
- `messaging/sender-id-mismatch`: 保存トークンを発行したFirebaseプロジェクトとFunctionsのプロジェクトが異なる。アプリを再インストールし、`GoogleService-Info.plist` とデプロイ先を確認します。
- `messaging/mismatched-credential`: Admin SDKのプロジェクトと対象トークンのプロジェクトが不一致。
- `messaging/invalid-argument`: トークン形式、Bundle ID、payload等を確認します。
- `messaging/server-unavailable` / `messaging/internal-error`: 一時障害。指数バックオフ付き再試行の対象です。

`fcmToken` と `fcmTokens` の両方に同じ値がある場合はSetで重複排除されるため、それ自体はfailureCountの原因ではありません。一方、`fcmTokens` に過去端末やシミュレータの古いトークンが残っていれば、最新実機への1件が成功しても古い1件のために `failureCount=1` になります。

## 最有力の原因

現状情報からの優先順位は以下です。

1. `fcmTokens` に残った古いシミュレータ/再インストール前トークンが失敗し、`failureCount` が発生している。
2. 権限要求直後にAPNsトークン未確立のままFCMトークン取得を試み、実機で使うべき最新トークンが保存されていない。
3. Firebase ConsoleのAPNs認証キーのTeam ID、Key ID、対象プロジェクト、またはキー有効性に問題があり `third-party-auth-error` になっている。
4. 保存トークンが別Firebaseプロジェクト/別Bundle ID由来である。

シミュレータで届かない事実だけではAPNs設定不良を確定できません。Xcode/Simulatorのバージョン、ホスト環境、sandbox APNs登録、シミュレータで発行された最新トークンかどうかの影響を受けるため、最終確認は署名済みiOS実機で行ってください。
