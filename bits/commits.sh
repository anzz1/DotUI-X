#!/bin/bash

# echo "$(git rev-parse --short=8 HEAD)  $(basename $PWD) ($(date "+%Y-%m-%d %H:%M:%S"))" # $(git config --get remote.origin.url)
# echo "--------  ------"
#
shopt -s dotglob
update() {
    for d in "$@"; do
        test -d "$d" -a \! -L "$d" || continue
        cd "$d"
        if [ -d ".git" ] || [ -f ".git" ]; then
            echo "$(git rev-parse --short=8 HEAD)  $(basename $PWD)" # $(git config --get remote.origin.url)
            update *
        fi
        cd ..
    done
}

cd ./third-party
update *

cd ./picoarch/cores
update *

echo "--------"
echo "generated by $0"
