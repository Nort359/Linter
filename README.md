# Linter
Линтер для МИС.

## Установка зависимостей

Сперва необходимо установить nodejs 10 версии (https://nodejs.org/fr/blog/release/v10.0.0/) на локальную машину,
после чего в терминале, находясь в корневой директории репозитория, запустить комнады:

```shell
$ npm cd Linter
$ npm i
```

Для линтинга PHP файлов необходимо установить composer на локальную машину (https://getcomposer.org/download/).
Далее в терминале набираем команду

```shell
$ composer global require "squizlabs/php_codesniffer=*"
```

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

2. Если необходимо, чтобы линтер исправил возможные ошибки в JS без вмешательства разработчика,
то необходимо ввести следующую команду:

```shell
$ npm run linter jsFix
```

3. Если необходимо, чтобы линтер исправил возможные ошибки в PHP без вмешательства разработчика,
то необходимо ввести следующую команду:

```shell
$ npm run linter phpFix
```

4. Есть также возможность использовать теже самые команды, что и в команде git diff
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
