# private-isu-observability

private-isuを題材にオブザーバビリティ基盤の構築とパフォーマンスチューニングを行うハンズオンリポジトリです。

## 参考書籍

**実践オブザーバビリティ&パフォーマンスチューニング**  
OpenTelemetry × ClickHouse × Grafanaで計測基盤をゼロから作る  
著者: 天体可観測

## セットアップ

### 1. `.envrc` の作成

`.envrc.sample` をコピーして `.envrc` を作成します。

```bash
cp .envrc.sample .envrc
direnv allow
```

### 2. `.envrc.override` の作成（個人設定）

個人設定は `.envrc.override` に記載します（`.gitignore` で除外済み）。

```bash
cat <<'EOF' > .envrc.override
#
# awsコマンド用（default以外のprofileを使う場合）
#
# export AWS_PROFILE=your-profile

#
# GitHubユーザー名（EC2への公開鍵配布に使用）
#
export GITHUB_USERNAME=your-github-username

#
# 1Password SSHエージェントを使う場合
#
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF
direnv allow
```

> **1Password SSHエージェントを使わない場合**  
> `SSH_AUTH_SOCK` の設定は不要です。`SSH_PRIVATE_KEY_PATH` が `.envrc` に設定されているため、通常のSSH鍵ファイルで接続できます。

### 3. SSH公開鍵の登録確認

ローカルのSSH鍵がGitHubに登録されているか確認します。

```bash
ssh-add -L | cut -d ' ' -f1,2 > /tmp/local_pub.key
curl -s https://github.com/${GITHUB_USERNAME}.keys | grep -f /tmp/local_pub.key
```

一致する公開鍵が表示されれば確認完了です。
