#!/bin/bash

if [[ ! -z $CI ]]; then
  git config --global user.email "davidsiaw@gmail.com"
  git config --global user.name "David Siaw (via Circle CI)"
fi

cd docs

git clone git@github.com:davidsiaw/tataru.git build
cd build
  git checkout gh-pages
cd ..

cp -r build/.git ./gittemp
bundle exec weaver build -r https://tataru.astrobunny.net
cp -r ./gittemp build/.git
pushd build
echo tataru.astrobunny.net > CNAME
cp 404/index.html 404.html
git add .
git add -u
git commit -m "update `date`"
ssh-agent bash -c 'ssh-add ~/.ssh/id_github.com; git push -u origin gh-pages'
popd
