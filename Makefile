# ============================================================
# 宝子 — 项目 Makefile
# ============================================================

.PHONY: help dev-mobile dev-backend build-mobile build-backend split-fonts clean

help: ## 显示帮助
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'

# ── Flutter 移动端 ──
dev-mobile: ## 启动 Flutter 开发 (iOS 模拟器)
	cd mobile && flutter run

dev-android: ## 启动 Flutter 开发 (Android 模拟器)
	cd mobile && flutter run -d android

build-mobile-ios: ## 构建 iOS
	cd mobile && flutter build ios --release

build-mobile-apk: ## 构建 Android APK
	cd mobile && flutter build apk --release

# ── Go 后端 ──
dev-backend: ## 启动 Go 后端 (热重载需自行安装 air)
	cd backend && go run ./cmd/server

build-backend: ## 编译 Go 后端
	cd backend && go build -o bin/server ./cmd/server

# ── 一体化 ──
dev: ## 本地 docker-compose 启动全部服务
	docker compose up -d

dev-down: ## 停止全部服务
	docker compose down

# ── 字体 ──
split-fonts: ## 重新分包中文字体（需 Python3 + fonttools）
	python3 split-fonts.py

# ── 清理 ──
clean: ## 清理构建产物
	cd mobile && flutter clean
	rm -rf backend/bin
