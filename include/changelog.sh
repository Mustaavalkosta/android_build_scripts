#!/bin/bash
# Generates changelog based on revisions

generate_changelog()
{
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]
    then
        echo "Insufficient parameters. Usage: $FUNCNAME [from revision file] [to file path] [changelog path] [revision timestamp]"
        exit 0
    fi

    FROM=$1
    TO=$2
    CHANGELOG=$3

    # Save new revision timestamp
    echo $4 > $TO

    # Start with header
    echo -e "## Changes since $(head -n 1 $FROM) ##\n" > $CHANGELOG

    repo forall -pc '
        echo $REPO_PATH:$REPO_LREV >> '"$TO"'
        PREV_REV=`grep "$REPO_PATH:" '"$FROM"' |cut -d ":" -f2`
        if git rev-parse $PREV_REV >/dev/null 2>&1
        then
            git log --oneline --no-merges $PREV_REV..HEAD
        fi
    ' | cat >> $CHANGELOG
}
