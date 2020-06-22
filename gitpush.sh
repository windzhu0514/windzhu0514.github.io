#!/bin/sh
echo "git pulling ..."
git pull




echo "generating site ..."
hugo

echo "push website source to github ..."
echo "git adding ..."
git add -A

echo "git pushing ..."
git commit -m "website source update"
git push

echo "push website to github ..."
cd ../windzhu0514.github.io

echo "git pulling ..."
git pull
echo "git adding ..."
git add -A
echo "git pushing ..."
git commit -m "website update"
git push
