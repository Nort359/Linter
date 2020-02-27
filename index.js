const Linter = require('./classes/Linter');
const exec = require('child_process').exec;
const argv = require('yargs').argv;
const executeLinting = async paths => {
    const linter = new Linter(paths)
        .getContentTagsInFile()
        .writeToFile()
        .lintTables()
        .lintJS();

    await linter.lintPHPFiles(exec, argv.phpFix === 'true')
        .catch(error => {
            if (error) {
                console.error(`Произошла ошибка при проверке PHP-кода: ${error}`);
            }
    });

    linter.deleteTempFiles();
};

const setPaths = () => {
    const paths = [];

    return path => {
        if (path && !paths.includes(path)) {
            paths.push(path);
        }

        return paths;
    };
};
const addOrGetPaths = setPaths();

if (!argv.fromGit) {
    argv.fromGit = 1;
}

if (+argv.fromGit === 1) {
    const executeCommand = (command, cb) => {
        exec(command, (err, stdout, stderr) => {
            if (err !== null) {
                return cb(new Error(err), null);
            } else if( typeof stderr !== 'string') {
                return cb(new Error(stderr), null);
            } else {
                return cb(null, stdout);
            }
        });
    };

    const gitCommands = [
        'diff'
    ];
    let gitCommand = 'git ';

    for (let i = 0; i < gitCommands.length; i++) {
        if (argv._.includes(gitCommands[i])) {
            gitCommand += argv._[i] + ' ' + argv._[i + 1];
            break; // Предполагается только одна инструкция git
        }
    }

    const prepareLinting = () => {
        return new Promise(resolve => {
            executeCommand(gitCommand, (error, message) => {
                const paths = [];

                message && message.split('\n').forEach(line => {
                    const reg = /(--- a\/)|(\+\+\+ b\/)/;

                    if (reg.test(line)) {
                        const path = line.replace(reg, '');
                        addOrGetPaths(path);
                    }
                });

                resolve();
            });
        });
    };

    prepareLinting()
        .then(() => {
            executeCommand('git status', (error, message) => {
                if (!error) {
                    let lines = message.split('\n');

                    lines.forEach(line => {
                        if (line.includes('modified') || line.includes('new file') || line.includes('renamed')) {
                            const filePath = line.split(':')[1].trim();
                            addOrGetPaths(filePath);
                        }
                    });
                } else {
                    console.error(error);
                }

                executeLinting(addOrGetPaths())
                    .catch(error => console.error(`При выполнение линтинга произошла ошибка: ${error}`));
            });
        })
        .catch(error => console.error(error));
} else {
    executeLinting()
        .catch(error => console.error(`При выполнение линтинга произошла ошибка: ${error}`));
}
