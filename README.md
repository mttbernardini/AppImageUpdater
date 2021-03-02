# AppImage updater with daily cronjob

A simple bash script to update all AppImages under *~/Applications* (and possibly */Applications*),
using [`appimageupdatetool`](https://github.com/AppImage/AppImageUpdate).

A systemd timer is provided to run the script daily.

## Install

Clone this repo and run the makefile, 3 lines:

```sh
git clone https://github.com/mttbernardini/appimageupdater
cd appimageupdater
make install
```

---
© 2021 Matteo Bernardini

This project is licensed under the MIT License.
