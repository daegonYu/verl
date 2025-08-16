python - <<'PY'
import torch, platform
print("torch:", torch.__version__, "| cuda:", torch.version.cuda, "| py:", platform.python_version())
try:
    import flash_attn
    print("flash-attn:", getattr(flash_attn, "__version__", "unknown"))
except Exception as e:
    print("flash-attn import error:", e)
PY

# veRL 설치
pip install --no-deps -e .

