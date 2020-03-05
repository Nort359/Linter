const Linter = require('./classes/Linter'),
    fs = require('fs'),
    {exec} = require('child_process');
const {argv} = require('yargs'),
    executeLinting = async (paths) => {
        const lintNameSQL = 'lintSQL',
            lintNameJS = 'lintJS',
            lintNamePHP = 'lintPHP',
            linter = new Linter(paths).
                getContentTagsInFile().
                writeToFile();

        let linterNames = [
                lintNameSQL,
                lintNameJS,
                lintNamePHP
            ],
            lintersCount = 0;

        // Избавляемся от зависимости регистра
        argv._ = argv._.map((item) => item.toLowerCase());
        linterNames = linterNames.map((linterName) => linterName.toLowerCase());

        // Проверяем количество переданных линтеров
        linterNames.forEach((linterName) => {
            if (argv._.includes(linterName)) {
                lintersCount++;
            }
        });

        // Если не было передано ни одно линтера, то линтим всё
        if (lintersCount === 0) {
            linterNames.forEach((linterName) => {
                argv._.push(linterName);
            });
        }

        const lintHandlers = [
            {
                lint: lintNameSQL,
                handler: (linter) => {
                    linter.lintSQL();
                }
            },
            {
                lint: lintNameJS,
                handler: (linter) => {
                    linter.lintJS(argv._.includes('jsFix'.toLowerCase()));
                }
            },
            {
                lint: lintNamePHP,
                handler: async (linter) => {
                    await linter.lintPHPFiles(exec, argv._.includes('phpFix'.toLowerCase())).
                        catch((error) => {
                            if (error) {
                                console.error(`Произошла ошибка при проверке PHP-кода: ${error}`);
                            }
                        });
                }
            }
        ];

        // Избавляемся от зависимости регистра
        argv._ = argv._.map((item) => item.toLowerCase());

        lintHandlers.forEach((lintHandler) => {
            if (argv._.includes(lintHandler.lint.toLowerCase())) {
                lintHandler.handler(linter);
            }
        });

        /*
         *If (argv._.includes(lintSQL)) {
         *  linter.lintSQL();
         *}
         *if (argv._.includes(lintJS)) {
         *  linter.lintJS(argv._.includes('jsFix'));
         *}
         *if (argv._.includes(lintPHP)) {
         *  await linter.lintPHPFiles(exec, argv._.includes('phpFix')).
         *      catch((error) => {
         *          if (error) {
         *              console.error(`Произошла ошибка при проверке PHP-кода: ${error}`);
         *          }
         *      });
         *}
         */

        /*
         *[
         *  lintSQL,
         *  lintJS,
         *  lintPHP
         *].forEach(lint => {
         *  if (argv._.includes(lint)) {
         *
         *  }
         *});
         */

        linter.deleteTempFiles();
    },

    /**
     * Возвращает функцию, замыкающую на себе массив всех проверяемых путей.
     * @return {function(*=): Array}
     */
    setPaths = () => {
        const paths = [];

        return (path) => {
            if (path && !paths.includes(path)) {
                paths.push(path);
            }

            return paths;
        };
    },
    addOrGetPaths = setPaths();

if (!argv.fromGit) {
    argv.fromGit = 1;
}

const config = JSON.parse(fs.readFileSync('./config.json', 'utf-8'));
let absPathRepo = __dirname.replace(/\\/g, '/');

if (absPathRepo.includes(config.linterPath)) {
    absPathRepo = absPathRepo.replace(config.linterPath, '');
}

if (+argv.fromGit === 1) {
    /**
     * Выполняет команду в терминале.
     * @param {string} command - Текст команды.
     * @param {function} cb - callback, выполняется после выполнения команды.
     * @return {string} - Результат выполнения команды.
     */
    const executeCommand = (command, cb) => {
            exec(command, (err, stdout, stderr) => {
                if (err !== null) {
                    return cb(new Error(err), null);
                } else if (typeof stderr !== 'string') {
                    return cb(new Error(stderr), null);
                } 
                
                return cb(null, stdout);
            
            });
        },

        gitCommands = ['diff'];
    let gitCommand = 'git ';

    for (let i = 0; i < gitCommands.length; i++) {
        if (argv._.includes(gitCommands[i])) {
            gitCommand += `${argv._[i]} ${argv._[i + 1]}`;
            break; // Предполагается только одна инструкция git
        }
    }

    /**
     * Подготавливает пути перед выполнением линтинга.
     * @return {Promise<any>}
     */
    const prepareLinting = () => new Promise((resolve) => {
        executeCommand(gitCommand, (error, message) => {
            const paths = [];

            message && message.split('\n').forEach((line) => {
                const reg = /(--- a\/)|(\+\+\+ b\/)/;

                if (reg.test(line)) {
                    const path = absPathRepo + line.replace(reg, '');

                    if (!addOrGetPaths().includes(path)) {
                        addOrGetPaths(path);
                    }
                }
            });

            resolve();
        });
    });

    prepareLinting().
        then(() => {
            executeCommand('git status', (error, message) => {
                if (!error) {
                    const lines = message.split('\n');

                    lines.forEach((line) => {
                        /*
                         *При перемещении Git добавляет удалённые в файлы и в блок new files и в deleted.
                         *Если файл встретился и в тои и в том блоке - пропускаем такой файл, т.к. считаем его удалённым.
                         */
                        const gitStatusArray = line.split(':'),
                            gitStatus = gitStatusArray[0] && gitStatusArray[0].trim(),
                            isDeleted = gitStatus === 'deleted',
                            isChanged = gitStatus === 'modified' || gitStatus === 'new file' || gitStatus === 'renamed';
                        let filePath = gitStatusArray[1] && gitStatusArray[1].trim();

                        if (filePath && filePath.includes(' -> ')) {
                            filePath = filePath.split(' -> ')[1].trim();
                        }

                        if (isChanged && !isDeleted) {
                            addOrGetPaths(filePath);
                        }
                    });
                } else {
                    console.error(error);
                }

                executeLinting(addOrGetPaths()).
                    catch((error) => console.error(`При выполнение линтинга произошла ошибка: ${error}`));
            });
        }).
        catch((error) => console.error(`При выполнение линтинга произошла ошибка: ${error}`));
} else {
    executeLinting().
        catch((error) => console.error(`При выполнение линтинга произошла ошибка: ${error}`));
}