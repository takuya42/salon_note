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

## Web予約のPush通知（FCM）

Web予約が作成されると、`asia-northeast2` のCloud Functionsが店舗の`ownerId`を参照し、
`users/{uid}`に保存されたFCMトークンへ通知を送信します。アプリは単一端末用の
`fcmToken`と複数端末用の`fcmTokens`を保存し、通知タップ時に予約一覧を開きます。

### Firebase設定

1. Firebase ConsoleでCloud Messagingを有効にします。
2. iOSアプリではApple DeveloperとXcodeでPush Notifications capabilityを有効にし、
   Firebase ConsoleへAPNs認証キーを登録します。
3. Android 13以降ではアプリ内の通知権限要求を許可します。
4. FunctionsとFirestore Rulesをデプロイします。

```bash
cd functions
npm install
npm test
npm run lint
cd ..
npx -y firebase-tools@latest deploy --only functions:notifyOwnerOfWebReservation,firestore:rules
```

iOSのAPNs通知はシミュレータではなく実機で確認してください。リリース署名時には、
署名済みアプリの`aps-environment`が`production`になっていることも確認してください。
