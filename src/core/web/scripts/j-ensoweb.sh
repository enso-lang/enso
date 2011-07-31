#! /bin/sh

# Usage (from src dir) ensoweb.sh <app>.web <anymodel>
# anymodel will be the "root" of the application.

WEBSCRIPTS=core/web/scripts

export WEB=$1
export ROOT=$2

RUBYOPT="-I." jruby --1.9 -S rackup ${WEBSCRIPTS}/serve-batch.ru