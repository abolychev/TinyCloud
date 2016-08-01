TinyCloud
=========

Понадобился минимальный функционал ownCloud, но более простой и из любого каталога. Так появился tinycloud.
Что умеет:
* отображать структуру файлов и каталогов в текущем каталоге
* мультизагрузка файлов
* отображение картинок в виде галереи

## Usage

cd foo/bar; tinycloud

go to http://you_ip:3000

## Install

apt-get install cpanminus

cpanm Mojolicious::Lite
cpanm Modern::Perl

wget https://raw.github.com/abolychev/TinyCloud/master/tinycloud
chmod +x tinycloud
