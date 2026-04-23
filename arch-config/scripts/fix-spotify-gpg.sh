#!/usr/bin/env bash
# Fix Spotify AUR GPG key issue

gpg --keyserver keyserver.ubuntu.com --recv-keys C85668DF69375001
paru -S spotify
