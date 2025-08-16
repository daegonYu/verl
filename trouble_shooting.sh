python - <<'PY'
import torch, platform
print("torch:", torch.__version__, "| CUDA:", torch.version.cuda)
print("PY:", platform.python_version())
try:
    print("cxx11 ABI:", torch._C._GLIBCXX_USE_CXX11_ABI)
except Exception as e:
    print("cxx11 ABI: <unknown>", e)
PY
python -c "import flash_attn; print('flash-attn:', getattr(flash_attn, '__version__', 'unknown'))"

# 0) 기존 flash-attn 제거
pip uninstall -y flash-attn || true

# 1) 빌드 도구
apt-get update && apt-get install -y ninja-build git && pip install -U pip setuptools wheel

# 2) CUDA 경로/아키텍처 설정 (GPU에 맞게 택1)
export CUDA_HOME=/usr/local/cuda-12.8
# H100이면
export TORCH_CUDA_ARCH_LIST="90"
# A100이면
# export TORCH_CUDA_ARCH_LIST="80"
# RTX 4090/ADA면
# export TORCH_CUDA_ARCH_LIST="89"

# (선택) cxx11 ABI 강제 플래그 — 보통은 torch 설정을 따라가서 불필요하지만,
# 환경에 따라 빌드 스크립트가 헷갈릴 수 있어 다음을 추가로 줘도 됩니다.
export CXXFLAGS="$CXXFLAGS -D_GLIBCXX_USE_CXX11_ABI=1"

# 3) pip로 소스 빌드 (빌드 격리 끄고, 캐시 끄기)
pip install --no-build-isolation --no-cache-dir "flash-attn==2.8.3"

# 4) 확인
python - <<'PY'
try:
    import torch, flash_attn
    print("torch:", torch.__version__)
    print("flash-attn:", getattr(flash_attn, "__version__", "unknown"))
    from flash_attn.flash_attn_interface import flash_attn_func
    print("flash-attn import OK")
except Exception as e:
    import traceback; traceback.print_exc()
PY

