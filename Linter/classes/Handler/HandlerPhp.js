const Handler = require('./Handler');
const process = require('process');
const execSync =  require('child_process').execSync;

class HandlerPhp extends Handler {
    /**
     * Линтит php файлы, с PHP кодом и возвращет массив с ошибками.
     * @param {boolean} isFix    Флаг, показывающий нужно ли исправлять найденные ошибки.
     * @param {object}  contents Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * @returns {Array<string>}
     */
    lint(isFix = false, contents) {
        let phpPaths = [];
        let errors = [];

        for (let type in contents) {
            if (contents.hasOwnProperty(type)) {
                Array.isArray(contents[type]) && contents[type].forEach(content => {
                    if (this.ext.includes(content.ext)) {
                        phpPaths.push(content.path);
                    }
                });
            }
        }

        if (phpPaths.length > 0) {
            try {
                let errors = execSync(`${isFix ? 'phpcbf' : 'phpcs'} --standard=PSR2 ${phpPaths.join(' ')}`, {
                    stdio: [
                        process.stdin,
                        process.stdout,
                        0 /* process.stderr */
                    ]
                }).toString();
                return [errors];
            } catch (e) {
                console.log('Неудалось проверить PHP код, т.к. в системе отсутствует команда phpcs или phpcbf.');
                return errors;
            }
        }

        return errors;
    }
}

module.exports = HandlerPhp;
