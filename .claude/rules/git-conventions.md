---
description: Gitブランチ命名規則・コミット・PR作成規約
---

# Git Conventions

## ブランチ命名規則

ブランチ名は以下のプレフィックスを使用すること。

| プレフィックス | 用途 |
|---|---|
| `feat/` | 新機能追加 |
| `fix/` | バグ修正 |
| `chore/` | ビルド・設定・ドキュメントなど機能に影響しない変更 |
| `refactor/` | リファクタリング |

`feature/` は使用しない。

## コミットメッセージ規約

- `Co-Authored-By:` トレーラーは付けない。

## PR作成規約

- 本文のセクション見出しは日本語にする（例: `## 概要`、`## テスト手順`）。
- `🤖 Generated with [Claude Code](https://claude.com/claude-code)` などのAI生成フッターは付けない。
- **base branch は必ず `main` を指定すること。** GitHubは直前に操作していたブランチをデフォルトにすることがあるため、`gh pr create` では `--base main` を明示する。
- **assignee は必ず自分を指定すること。** `gh pr create` では `--assignee @me` を付ける。
