const Linter = require('./classes/Linter'),
    fs = require('fs'),
    {exec} = require('child_process');
const {argv} = require('yargs'),
    executeLinting = async (paths, startPath) => {
        const lintNameSQL = 'lintSQL',
            lintNameJS = 'lintJS',
            lintNamePHP = 'lintPHP',
            isFixed = 'fix',
            linter = new Linter(paths, startPath).
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
                    linter.lintJS(argv._.includes(isFixed));
                }
            },
            {
                lint: lintNamePHP,
                handler: async (linter) => {
                    await linter.lintPHPFiles(exec, argv._.includes(isFixed)).
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

    const allFilesFlag = 'allFiles';

// Избавляемся от зависимости регистра
argv._ = argv._.map((item) => item.toLowerCase());

const config = JSON.parse(fs.readFileSync('./config.json', 'utf-8'));
let absPathRepo = __dirname.replace(/\\/g, '/');
let absPathLinter = absPathRepo;
let regPathRepo = new RegExp(config.linterPath + '$', 'i');

if (absPathRepo.includes(config.linterPath)) {
    absPathRepo = absPathRepo.replace(regPathRepo, '');
}

if (!argv._.includes(allFilesFlag.toLowerCase())) {
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
                            if (filePath.includes('../')) {
                                filePath = filePath.replace(/\.\.\//gi, '');
                                addOrGetPaths(absPathRepo + filePath);
                            } else {
                                addOrGetPaths(absPathLinter + '/' + filePath);
                            }
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
    executeLinting(null, absPathRepo).
        catch((error) => console.error(`При выполнение линтинга произошла ошибка: ${error}`));
}