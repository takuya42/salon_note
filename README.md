# SalonNote

小規模サロン向け  
予約・売上管理アプリ

---

## コンセプト

　経営サロンのための  
「シンプルで見やすい経営ダッシュボード」

ネイル・ヘッドスパ・ボディサロン・エステなど  
予約制サロンに対応予定。

---

##  主な機能（開発中）

- 今日の売上表示
- 今日の予約件数表示
- ダッシュボードUI
- 予約データ管理（予定）
- 売上自動計算（予定）
---

## 🛠 技術スタック

- Flutter
- Dart
- Firebase（予定）
- Git / GitHub

---

## 今後実装予定

- 予約登録機能
- 顧客管理機能
- 月別売上グラフ
- サブスクリプション機能（広告なしプラン）

---

## Web予約メールアドレス・アプリ通知（FCM）の設定

Web予約では、お名前・電話番号・**メールアドレス（必須）**・メニュー・予約日時を入力します。予約は `shops/{shopId}/reservations/{reservationId}` に保存され、メールアドレスは `customerEmail` に格納されます。既存の予約ドキュメントに `customerEmail` がない場合もアプリ側の読み込みは継続できますが、新規Web予約では必須です。

予約作成後は Cloud Functions（第2世代）が店舗の `ownerId` を参照し、`users/{ownerId}` に保存された端末トークンへ FCM 通知を送ります。通知をタップすると予約一覧画面が開きます。

### 1. Firebaseプロジェクトの準備

1. Firebase Consoleで **Cloud Firestore**、**Authentication**、**Cloud Messaging** を有効にします。
2. Cloud Functionsをデプロイできるよう、Firebaseプロジェクトを Blaze プランに設定します。
3. リポジトリルートで対象プロジェクトを確認します。

```bash
npx -y firebase-tools@latest login
npx -y firebase-tools@latest use salon-note
```

### 2. Flutter依存関係

```bash
flutter pub get
```

アプリはログイン済みユーザーのFCMトークンを次のフィールドへ保存します。

- `users/{uid}.fcmToken`: 現在端末のトークン（単一端末互換）
- `users/{uid}.fcmTokens`: 複数端末用のトークン配列
- `users/{uid}.fcmTokenUpdatedAt`: 最終更新日時

無効になったトークンは、Functionsで送信エラーを検出した際に削除されます。

### 3. Android設定

1. Firebase ConsoleのAndroidアプリに、このプロジェクトのApplication IDを登録します。
2. 最新の `google-services.json` を `android/app/google-services.json` に配置します。
3. Android 13以降では初回起動時に通知権限が要求されます。`POST_NOTIFICATIONS` 権限はManifestへ設定済みです。
4. 通知チャンネルIDは `reservations`、表示名は「予約通知」です。

### 4. iOS設定（必須）

1. Apple DeveloperでApp IDの **Push Notifications** capabilityを有効にします。
2. Xcodeで `ios/Runner.xcworkspace` を開き、Runnerターゲットの **Signing & Capabilities** に次を追加します。
   - Push Notifications
   - Background Modes → Remote notifications
3. Firebase Console → プロジェクト設定 → Cloud Messaging → Appleアプリ設定で、APNs認証キー（`.p8`、Key ID、Team ID）を登録します。
4. 最新の `GoogleService-Info.plist` を `ios/Runner/GoogleService-Info.plist` に配置します。
5. Development/Ad Hoc/App Storeそれぞれ、Push Notificationsを含む正しいProvisioning Profileで署名します。実機で通知許可を承認して確認してください（iOS Simulatorでは本番相当のAPNs確認はできません）。

`Runner.entitlements` の `aps-environment` と `Info.plist` の `remote-notification` Background Modeは設定済みです。App Store配布時は、署名後のentitlementsが `production` になっていることをArchiveで確認してください。

### 5. Functionsのインストール・テスト・デプロイ

```bash
cd functions
npm install
npm test
npm run lint
cd ..
npx -y firebase-tools@latest deploy --only functions:notifyOwnerOfWebReservation
```

Functionsは `asia-northeast2` で動作し、`source == "web"` の予約だけを通知します。通知内容は次の3行です（日時は日本時間）。

```text
山田太郎
2026/06/10 10:00
カット
```

### 6. Firestore Rulesのデプロイ

```bash
npx -y firebase-tools@latest deploy --only firestore:rules
```

Rulesでは、新規予約の `customerEmail` が必須かつstring型であることを検証します。既存予約は書き換えないため、`customerEmail` が存在しない既存ドキュメントとの互換性は維持されます。

### 7. 動作確認

1. iOS/Android実機で店舗オーナーとしてログインし、通知を許可します。
2. Firestoreの `users/{uid}` に `fcmToken` / `fcmTokens` が保存されたことを確認します。
3. 公開中店舗のWeb予約画面から、メールアドレスを含めて予約します。
4. `shops/{shopId}/reservations/{reservationId}` に `customerEmail` が保存されたことを確認します。
5. オーナー端末に「新しい予約が入りました」が届くことを確認します。
6. 通知をタップし、SalonNoteの予約一覧画面へ遷移することを確認します。
