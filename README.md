# Subscription Manager

個人利用向けのサブスクリプション管理アプリの雛形です。添付の要件定義書をもとに、iPhone / Mac 両対応のSwiftUIアプリとして構成しています。

## 初期版の範囲

- サブスクの手動登録、編集、削除
- 一覧、詳細、ホーム、設定画面
- 支払い日、解約期限日の管理
- 今月の支払い予定額、月額換算、年額換算の集計
- カテゴリ別の月額 / 年額換算集計
- 支払い日 / 解約期限日の1日前通知
- 通知許可がない場合の設定画面での誘導
- 端末内JSON保存
- 保存前の入力バリデーション
- 永続化エラーのユーザー表示

初期版では iCloud同期、外部サービス連携、複数ユーザー管理、CSV出力、グラフ表示は対象外です。

## 構成

```text
SubscriptionManagerApp/
├─ SubscriptionManagerApp.swift
├─ Models/
│  ├─ AppRoute.swift
│  ├─ CategorySpending.swift
│  ├─ Subscription.swift
│  ├─ SubscriptionSummary.swift
│  └─ SubscriptionValidation.swift
├─ Stores/
│  └─ SubscriptionStore.swift
├─ Services/
│  └─ NotificationScheduler.swift
└─ Views/
   ├─ Formatters.swift
   ├─ HomeView.swift
   ├─ RootView.swift
   ├─ SettingsView.swift
   ├─ SubscriptionDetailView.swift
   ├─ SubscriptionFormView.swift
   ├─ SubscriptionListView.swift
   └─ SubscriptionRow.swift

Tests/
└─ SubscriptionManagerAppTests/
   ├─ NotificationSchedulerTests.swift
   ├─ SubscriptionSummaryTests.swift
   └─ SubscriptionValidationTests.swift
```

## 実装方針

- UIはSwiftUIで実装
- iPhoneは `TabView` による3タブ構成
- Macは `NavigationSplitView` によるサイドバー構成
- 状態管理は `Observation` の `@Observable` を使用
- ローカル保存はApplication Support配下の `subscriptions.json`
- 通知は `UserNotifications` で1日前の午前9時に予約
- 通知予約は `NotificationPlan` に分離し、単体テスト可能な形にする
- 支払い周期は `monthsPerCycle` を持たせ、将来の周期追加に備える
- 永続化エラーは `SubscriptionStore.persistenceErrorMessage` で管理し、ルート画面のアラートで表示する

## 検証

```bash
swift test --disable-sandbox
```

現在の環境ではSwiftPMのユーザーキャッシュ権限警告が出ますが、テストは成功します。

## 完了した次候補

1. SwiftPMターゲットとして `SubscriptionManagerApp` と `SubscriptionManagerAppTests` を定義
2. 通知予約プランの単体テストを追加
3. 入力バリデーションを強化
4. 支払い周期追加とカテゴリ別集計に備えてモデルを拡張
5. カテゴリ別集計をホーム画面に表示
6. 通知許可がない場合の画面誘導を追加
7. 永続化エラーをユーザーへ表示

## 次に実装する候補

1. XcodeのMultiplatform Appプロジェクトとして `.xcodeproj` を作成する
2. カテゴリ別集計の詳細画面を追加する
3. 通知予約済み件数を設定画面に表示する
4. データのエクスポート / インポートを追加する
