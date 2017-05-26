#!/bin/sh

source /vagrant/macros

# lookup my hostname IP from env
hostname=$(hostname)
ip=${!hostname}

