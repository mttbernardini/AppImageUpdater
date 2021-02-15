# AppImage updater with daily cronjob

A simple bash script to update all AppImages under *~/Applications*,
using [`appimageupdatetool`](https://github.com/AppImage/AppImageUpdate).

A systemd timer is provided to run the script daily.

## Install

Clone this repo and run the makefile, 3 lines:

```sh
git clone https://gist.github.com/0c63d1fc41d081033f2235f40fae6680.git appimageupdater
cd appimageupdater
make install
```
