# ランニングシューズ走行距離記録

ランニングシューズの走行距離を記録・管理するFlutterアプリです。シューズごとの累計走行距離を把握し、適切な買い替え時期の判断に役立ちます。

## 機能

### シューズ管理
- シューズの登録（ブランド・モデル名・購入日）
- カメラ/ギャラリーからシューズ画像を保存
- シューズ一覧表示（画像サムネイル・走行距離付き）
- シューズの削除

### 走行記録
- 日付・距離・メモを記録
- 走行履歴の編集・削除
- 累計走行距離の自動計算
- 距離に応じた色分け表示（緑→オレンジ→赤）

### リマインド通知
- 毎日指定時刻にローカルプッシュ通知で記録を促す
- 通知時刻はユーザーが設定可能（デフォルト: 21:00）
- ON/OFF切り替え対応

### データ移行
- JSON形式でエクスポート（画像はBase64エンコード）
- iOS/Android間でデータ移行可能
- 既存データへの追加 or 上書きインポート

### 広告
- Google AdMobによるバナー広告・インタースティシャル広告

## 技術スタック

- **フレームワーク**: Flutter
- **データ保存**: SharedPreferences
- **画像保存**: アプリドキュメントディレクトリ
- **広告**: google_mobile_ads
- **通知**: flutter_local_notifications + timezone
- **データ移行**: share_plus + file_picker

## セットアップ

```bash
flutter pub get
flutter run
```

### 必要環境
- Flutter SDK 3.0.0以上
- Android NDK 26.3.11579264
- AGP 8.2.2

## プロジェクト構成

```
lib/
├── main.dart                          # エントリポイント
├── models/
│   └── shoe.dart                      # Shoe / MileageEntry モデル
├── screens/
│   ├── shoe_list_screen.dart          # シューズ一覧（ホーム画面）
│   ├── shoe_detail_screen.dart        # シューズ詳細・走行履歴
│   ├── add_shoe_screen.dart           # シューズ登録
│   ├── add_mileage_screen.dart        # 走行記録の追加・編集
│   └── settings_screen.dart           # 設定（リマインド通知）
└── services/
    ├── storage_service.dart           # データ保存・画像管理
    ├── ad_service.dart                # Google AdMob管理
    ├── notification_service.dart      # ローカル通知管理
    ├── data_migration_service.dart    # エクスポート・インポート
    └── shoe_model_service.dart        # シューズモデル候補取得
```
