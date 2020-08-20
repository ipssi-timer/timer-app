#!make
include .env

SHELL = /bin/bash


.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' 'Makefile' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

# -------------------------
# Une affaire de Docker

.PHONY: pull
pull: ## Extrait toutes les images Docker utilisées dans docker-compose.yml
	@echo "Extraction des images Docker..."
	@docker-compose pull

.PHONY: serve
serve: ## Met en service l'ensemble de l'application
	@echo "Lancement des images Docker..."
	@docker-compose up -d
	@echo "L'application est dorénavant accessible à l'adresse http://localhost !"

.PHONY: down
down: ## Stoppe l'application et supprime tous les containers, réseaux et volumes partagés
	@echo "Arrêt des images Docker..."
	@docker-compose down -v
	@echo "Arrêt de l'application !"

.PHONY: build
build: ## Extrait toutes les images Docker utilisées dans docker-compose.yml et les construit
	@echo "Construction des images Docker (avec extraction)..."
	@docker-compose build --pull
	@echo "Images Docker construites !"

# -------------------------
# Une affaire de Git

.PHONY: clone
clone: clone-timer-back clone-timer-ui ## Clone les répertoires git du projet

.PHONY: clone-timer-back
clone-timer-back: ## Clone le répertoire git `timer-back`
	@echo "Clonage du répertoire 'timer-back'..."
	@if [ -d "timer-back" ]; then \
		echo "Répertoire 'timer-back déjà existant !"; \
		make clean-timer-back; \
		git clone https://${GIT_USER}:${GIT_PASSWORD}@github.com/ipssi-timer/timer-back.git timer-back; \
	fi; \

.PHONY: clone-timer-ui
clone-timer-ui: ## Clone le répertoire git `timer-ui`
	@echo "Clonage du répertoire 'timer-ui'..."
	@if [ -d "timer-ui" ]; then \
		echo "Répertoire 'timer-ui' déjà existant !"; \
		make clean-timer-ui; \
		git clone https://${GIT_USER}:${GIT_PASSWORD}@github.com/ipssi-timer/timer-front.git timer-ui; \
	fi; \

# -------------------------
# Une affaire de répertoire

.PHONY: clean
clean: clean-timer-back clean-timer-ui ## Supprime les répertoires `timer-back` et `timer-ui` du projet

.PHONY: clean-timer-back
clean-timer-back: ## Supprime le répertoire `timer-back`
	@echo "Suppression du répertoire 'timer-back'..."
	@rm -rf timer-back
	@echo "Répertoire 'timer-back' supprimé !"

.PHONY: clean-timer-ui
clean-timer-ui: ## Supprime le répertoire `timer-ui`
	@echo "Suppression du répertoire 'timer-ui'..."
	@rm -rf timer-ui
	@echo "Répertoire 'timer-ui' supprimé !"

# -------------------------
# Une affaire de projet

.PHONY: run
run: ## Construit l'ensemble du projet (Au clone jusqu'à la mise en service)
	@echo "Clonage des répertoires git de l'application..."
	@make clone
	@echo "Construction de l'application..."
	@make build
	@echo "Création d'un lien symbolique pour la configuration du projet..."
	@echo "Installation des dépendences..."
	@make dependencies
	@echo "Mise en service de l'application..."
	@make serve

.PHONY: dependencies
dependencies: timer-back/vendor timer-back/node_modules timer-ui/node_modules ## Construit les dépendences du projet

# -------------------------
# Prépare les dépendences de l'application

timer-back/composer.lock: timer-back/composer.json
	@docker-compose run --rm timer-back sh -c "cd /var/www/timer-back && composer install --prefer-dist --optimize-autoloader --no-interaction"

timer-back/vendor: timer-back/composer.lock
	@docker-compose run --rm timer-back sh -c "cd /var/www/timer-back && composer install --prefer-dist --optimize-autoloader --no-interaction"

timer-back/yarn.lock: timer-back/package.json
	@docker-compose run --rm timer-back-node sh -c "cd /var/www/timer-back/yarn install"

timer-back/node_modules: timer-back/yarn.lock
	@docker-compose run --rm timer-back-node sh -c "cd /var/www/timer-back && yarn install --frozen-lockfile --check-files"

timer-ui/yarn.lock: timer-ui/package.json
	@docker-compose run --rm timer-ui-node sh -c "cd /var/www/timer-ui && yarn install"

timer-ui/node_modules: timer-ui/yarn.lock
	@docker-compose run --rm timer-ui-node sh -c "cd /var/www/timer-ui && yarn install --frozen-lockfile --check-files"
