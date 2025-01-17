# Linter
Линтер для МИС.

## Установка зависимостей

Сперва необходимо установить nodejs 10 версии (https://nodejs.org/fr/blog/release/v10.0.0/) на локальную машину,
после чего в терминале, находясь в корневой директории репозитория, запустить комнады:

```shell
$ cd Linter
$ npm i
```

Для линтинга PHP файлов необходимо установить composer на локальную машину (https://getcomposer.org/download/).
Далее в терминале набираем команду

```shell
$ composer global require "squizlabs/php_codesniffer=*"
```

Если система не видит команду composer, то перезапустите компьютер.
Чтобы проверить, что библиотека корректно установилась можно воспользоваться командой:

```shell
$ phpcs --version
```

## Запуск

Запустить линтер можно с помощью нескольких команд:

1. Провести линтинг всех файлов находящихся в текущем stage (git status):

```shell
$ npm run linter
```

2. Если необходимо провести линтинг только конкретного языка, то необходимо добавлять
следующие ключевые слова:

```shell
$ npm run linter sql // Проведёт линтинг только SQL тэгов.
$ npm run linter js // Проведёт линтинг только JS тэгов и файлов.
$ npm run linter php // Проведёт линтинг только PHP тэгов и файлов.
```

По умолчанию, если не передан никакой линтинг, то считается, что необходимо линтить все языки.

```shell
$ npm run linter sql js php
```

Для того, чтобы проверить какие линтеры поддерживаются, необходимо использовать команду:

```shell
$ npm run linter list
```

3. Если необходимо, чтобы линтер исправил возможные ошибки без вмешательства разработчика,
то необходимо ввести следующую команду:

```shell
$ npm run linter fix
```

4. Для проверки всех файлов по всему проекту необходимо ввести следующию команду:

```shell
$ npm run linter allFiles
```

иначе будут проверяться только те файлы, которые вошли в текущий стэйдж из команды git status.

5. Чтобы провести проверку конкретных файлов, необходимо передать ключевое слово files и через пробел указать
файлы, которые необходимо пролинтить. Пути к файлам указываются относительно корневой дикректории репозитория:

```shell
$ npm run linter files path1 path2 path3
```

6. Есть также возможность использовать те же самые команды, что и в команде git diff
- Например проверить разницу между двумя коммитами:

```shell
$ npm run linter diff коммит1..коммит2
```

- Можно также использовать все другие верификации команды git diff. Например:
```shell
$ npm run linter diff ветка1..master
$ npm run linter diff master...
$ npm run linter diff HEAD^
```
