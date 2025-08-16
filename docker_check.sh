# 태그 "이름"만 넣으세요 (레포지토리 접두사 X)
TAG=base-verl0.5-cu126-cudnn9.8-torch2.7.1-fa2.7.4

curl -s 'https://hub.docker.com/v2/repositories/verlai/verl/tags/?page_size=500' \
| grep -o '"name":"[^"]*"' | cut -d: -f2 | tr -d '"' \
| grep -x "$TAG" && echo "FOUND: $TAG" || echo "NOT FOUND: $TAG"
