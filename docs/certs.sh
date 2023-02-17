#!/bin/bash
echo "Installing brew packages ..."
brew install mkcert > /dev/null 2>&1
brew install nss > /dev/null 2>&1

echo "Generating self signed certificate ..."
mkdir temp/ > /dev/null 2>&1
cd temp/; mkcert "*.palspace.dev" > /dev/null 2>&1

echo "Installing self signed certificate ..."
cd temp/; mkcert -install

echo "Copying certificate to proxy ..."
mv temp/_wildcard.palspace.dev.pem docker/ingress/custom_ssl/npm-1/fullchain.pem > /dev/null 2>&1
mv temp/_wildcard.palspace.dev-key.pem docker/ingress/custom_ssl/npm-1/privkey.pem > /dev/null 2>&1

echo "Installing self signed certificate into containers ..."
cd ../
make up
CONTAINER=$(docker ps -aqf "name=palspace-backend")
docker cp docker/ingress/custom_ssl/npm-1/fullchain.pem $CONTAINER:/usr/local/share/ca-certificates/certi.crt > /dev/null 2>&1
docker exec -it $CONTAINER update-ca-certificates > /dev/null 2>&1

echo "Cleaning up temp ..."
rm -rf temp/
echo "Done."
echo "Opening certificate folder in Finder, for iOS please drag and drop the rootCA.pem to your simulator."
cd ~/Library/Application\ Support/mkcert; open .