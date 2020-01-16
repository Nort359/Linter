const fs = require('fs');
const path = require('path');
const chalk = require('chalk');
const libxml = require('libxmljs');
const CLIEngine = require("eslint").CLIEngine;

/**
 * class Linter
 */
class Linter {

    /**
     * @constructs Linter
     * @param {string|Array<string>} path - Путь до файла.
     * @param {string} encoding           - Кодировка файла.
     */
    constructor(path, encoding = 'utf8') {
        this.fileContents = [];

        if (path) {
            if (Array.isArray(path)) {
                path.forEach(p => {
                    this.fileContents.push({ path: p, content: fs.readFileSync(p, encoding) });
                });
            } else {
                this.fileContents.push({ path: path, content: fs.readFileSync(path, encoding) });
            }
        } else {
            this.paths = [];
            this.getFilePaths('.\\', 'frm', ['node_modules', '.git', '.idea', 'temp']);
            this.paths.forEach(p => {
                this.fileContents.push({ path: p, content: fs.readFileSync(p, encoding) });
            });
        }

        this.paths = [];

        this.encoding = encoding;
        this.tags = [
            {
                cmp: 'Script',
                extension: 'js'
            },
            {
                cmp: 'Action',
                extension: 'sql'
            },
            {
                cmp: 'DataSet',
                extension: 'sql'
            }
        ];

        this.contents = {};
        this.subforms = [];
    }

    /**
     * Метод рекурсивно прохоится по всем директориям в проекте и ищет файлы с заданными расширениеми.
     * @param {string|Array<string>} startPath          - Директория, в которой необходимо начать поиск.
     * @param {string|Array<string>} filter             - Расширения файлов, которые необходимо найти.
     * @param {string|Array<string>|null} exceptionPath - Пути до директорий, которые необходимо пропустить при поиске.
     */
    getFilePaths(startPath, filter, exceptionPath = null) {
        const self = this;

        if (!Array.isArray(exceptionPath)) {
            exceptionPath = [exceptionPath];
        }

        if (!~exceptionPath.indexOf(startPath)) {
            if (!fs.existsSync(startPath)) return;

            const files = fs.readdirSync(startPath);

            files.forEach(file => {
                const filename = path.join(startPath, file);
                const stat = fs.lstatSync(filename);

                if (stat.isDirectory()) {
                    self.getFilePaths(filename, filter); // recurse
                } else if (filename.indexOf(filter) >= 0) {
                    self.paths.push(filename);
                }
            });
        }

        return this.paths;
    }

    /**
     * Находит позицию не пустого символа.
     * @param {string}  str       - Строка, где необходимо производить поиск.
     * @param {boolean} fromBegin - true - начинать поиск с начала строки, fakse - с конца.
     * @return {number}           - Позиция первого не пустого символа.
     */
    static findLetterPosition(str, fromBegin = true) {
        let position = -1;

        if (fromBegin) {
            for (let i = 0; i <= str.length; i++) {
                if (str[i] && /\S/.test(str[i])) {
                    position = i;
                    break;
                }
            }
        } else {
            for (let i = str.length; i >= 0; i--) {
                if (str[i] && /\S/.test(str[i])) {
                    position = i;
                    break;
                }
            }
        }

        return position;
    }

    /**
     * private
     * Получает содержимое переданного тега в файле и помещает его в this.contents
     * @param {string} node     - Содержимое тега.
     * @param {string} cmp      - Имя тега.
     * @param {string} nodeName - Атрибут name на компоненте.
     * @param {number} line     - Номер строки исходного файла, где был обнаружен текущий тег.
     * @param {string} path     - Путь до проверяемого файла.
     */
    _getContent(node, cmp, nodeName, line, path) {
        if (!Array.isArray(this.contents[cmp])) {
            this.contents[cmp] = [];
        }

        let i = this.contents[cmp].length;

        this.contents[cmp].push({ text: node, name: nodeName, path: path, line: line });

        if (this.contents[cmp][i].text) {
            let firstSymbolPosition = -1;
            
            // Убираем лишние пробелы перед каждой строкой.
            this.contents[cmp][i].text = this.contents[cmp][i].text.split('\n').map(line => {
                // Находим позицию первого не пустого символа.
                if (firstSymbolPosition === -1) {
                    firstSymbolPosition = Linter.findLetterPosition(line);
                }

                // Пропускаем пустые строки, а в не пустых убираем лишнее количество табов и пробелов.
                return line = line.trim() !== '' ? line.substr(firstSymbolPosition) + '\n' : line + '\n';
            });

            if (Array.isArray(this.contents[cmp][i].text)) {
                this.contents[cmp][i].text = this.contents[cmp][i].text.join('');
            }

            // Обрезаем пустые символы и сиволы переноса строк в самом начале строки.
            this.contents[cmp][i].text = this.contents[cmp][i].text.substr(Linter.findLetterPosition(this.contents[cmp][i].text));
            // Обрезаем пустые символы и сиволы переноса строк в конце строки.
            var symbolsCount = this.contents[cmp][i].text.length - Linter.findLetterPosition(this.contents[cmp][i].text, false);
            this.contents[cmp][i].text = this.contents[cmp][i].text.substr(0, this.contents[cmp][i].text.length - symbolsCount + 1);
        }
    }

    /**
     * private
     * Ищет все сабформы на форме и получает из них контент вызывая метод this.getContentTagsInFile.
     * @param {string} fileContents - Содержимое файла.
     */
    _checkSubForms(fileContents) {
        const self = this;
        const cmp = 'SubForm';
        const xmlDoc = libxml.parseXmlString(fileContents);
        const d3SubForm = xmlDoc.find(`./cmp${cmp}`);
        const m2SubForm = xmlDoc.find(`./component[@cmptype="${cmp}"]`);
        this.subForms = d3SubForm.concat(m2SubForm);

        this.subForms.forEach(subForm => {
            const path = `${subForm.attr('path').value()}.frm`;

            if (fs.existsSync(path)) {
                const subFormFileContents = fs.readFileSync(path, this.encoding);
                self.getContentTagsInFile(subFormFileContents);
            } else {
                console.error('Не найдена сабформа ' + chalk.red(path));
            }
        });
    }

    /**
     * Возвращает контент для каждого тега в переданном файле. 
     * @param {string|Array<string>} fileContents - Содержимое файла.
     * @return {object}                           - Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * Структура:
     * {
     *      имя_тега: [] - Массив с кодом всех тегов.
     * }
     */
    getContentTagsInFile(fileContents = this.fileContents) {
        const self = this;

        if (!Array.isArray(fileContents)) {
            fileContents = [fileContents];
        }

        fileContents.forEach(file => {
            self.tags.forEach(tag => {
                const cmp = tag.cmp;
                const xmlDoc = libxml.parseXmlString(file.content);
                const d3Nodes = xmlDoc.find(`.//cmp${cmp}`);
                const m2Nodes = xmlDoc.find(`.//component[@cmptype="${cmp}"]`);
                const nodes = d3Nodes.concat(m2Nodes);

                nodes.forEach(node => {
                    const nodeAttrName = node.attr('name');
                    const line = node.line();
                    const nodeName = nodeAttrName && nodeAttrName.value();

                    if (cmp !== 'Action') {
                        // TODO: Сделать реализацию для сабэкшинов
                        self._getContent(node.text(), cmp, nodeName, line, file.path);
                    } else {
                        self._getContent(node.text(), cmp, nodeName, line, file.path);
                    }
                });
            });

            // Рекурсивно проходимся по всем сабформам.
            self._checkSubForms(file.content);
        });

        return self;
    }

    /**
     * Записывает в файлы содержимое тегов.
     * @param {object} contents - Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * Структура:
     * {
     *      имя_тега: [] - Массив с кодом всех тегов.
     * }
     */
    writeToFile(contents = this.contents) {
        const pathTemp = `temp/`;

        if (!fs.existsSync(pathTemp)) {
            fs.mkdirSync(pathTemp);
        }

        this.tags.forEach(tag => {
            const dir = tag.extension;
            const cmp = tag.cmp;
            const pathTag = `${pathTemp}/${dir}/`;

            if (!fs.existsSync(pathTag)) {
                fs.mkdirSync(pathTag);
            }

            Array.isArray(contents[cmp]) && contents[cmp].forEach((content, index) => {
                const name = content.name;
                const newFilePath = `${pathTag}/${cmp + '__' + (name ? name : index)}.${dir}`;
                fs.writeFileSync(newFilePath, content.text);
                this.contents[cmp][index].lintFile = newFilePath;
            });
        });

        return this;
    }

    /**
     * Метод линтит переданные JS файлы и выводит найденные ошибки в консоль.
     * @param {object} contents - Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * Структура:
     * {
     *      имя_тега: [] - Массив с кодом всех тегов.
     * }
     */
    lintJS(contents = this.contents) {
        const cli = new CLIEngine({
            envs: ['browser', 'mocha'],
            fix: false,
            useEslintrc: true
        });

        Array.isArray(contents['Script']) && contents['Script'].forEach(content => {
            const report = cli.executeOnFiles(content.lintFile);

            report.results.forEach(function(result) {
                const fileName = result.filePath.split('\\');

                console.log('\nФайл: ' + chalk.green(content.path) + ', имя скрипта: ' + chalk.green(content.name ? content.name : '[Атрибут \'name\' у тега \'Script\' отсутсвует]') + '.');
                console.log('Найдено ' + chalk.red(result.errorCount  + ' ошибок') + ' и ' + chalk.yellow(result.warningCount + ' предупреждений') + '.\n');

                result.messages.forEach(function(message) {
                    console.log('Строка: ' + (content.line + message.line + 1) + ', Столбец: ' + message.column + ': ' + chalk.red(message.ruleId) + ' ' + message.message);
                });

                console.log('\n-------------------------------------\n');
            });
        });

        return this;
    }

    deleteTempFiles(path = 'temp/') {
        const self = this;

        if (fs.existsSync(path)) {
            fs.readdirSync(path).forEach((file, index) => {
                const curPath = path + '/' + file;
                if (fs.lstatSync(curPath).isDirectory()) { // recurse
                    self.deleteTempFiles(curPath);
                } else { // delete file
                    fs.unlinkSync(curPath);
                }
            });

            fs.rmdirSync(path);
        }

        return this;
    }
}

module.exports = Linter;
