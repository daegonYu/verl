set -x

export HYDRA_FULL_ERROR=1
export VLLM_USE_V1=1
export TOKENIZERS_PARALLELISM=false

gsm8k_train_path=/workspace/verl/data/my_data/train.parquet
gsm8k_test_path=/workspace/verl/data/my_data/test.parquet
model_path=trillionlabs/Tri-7B

train_files="['$gsm8k_train_path']"
test_files="['$gsm8k_test_path']"

python3 -m verl.trainer.main_ppo \
    custom_reward_function.path="verl/utils/reward_score/my_reward.py" \
    custom_reward_function.name="compute_score" \
    algorithm.adv_estimator=grpo \
    data.train_files="$train_files" \
    data.val_files="$test_files" \
    data.train_batch_size=2 \
    data.max_prompt_length=800 \
    data.max_response_length=700 \
    data.filter_overlong_prompts=True \
    data.truncation='error' \
    actor_rollout_ref.model.path=$model_path \
    actor_rollout_ref.model.use_remove_padding=True \
    actor_rollout_ref.model.enable_gradient_checkpointing=True \
    actor_rollout_ref.actor.optim.lr=1e-6 \
    actor_rollout_ref.actor.ppo_mini_batch_size=2 \
    actor_rollout_ref.actor.ppo_micro_batch_size_per_gpu=1 \
    actor_rollout_ref.actor.use_kl_loss=False \
    actor_rollout_ref.actor.kl_loss_coef=0.0 \
    algorithm.use_kl_in_reward=False \
    actor_rollout_ref.actor.entropy_coeff=0.001 \
    actor_rollout_ref.rollout.name=vllm \
    actor_rollout_ref.rollout.tensor_model_parallel_size=2 \
    actor_rollout_ref.rollout.log_prob_micro_batch_size_per_gpu=1 \
    actor_rollout_ref.rollout.gpu_memory_utilization=0.8 \
    actor_rollout_ref.rollout.n=8 \
    actor_rollout_ref.ref.log_prob_micro_batch_size_per_gpu=1 \
    trainer.n_gpus_per_node=2 \
    trainer.nnodes=1 \
    trainer.critic_warmup=0 \
    trainer.val_before_train=True \
    trainer.logger='["wandb"]' \
    trainer.project_name='moducorpus_korea_culture' \
    trainer.experiment_name='Tri-7B-v1' \
    trainer.save_freq=-1 \
    trainer.test_freq=100 \
    trainer.total_epochs=15 "$@"
