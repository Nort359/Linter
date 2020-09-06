const fs = require('fs');
const path = require('path');
const execSync =  require('child_process').execSync;

class Path {
    /**
     * Метод рекурсивно прохоится по всем директориям в проекте и ищет файлы с заданными расширениеми.
     * @param {string}                    startPath     Директория, в которой необходимо начать поиск.
     * @param {string|Array<string>}      filters       Расширения файлов, которые необходимо найти.
     * @param {string|Array<string>|null} exceptionPath Пути до директорий, которые необходимо пропустить при поиске.
     */
    static getAllFilePaths(startPath, filters, exceptionPath = null) {
        let paths = [];

        if (!Array.isArray(exceptionPath)) {
            exceptionPath = [exceptionPath];
        }

        for (let i = 0; i < exceptionPath.length; i++) {
            if (!!~startPath.indexOf(exceptionPath[i])) {
                return [];
            }
        }

        if (!~exceptionPath.indexOf(startPath)) {
            if (!fs.existsSync(startPath)) {
                return [];
            }

            const files = fs.readdirSync(startPath);

            files.forEach(file => {
                const fileName = path.join(startPath, file);
                const stat = fs.lstatSync(fileName);

                if (stat.isDirectory()) {
                    paths = paths.concat(Path.getAllFilePaths(fileName, filters, exceptionPath)); // Recurse
                } else {
                    filters.forEach(filter => {
                        let ext = fileName.split('.');

                        ext = ext[ext.length - 1];

                        if (ext === filter) {
                            paths.push(fileName);
                        }
                    });
                }
            });
        }

        return paths;
    }

    static getModifiedFilePaths(argv, absPathRepo, exts) {
        const config = JSON.parse(fs.readFileSync('./config.json', 'utf-8'));
        let absPathLinter = absPathRepo, // Абсолютный путь до линтера
            regPathRepo = new RegExp(config.linterPath + '$', 'i');

        if (absPathRepo.includes(config.linterPath)) {
            absPathRepo = absPathRepo.replace(regPathRepo, '');
        }

        const filePosition = argv._.indexOf('files');
        let paths = [];

        // Если пользователем были переданы файлы
        if (filePosition !== -1) {
            for (let i = filePosition + 1; i < argv._.length; i++) {
                paths.push(absPathRepo + argv._[i]);
            }
        } else if (!argv._.includes('allFiles')) {
            let gitCommands = ['diff'];
            let gitCommand = '';

            for (let i = 0; i < gitCommands.length; i++) {
                if (argv._.includes(gitCommands[i])) {
                    const position = argv._.indexOf(gitCommands[i]);

                    gitCommand += `${argv._[position]} ${argv._[position + 1]}`;
                    break; // Предполагается только одна инструкция git
                }
            }

            if (gitCommand !== '') {
                gitCommand = 'git ' + gitCommand;
            }

            /**
             * Подготавливает пути перед выполнением линтинга.
             */
            const prepareLinting = command => {
                if (command) {
                    let message = execSync(command).toString();

                    message && message.split('\n').forEach(line => {
                        const reg = /(--- a\/)|(\+\+\+ b\/)/;

                        if (reg.test(line)) {
                            const path = absPathRepo + line.replace(reg, '');

                            if (!paths.includes(path)) {
                                paths.push(path);
                            }
                        }
                    });
                }
            };

            prepareLinting(gitCommand);

            let message = execSync('git status').toString();
            let lines = message.split('\n');

            lines.forEach(line => {
                /*
                 * При перемещении Git добавляет удалённые в файлы и в блок new files и в deleted.
                 * Если файл встретился и в том и в том блоке - пропускаем такой файл, т.к. считаем его удалённым.
                 */
                const gitStatusArray = line.split(':');
                const gitStatus = gitStatusArray[0] && gitStatusArray[0].trim();
                const isDeleted = gitStatus === 'deleted';
                const isChanged = gitStatus === 'modified' || gitStatus === 'new file' || gitStatus === 'renamed';
                let filePath = gitStatusArray[1] && gitStatusArray[1].trim();

                if (filePath && filePath.includes(' -> ')) {
                    filePath = filePath.split(' -> ')[1].trim();
                }

                if (isChanged && !isDeleted) {
                    if (filePath.includes('../')) {
                        filePath = filePath.replace(/\.\.\//gi, '');
                        paths.push(absPathRepo + filePath);
                    } else {
                        paths.push(absPathLinter + '/' + filePath);
                    }
                }
            });
        } else {
            const paths = Path.getAllFilePaths(absPathRepo, exts, [
                'node_modules',
                '.git',
                '.idea',
                'temp',
                'external'
            ]);

            for (let i = 0; i < paths.length; i++) {
                paths.push(paths[i]);
            }
        }

        return paths;
    }
}

module.exports = Path;
