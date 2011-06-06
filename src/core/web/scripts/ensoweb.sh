#! /bin/sh


WEBSCRIPTS=core/web/scripts

export WEB=$1
export ROOT=$2

RUBYOPT="-I." thin start -V -D -R ${WEBSCRIPTS}/serve.ru