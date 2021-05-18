#!/usr/bin/make -f

NAME        = appimage-updater
BIN_DIR     = ~/.local/bin
SYSTEMD_DIR = ~/.local/share/systemd/user

.PHONY: install uninstall

install:
	install -d $(BIN_DIR) $(SYSTEMD_DIR)
	install -m 755 -t $(BIN_DIR) $(NAME).py
	install -m 644 -t $(SYSTEMD_DIR) $(NAME).service $(NAME).timer
	systemctl --user daemon-reload
	systemctl --user enable $(NAME).timer

uninstall:
	systemctl --user disable $(NAME).timer || true
	rm -f $(BIN_DIR)/$(NAME).py
	rm -f $(SYSTEMD_DIR)/$(NAME).service $(SYSTEMD_DIR)/$(NAME).timer
	systemctl --user daemon-reload
