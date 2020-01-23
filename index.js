const Linter = require('./classes/Linter');
const exec = require('child_process').exec;

const executeLinting = paths => {
    new Linter(paths)
        .getContentTagsInFile()
        .writeToFile()
        .lintJS()
        .deleteTempFiles();
};

if (+process.env.fromGit === 1) {
    const executeCommand = (command, cb) => {
        var child = exec(command, (err, stdout, stderr) => {
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
                if (line.includes('modified')) {
                    const filePath = line.split(':')[1].trim();
                    modifiedFiles.push(filePath);
                }
            });
        } else {
            console.error(error);
        }

        executeLinting(modifiedFiles);
    });
} else {
    executeLinting();
}
