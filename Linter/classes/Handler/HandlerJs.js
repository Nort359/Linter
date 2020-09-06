const {CLIEngine} = require('eslint');
const fs = require('fs');
const chalk = require('chalk');

const Handler = require('./Handler');

class HandlerJs extends Handler {
    /**
     * Метод линтит переданные JS файлы и возвращет массив с ошибками.
     * @param {boolean} isFix    Флаг, показывающий нужно ли исправлять найденные ошибки.
     * @param {object}  contents Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * @param {object}  func     Дополнительные фунцкции.
     * Структура:
     * {
     *      имя_тега: [] - Массив с кодом всех тегов.
     * }
     * @return {Array<string>}
     */
    lint(isFix = false, contents, func) {
        const cli = new CLIEngine({
            envs: [
                'browser',
                'mocha'
            ],
            fix: isFix,
            useEslintrc: true
        });

        let globalErrorCount = 0;
        let errors = [];

        for (let type in contents) {
            if (contents.hasOwnProperty(type)) {
                Array.isArray(contents[type]) && contents[type].forEach(content => {
                    if (this.ext.includes(content.ext)) {
                        const report = cli.executeOnFiles(content.lintFile);

                        Array.isArray(report.results) && report.results.forEach(result => {
                            if (isFix === true) {
                                // Если свойства path и lintFile разные - значит имеем дело с тегом.
                                if (content.path !== content.lintFile && result.output) {
                                    // TODO: протестировать.
                                    if (typeof func.replace === 'function') {
                                        fs.writeFileSync(content.path, func.replace(content, result.output));
                                    }
                                } else if (result.output) {
                                    fs.writeFileSync(content.path, result.output);
                                }
                            }

                            if (result.errorCount !== 0) {
                                errors.push(`\nФайл ${chalk.green(content.path)}: обнаружено ${chalk.red(`${result.errorCount} и ${chalk.yellow(`${result.warningCount} предупреждений`)}`)}.`);
                            }

                            result.messages.forEach(message => {
                                errors.push(`\tСтрока: ${content.line + message.line}, Столбец: ${message.column}: ${chalk.red(message.ruleId)} ${message.message}`);
                                globalErrorCount++;
                            });

                            errors.push('\n-------------------------------------\n');
                        });
                    }
                });
            }
        }

        if (globalErrorCount !== 0) {
            errors.push(`Всего обнаружено ошибок: ${globalErrorCount}\n`);
        }

        return errors;
    }
}

module.exports = HandlerJs;
