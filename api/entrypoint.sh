#! /bin/bash
cmd="$@"
python manage.py migrate
exec $cmd
