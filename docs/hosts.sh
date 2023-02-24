#!/bin/bash
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac
echo "Running on ${machine}"

# If linux or mac let's echo the hosts
if [ "$machine" = "Linux" ] || [ "$machine" = "Mac" ]; then
  echo "127.0.0.1    mail.palspace.dev" | sudo tee -a /etc/hosts
  echo "127.0.0.1    api.palspace.dev" | sudo tee -a /etc/hosts
  echo "127.0.0.1    obj.palspace.dev" | sudo tee -a /etc/hosts
  echo "127.0.0.1    obj-portal.palspace.dev" | sudo tee -a /etc/hosts
  echo "127.0.0.1    proxy.palspace.dev" | sudo tee -a /etc/hosts
fi

# If mingw let's echo the hosts
if [ "$machine" = "MinGw" ]; then
  sudo docs\\hosts.bat
fi