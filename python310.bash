pip install torch==2.4.0 torchvision==0.19.0 torchaudio==2.4.0 \
  --index-url https://download.pytorch.org/whl/cu121
pip install vllm==0.6.3
pip install ray
pip install flash-attn --no-build-isolation
pip install -e .
pip install -v --disable-pip-version-check --no-cache-dir --no-build-isolation \
  --config-settings "--build-option=--cpp_ext" \
  --config-settings "--build-option=--cuda_ext" \
  git+https://github.com/NVIDIA/apex

pip install git+https://github.com/NVIDIA/TransformerEngine.git@v1.7

cd ..
git clone -b core_v0.4.0 https://github.com/NVIDIA/Megatron-LM.git
cp verl/patches/megatron_v4.patch Megatron-LM/
cd Megatron-LM && git apply megatron_v4.patch
pip install -e .
export PYTHONPATH=$PYTHONPATH:$(pwd)
