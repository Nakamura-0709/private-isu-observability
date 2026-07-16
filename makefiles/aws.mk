################################################################################
# 認証
################################################################################
.PHONY: aws.login
aws.login: ## AWS SSOでログイン
	@aws sso login --profile $(AWS_PROFILE)

################################################################################
# 一覧
################################################################################
.PHONY: aws.status
aws.status: ## AWSのインスタンス状態とCFnスタック一覧
	@aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --query 'StackSummaries[].{Name:StackName,Created:CreationTime}' --output table
	@aws ec2 describe-instances --filters 'Name=tag:Name,Values=web,bench' --query 'Reservations[].Instances[].{Name:Tags[?Key==`Name`]|[0].Value,State:State.Name,PublicIp:PublicIpAddress,InstanceId:InstanceId}' --output table

################################################################################
# CFnスタック作成
################################################################################
.PHONY: aws.create-cfn
aws.create-cfn: validate-ssh-private-key ## AWSのCFnスタックを作成
	$(eval MY_IP := $(shell curl -fsS https://checkip.amazonaws.com))
	@aws cloudformation create-stack --stack-name $(STACK_NAME) --template-body file://private-isu.yaml --parameters \
	    ParameterKey=GitHubUsername,ParameterValue="${GITHUB_USERNAME}" \
	    ParameterKey=MyIp,ParameterValue=$(MY_IP)
	@echo "$(STACK_NAME): 作成中です(約1分かかります)"
	@time aws cloudformation wait stack-create-complete --stack-name $(STACK_NAME)

################################################################################
# SSHの設定
################################################################################
.PHONY: aws.setup-ssh-config
aws.setup-ssh-config: validate-ssh-private-key ## SSH設定をセットアップ
	$(eval STACK_ID := $(shell aws cloudformation describe-stacks --stack-name $(STACK_NAME) --query 'Stacks[0].StackId' --output text))
	$(eval WEB_HOST_IP := $(shell aws ec2 describe-instances \
	    --filters "Name=tag:aws:cloudformation:stack-id,Values=$(STACK_ID)" "Name=tag:Name,Values=web" \
	    --query 'Reservations[0].Instances[0].PublicIpAddress' --output text))
	$(eval BENCH_HOST_IP := $(shell aws ec2 describe-instances \
	    --filters "Name=tag:aws:cloudformation:stack-id,Values=$(STACK_ID)" "Name=tag:Name,Values=bench" \
	    --query 'Reservations[0].Instances[0].PublicIpAddress' --output text))
	@mkdir -p "$(shell dirname "${SSH_CONFIG_FILE}")"
	@sed \
	    -e "s|{{SSH_PRIVATE_KEY_PATH}}|${SSH_PRIVATE_KEY_PATH}|g" \
	    -e "s|{{WEB_HOST_IP}}|$(WEB_HOST_IP)|g" \
	    -e "s|{{BENCH_HOST_IP}}|$(BENCH_HOST_IP)|g" \
	    .ssh/ssh_config.tmpl > "${SSH_CONFIG_FILE}"
	@ssh -F "${SSH_CONFIG_FILE}" web 'echo "ssh web: OK"' || echo 'ssh web: SSH NG'
	@ssh -F "${SSH_CONFIG_FILE}" bench 'echo "ssh bench: OK"' || echo 'ssh bench: SSH NG'

# SSH鍵の検証（1Passwordエージェント対応版）
# 書籍では ssh-keygen -y -f ${SSH_PRIVATE_KEY_PATH} を使用しているが、
# 1Passwordエージェント利用時は秘密鍵ファイルが存在しないため ssh-add -L に変更
validate-ssh-private-key:
	@test -n "$${GITHUB_USERNAME:-}" || { \
	    echo '----[ERROR]----' >&2; \
	    echo 'GITHUB_USERNAMEが設定されていません' >&2; \
	    echo '.envrc.overrideにGITHUB_USERNAMEを設定してdirenv allowを実施してください' >&2; \
	    exit 1; \
	}
	$(eval PUBLIC_KEYS := $(shell ssh-add -L | cut -d ' ' -f1,2))
	@echo "$(PUBLIC_KEYS)" | tr ' ' '\n' | paste - - | while read key; do \
	    curl -fsS "https://github.com/${GITHUB_USERNAME}.keys" | grep -qF "$$key" && exit 0; \
	done; \
	echo '----[ERROR]----' >&2; \
	echo "1PasswordエージェントのSSH鍵がhttps://github.com/${GITHUB_USERNAME}.keysにありません" >&2; \
	exit 1
