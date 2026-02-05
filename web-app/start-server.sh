#!/bin/bash

##
## @version $Version: 1.1.3$
## @author buzzcauldron
## @copyright Copyright(c) 2025, buzzcauldron
## @license MIT License
##

## Setup umask, user and group IDs for running apachectl ##
[ "$DATA_UMASK" != "" ] && umask "$DATA_UMASK";
[ "$DATA_UID" = "" ] && DATA_UID=$(stat -c %u /var/www/visual-page-editor/data);
[ "$DATA_GID" = "" ] && DATA_GID=$(stat -c %g /var/www/visual-page-editor/data);
usermod -u $DATA_UID www-data;
groupmod --non-unique -g $DATA_GID www-data;
chown :www-data /var/www/visual-page-editor/app;
chmod g+w /var/www/visual-page-editor/app;

## Start the git commit daemon ##
if [ -d "/var/www/visual-page-editor/data/.git" ]; then
  cd /var/www/visual-page-editor/data;
  export HOME="/var/www";
  git config --global user.email "www-data@visual-page-editor.org";
  git config --global user.name "www-data";
  chown www-data: /var/www/.gitconfig;
  git status >/dev/null 2>&1;
  RC="$?";
  cd -;
  if [ "$RC" = 0 ]; then
    echo "Starting git-commit-daemon ...";
    cd /var/www/visual-page-editor/app;
    sudo -u www-data ./git-commit-daemon.sh \
      >>/var/log/apache2/git-commit-daemon.log \
      2>>/var/log/apache2/git-commit-daemon.err &
    # @todo These logs are not being flushed properly
  else
    echo "ERROR: /var/www/visual-page-editor/data/.git exists but commit daemon not started due to an unexpected git status";
    exit $RC;
  fi
fi

## Start apache server ##
apachectl -D FOREGROUND;
