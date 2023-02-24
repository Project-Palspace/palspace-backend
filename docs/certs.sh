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

# If darwin let's install brew packages
if [ "$machine" = "Mac" ]; then
  echo "Installing brew packages ..."
  brew install mkcert > /dev/null 2>&1
  brew install nss > /dev/null 2>&1
fi

# If mingw let's install brew packages
if [ "$machine" = "MinGw" ]; then
  echo "Installing choco packages ..."
  sudo choco install mkcert > /dev/null 2>&1
fi

echo "Generating self signed certificate ..."
mkdir temp/
cd temp/
mkcert "*.palspace.dev" > /dev/null 2>&1

echo "Installing self signed certificate ..."
# If mingw let's install brew packages
if [ "$machine" = "MinGw" ]; then
  sudo mkcert -install
else
  mkcert -install
fi
cd ../

echo "Copying certificate to proxy ..."
rm docker/ingress/custom_ssl/npm-1/fullchain.pem
rm docker/ingress/custom_ssl/npm-1/privkey.pem
mv temp/_wildcard.palspace.dev.pem docker/ingress/custom_ssl/npm-1/fullchain.pem
mv temp/_wildcard.palspace.dev-key.pem docker/ingress/custom_ssl/npm-1/privkey.pem

echo "Installing self signed certificate into containers ..."
make up
CONTAINER=$(docker ps -aqf "name=palspace-backend")
docker cp docker/ingress/custom_ssl/npm-1/fullchain.pem $CONTAINER:/usr/local/share/ca-certificates/certi.crt > /dev/null 2>&1
docker exec -it $CONTAINER update-ca-certificates > /dev/null 2>&1

echo "Cleaning up temp ..."
rm -rf temp/
echo "Done."

if [ "$machine" = "Mac" ]; then
  echo "Opening certificate folder in Finder, for iOS please drag and drop the rootCA.pem to your simulator."
  cd ~/Library/Application\ Support/mkcert; open .
fi