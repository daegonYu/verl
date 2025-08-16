
# ① .env 로드 → ② HF/W&B 로그인(비대화형)
set -a && source /workspace/verl/.env && set +a \
&& { command -v huggingface-cli >/dev/null || pip install -U "huggingface_hub[cli]"; } \
&& echo "$HF_TOKEN" | huggingface-cli login --token "$HF_TOKEN" \
&& echo "$WANDB_API_KEY" | wandb login 