#!/usr/bin/env python3

import os
from itertools import chain
from tempfile import TemporaryDirectory
from sys import exit
from pathlib import Path
from argparse import ArgumentParser
from subprocess import run

class AppImageUpdater:
	__slots__ = ("tracked_dirs", "aiu_name", "_aiu_exec", "_opts", "_updated")

	def __init__(self, args=None):
		self.tracked_dirs = ("/Applications", "~/Applications")
		self.aiu_name = "appimageupdatetool-*.AppImage"
		self._aiu_exec = None
		self._updated = 0
		self._parse_args(args)

	def _parse_args(self, args):
		parser = ArgumentParser()
		parser.add_argument("-n", action="store_true", help="send a notification with the number of updated applications (only if there's at least one)")
		parser.add_argument("-v", action="store_true", help="verbose mode (i.e. show output from `appimageupdatetool` sub-process")
		self._opts = parser.parse_args(args)

	def _log(self, msg, type="step"):
		codes = {
			"step": "34",
			"ok": "32",
			"info": "1;33",
			"error": "31",
		}
		print(f"\033[{codes[type]}m# {msg}\033[0m")

	def _send_notification(self):
		if self._opts.n and self._updated > 1:
			run(["notify-send", "-i", "dialog-information-symbolic", f"Updated {self._updated} AppImage(s)"])

	def _find_updater(self):
		for d in self.tracked_dirs:
			execs = Path(d).expanduser().glob(self.aiu_name)
			for exec in execs:
				if os.access(exec, os.X_OK):
					self._aiu_exec = exec
					return
		self._log(f"appimageupdatetool not found in {self.tracked_dirs}, or missing x permission. Cannot check updates.", "error")
		exit(1)

	def _update_app(self, app, workdir):
		# work on temp dir link to avoid permission issues and clobbering with zsync temp files
		tmp_app = workdir/app.name
		tmp_app.symlink_to(app)

		# nb: -O doesn't actually "overwrite", but rather replaces the file (i.e. original file is unlinked)
		check = run([self._aiu_exec, "-O", tmp_app], capture_output=not self._opts.v)

		if check.returncode == 0:
			try:
				tmp_app.replace(app)
				self._log(f"Successfully updated {app.name}", "ok")
				self._updated += 1
			except OSError:
				# TODO: handle permissions
				pass
		else:
			self._log(f"Something went wrong while updating {app.name} (exit code {check.returncode})", "error")

	def _update_apps(self, workdir):
		for d in self.tracked_dirs:
			pd = Path(d).expanduser()
			for app in chain(pd.glob("*.AppImage"), pd.glob("*.appimage")):
				self._log(f"Checking updates for {app.name}")
				check = run([self._aiu_exec, "-j", app], capture_output=not self._opts.v)
				if check.returncode == 0:
					self._log(f"No updates available for {app.name}", "info")
				elif check.returncode == 1:
					self._update_app(app, workdir)
				else:
					if self._opts.v: print() # sometimes $aiu_exec doesn't print trailing \n
					self._log(f"Cannot check updates for {app.name} (exit code {check.returncode})", "error")
		self._log(f"Done, updated {self._updated} AppImages.")

	def run_update(self):
		self._find_updater()
		with TemporaryDirectory() as wd:
			self._update_apps(Path(wd))
		self._send_notification()

	def abort(self):
		self._log(f"Aborted, updated {self._updated} AppImages.", "error")
		self._send_notification()
		exit(1)


if __name__ == "__main__":
	upd = AppImageUpdater()
	try:
		upd.run_update()
	except KeyboardInterrupt:
		upd.abort()
