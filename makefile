#!/usr/bin/make -f

NAME        = appimageupdater
APPS_DIR    = ~/Applications
SYSTEMD_DIR = ~/.local/share/systemd/user

.PHONY: install uninstall

install:
	install -d $(APPS_DIR) $(SYSTEMD_DIR)
	install -t $(APPS_DIR) $(NAME).sh
	install -t $(SYSTEMD_DIR) $(NAME).service $(NAME).timer
	systemctl --user daemon-reload
	systemctl --user enable $(NAME).timer

uninstall:
	systemctl --user disable $(NAME).timer
	rm $(APPS_DIR)/$(NAME).sh
	rm $(SYSTEMD_DIR)/$(NAME).service $(SYSTEMD_DIR)/$(NAME).timer
	systemctl --user daemon-reload
