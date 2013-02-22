#! /bin/sh

# Usage (from src dir) ensoweb.sh <app>.web <anymodel>
# anymodel will be the "root" of the application.

WEBSCRIPTS=apps/web/scripts

export WEB=$1
export SCHEMA=$2
export AUTH=$3

RUBYOPT="-I." jruby --1.9 -S rackup ${WEBSCRIPTS}/serve-batch.ru