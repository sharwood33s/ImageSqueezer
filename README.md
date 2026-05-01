<img width="1012" height="764" alt="EE9F37DB-7767-49BE-9A60-99057E45E11F" src="https://github.com/user-attachments/assets/b6d1b9b0-10ea-4e6e-a45c-2a3337c4a089" />
# ImageSqueezer
アイコン画像やネット上にアップロードする時に画像が高画質すぎてアップロードできない経験があり作成しました。
Web上で無料でリサイズできるサイトもありますが、なるべく自分の環境で動作させたいのでアプリを作成しました。
macOS で動く画像リサイズ・圧縮アプリです。画像をドラッグ＆ドロップして、最大幅・高さ、形式、品質、保存先を指定して一括書き出しできます。

## 起動

開発実行:

```sh
swift run ImageSqueezer
```

Finder から開ける `.app` を作る場合:

```sh
./scripts/build_app.sh
open dist/ImageSqueezer.app
```

## 機能

- JPEG、PNG、HEIC、TIFF、WebP の読み込み
- JPEG、PNG、HEIC への書き出し
- 最大幅・最大高さによるリサイズ
- サムネイル、ブログ、SNS 正方形、フルHD、4K の縮小プリセット
- 縦横比維持の切り替え
- JPEG/HEIC 品質の調整
- 複数画像の一括処理
- ドラッグ＆ドロップとファイル選択

## アイコン

元画像は `Assets/AppIcon.png`、macOS 用アイコンは `Assets/AppIcon.icns` です。
`./scripts/build_app.sh` 実行時に `.icns` が再生成され、`dist/ImageSqueezer.app` に同梱されます。

## ライセンス

このプロジェクトは MIT ライセンスの下で公開されています。詳細は [LICENSE](LICENSE) ファイルを参照してください。

AppIcon.png はフリー素材を使用しています。著作権は作者に帰属します。
