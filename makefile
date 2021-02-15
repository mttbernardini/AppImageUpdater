#!/usr/bin/make -f

NAME        = appimageupdater
APPS_DIR    = ~/Applications
SYSTEMD_DIR = ~/.local/share/systemd/user

.PHONY: install uninstall

install:
	mkdir -p $(APPS_DIR)
	mkdir -p $(SYSTEMD_DIR)
	ln -sft $(APPS_DIR) $$(realpath $(NAME).sh)
	ln -sft $(SYSTEMD_DIR) $$(realpath $(NAME).service $(NAME).timer)
	systemctl --user daemon-reload
	systemctl --user enable $(NAME).timer

uninstall:
	systemctl --user disable *.timer
	rm $(APPS_DIR)/$(NAME).sh
	rm $(SYSTEMD_DIR)/$(NAME).service $(SYSTEMD_DIR)/$(NAME).timer
	systemctl --user daemon-reload
