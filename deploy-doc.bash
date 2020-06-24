#!/bin/bash

if [[ ! -z $CI ]]; then
  git config --global user.email "davidsiaw@gmail.com"
  git config --global user.name "David Siaw (via Circle CI)"
fi

cd docs

bundle install -j4
bundle exec weaver build -r https://tataru.astrobunny.net

pushd build
echo tataru.astrobunny.net > CNAME
cp 404/index.html 404.html
popd
