#!/usr/bin/env sh

cd `dirname $0`/../
rm -rf sphinx_rtd_theme
git clone https://github.com/snide/sphinx_rtd_theme.git sphinx_rtd_theme_repo
mv sphinx_rtd_theme_repo/sphinx_rtd_theme .
rm -rf sphinx_rtd_theme_repo
echo "Theme updated"
