const Linter = require('./classes/Linter');
const util = require('util');
const exec = require('child_process').exec;

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

        // console.log(message);
    } else {
        console.error(error);
    }

    // const linter = new Linter(modifiedFiles);
    const linter = new Linter();

    linter
        .getContentTagsInFile()
        .writeToFile()
        .lintJS()
        .deleteTempFiles();
});

// TODO: скрипт для отлавливания вывода в консоль. Может пригодится.

// let test = [];
//
// function hook_stdout(callback) {
//     var old_write = process.stdout.write;
//
//     process.stdout.write = (function(write) {
//         return function(string, encoding, fd) {
//             write.apply(process.stdout, arguments);
//             callback(string, encoding, fd);
//         }
//     })(process.stdout.write);
//
//     return function() {
//         process.stdout.write = old_write;
//     }
// }
//
// const unhook = hook_stdout(function(string, encoding, fd) {
//     test.push(string.replace('\n', '').replace('\r', ''));
// });

// [
//     './spec/resources/form.frm',
//     './spec/resources/formM2.frm',
//     './spec/resources/formD3.frm'
// ]

// const linter = new Linter();
//
// linter
//   .getContentTagsInFile()
//   .writeToFile();



// console.log('a');
// console.log('b');
//
// console.log('c');
// console.log('d');
//
// console.log('e');
// console.log('f');

// unhook();
//
// console.log(test);