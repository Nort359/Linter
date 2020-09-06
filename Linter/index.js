const Linter = require('./classes/Linter');
const Path = require('./classes/Path');

const process = require('process');
const {argv} = require('yargs');

const addHandlersLinter = require('./scripts/addHandlersLinter');
const linter = addHandlersLinter(new Linter());

// Избавляемся от зависимости регистра
argv._ = argv._.map((item) => item.toLowerCase());

let absPathRepo = __dirname.replace(/\\/g, '/'); // абсолютный путь к проекту

let messages = [];
let paths = Path.getModifiedFilePaths(argv, absPathRepo, linter.getExts());

if (argv._.includes('list')) {
    console.log('Список доступных линтеров:');
    linter.getLinters().forEach((name, id) => console.log(id + 1 + '. ' + name));
} else {
    try {
        const content = linter.handle(paths);
        messages = linter.lint(argv._.includes('fix'), content);
    } catch (e) {
        console.error(`При выполнение линтинга произошла ошибка: ${e.message}`);
    }

    messages.forEach(message => {
        console.log(message);
    });
}

process.exit();
