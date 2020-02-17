const Linter = require('./classes/Linter');
const exec = require('child_process').exec;
const argv = require('yargs').argv;
const executeLinting = async paths => {
    const linter = new Linter(paths)
        .getContentTagsInFile()
        .writeToFile()
        .lintJS();

    await linter.lintPHPFiles(exec, argv.phpFix === 'true')
        .catch(error => {
            if (error) {
                console.error(`Произошла ошибка при проверке PHP-кода: ${error}`);
            }
    });

    linter.deleteTempFiles();
};

if (+process.env.fromGit === 1) {
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

    executeCommand('git status', (error, message) => {
        let modifiedFiles = [];

        if (!error) {
            let lines = message.split('\n');

            lines.forEach(line => {
                if (line.includes('modified') || line.includes('new file') || line.includes('renamed')) {
                    const filePath = line.split(':')[1].trim();
                    modifiedFiles.push(filePath);
                }
            });
        } else {
            console.error(error);
        }

        executeLinting(modifiedFiles)
            .catch(error => console.error(`При выполнение линтинга произошла ошибка: ${error}`));
    });
} else {
    executeLinting()
        .catch(error => console.error(`При выполнение линтинга произошла ошибка: ${error}`));
}
