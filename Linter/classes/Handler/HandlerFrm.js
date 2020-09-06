const fs = require('fs');
const libxml = require('libxmljs');
const chalk = require('chalk');

const Handler = require('./Handler');

class HandlerFrm extends Handler {
    constructor(ext = [], encoding = 'utf8') {
        super(ext, encoding);

        this.ext = ext;

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
                cmp: 'SubAction',
                extension: 'sql'
            },
            {
                cmp: 'DataSet',
                extension: 'sql'
            },
            {
                cmp: 'SubSelect',
                extension: 'sql'
            }
        ];

        this.contents = {};

        this.tags.forEach((tag) => {
            this.contents[tag.cmp] = [];
        });
    }

    /**
     * Возвращает выбранные компоненты для m2 и d3
     * @param {object} xmlDoc - xmlDoc
     * @param {string} cmp - Имя компонента
     * @returns {string}
     * @private
     */
    static _getXPathComponent(xmlDoc, cmp) {
        return cmp ? xmlDoc.find(`.//cmp${cmp}|.//component[@cmptype="${cmp}"]`) : '';
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
                if (str[i] && (/\S/).test(str[i])) {
                    position = i;
                    break;
                }
            }
        } else {
            for (let i = str.length; i >= 0; i--) {
                if (str[i] && (/\S/).test(str[i])) {
                    position = i;
                    break;
                }
            }
        }

        return position;
    }

    handle(paths, tempDir) {
        let fileContents = [];

        paths.forEach(path => {
            const ext = this._getExtByPath(path);

            if (this.ext.includes(ext)) {
                fileContents.push({
                    path: path,
                    content: fs.readFileSync(path, this.encoding),
                    isSubForm: false
                });
            }
        });

        const self = this;

        fileContents.forEach(file => {
            self.tags.forEach(tag => {
                const {cmp} = tag;
                const xmlDoc = libxml.parseXmlString(file.content);
                const nodes = HandlerFrm._getXPathComponent(xmlDoc, cmp);

                nodes.forEach(node => {
                    const nodeAttrName = node.attr('name');
                    const nodeName = nodeAttrName && nodeAttrName.value();

                    // Проверка саб компонентов у DataSet и Action
                    if (tag.extension === 'sql') {
                        ['SubAction', 'SubSelect'].forEach(subCmp => {
                            const subNodes = HandlerFrm._getXPathComponent(xmlDoc, subCmp);

                            subNodes.forEach((n) => {
                                n.remove();
                            });
                        });
                    }

                    if (node.text().trim() !== '') {
                        this._getContent(file, node, tag, nodeName);
                    }
                });
            });

            /*
             * Рекурсивно проходимся по всем сабформам.
             * Раскомментировать при необходимости линтить сабформы.
             * self._checkSubForms(file.content);
             */
        });

        this.writeToFile(tempDir);

        return this.contents;
    }

    /**
     * Private
     * Получает содержимое переданного тега в файле и помещает его в this.contents
     * @param {object} file      - Содержимое файла.
     * @param {object} node      - Содержимое тега.
     * @param {object} tag       - Объект, содерожащий имя тега и расширения для файла.
     * @param {string} nodeName  - Атрибут name на компоненте.
     * @private
     */
    _getContent(file, node, tag, nodeName) {
        const {path} = file; // Путь до проверяемого файла.
        const {isSubForm} = file; // Флаг-показатель, является ли файл сабформой.
        const cmp = tag.cmp;
        const line = node.line(); // Номер строки исходного файла, где был обнаружен текущий тег.
        const nodeText = node.text(); // Содержимое тега.

        const i = this.contents[cmp].length;

        this.contents[cmp].push({
            file,
            node,
            text: nodeText,
            cmp,
            name: nodeName,
            path,
            line: +line + 1,
            ext: tag.extension,
            isSubForm
        });

        if (this.contents[cmp][i].text) {
            let firstSymbolPosition = -1;

            // Убираем лишние пробелы перед каждой строкой.
            this.contents[cmp][i].text = this.contents[cmp][i].text.split('\n').map(line => {
                let currentFirstSymbolPosition = HandlerFrm.findLetterPosition(line);
                let cutPosition = firstSymbolPosition;

                // Находим позицию первого не пустого символа.
                if (firstSymbolPosition === -1) {
                    firstSymbolPosition = currentFirstSymbolPosition;
                    cutPosition = firstSymbolPosition;
                } else if (currentFirstSymbolPosition < firstSymbolPosition) {
                    cutPosition = currentFirstSymbolPosition
                }

                // Пропускаем пустые строки, а в не пустых убираем лишнее количество табов и пробелов.
                return line.trim() !== '' ? `${line.substr(cutPosition)}\n` : `${line}\n`;
            });

            if (Array.isArray(this.contents[cmp][i].text)) {
                this.contents[cmp][i].text = this.contents[cmp][i].text.join('');
            }

            // Обрезаем пустые символы и сиволы переноса строк в самом начале строки.
            this.contents[cmp][i].text = this.contents[cmp][i].text.substr(HandlerFrm.findLetterPosition(this.contents[cmp][i].text));
            // Обрезаем пустые символы и сиволы переноса строк в конце строки.
            const symbolsCount = this.contents[cmp][i].text.length - HandlerFrm.findLetterPosition(this.contents[cmp][i].text, false);

            this.contents[cmp][i].text = this.contents[cmp][i].text.substr(0, this.contents[cmp][i].text.length - symbolsCount + 1);
        }
    }

    /**
     * Private
     * Ищет все сабформы на форме и получает из них контент вызывая метод this.getContentTagsInFile.
     * @param {string} fileContents - Содержимое файла.
     * @private
     */
    _checkSubForms(fileContents) {
        const self = this;
        const subForms = HandlerFrm._getXPathComponent(libxml.parseXmlString(fileContents), 'SubForm');

        subForms.forEach(subForm => {
            const path = `Forms\/${subForm.attr('path').value()}.frm`;

            if (fs.existsSync(path)) {
                const subFormContent = [];

                subFormContent.push({
                    path,
                    content: fs.readFileSync(path, this.encoding),
                    isSubForm: true
                });
                self.handle(subFormContent);
            } else {
                console.error(`Не найдена сабформа ${chalk.red(path)}`);
            }
        });
    }

    /**
     * Проверяет является ли символ пустым символом.
     * @param {string} symbol - Символ, который необходимо проверить.
     * @return {boolean}      - true - не пустой, false - пустой.
     */
    static isLetter(symbol) {
        return symbol.toUpperCase() !== symbol.toLowerCase();
    }

    /**
     * Находит позицию первого не пустого символа.
     * @param {string} str - Строка, где необходимо производить поиск.
     * @return {number}    - Позиция первого не пустого символа.
     */
    static findFirstLetterPosition(str) {
        let position = -1;

        for (let j = 0; j <= str.length; j++) {
            if (str[j] && HandlerFrm.isLetter(str[j])) {
                position = j;
                break;
            }
        }

        return position;
    }

    /**
     * Записывает в файлы содержимое тегов.
     * @param {string} tempDir Название временной директории.
     * @param {object} contents Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * Структура:
     * {
     *      имя_тега: [] - Массив с кодом всех тегов.
     * }
     * @return {object<Handler>}
     */
    writeToFile(tempDir, contents = this.contents) {
        if (!fs.existsSync(tempDir)) {
            fs.mkdirSync(tempDir);
        }

        this.tags.forEach(tag => {
            const dir = tag.extension;
            const cmp = tag.cmp;
            const pathTag = `${tempDir}/${dir}/`;

            if (!fs.existsSync(pathTag)) {
                fs.mkdirSync(pathTag);
            }

            Array.isArray(contents[cmp]) && contents[cmp].forEach((content, index) => {
                const {name} = content;
                const newFilePath = `${pathTag}${`${cmp}__${name ? name : index}`}.${dir}`;

                fs.writeFileSync(newFilePath, content.text);
                this.contents[cmp][index].lintFile = newFilePath;
            });
        });

        return this;
    }

    /**
     * Заменяет содержимое тега на исправленный.
     * @param {object} content - Содержание всей формы.
     * @param {string} replaceText - Заменяемый текст.
     * @return {string}
     * @static
     */
    static replace(content, replaceText) {
        let nodeLines = content.node.text().split('\n');
        let spaces = '';
        let indentNodeText = 0;
        let output = replaceText;
        let nodeText = content.node.text();
        let documentRoot = content.file.content;

        nodeLines = nodeLines.map((line) => line.replace(/\t/g, '    '));

        // Определяем количество отступов в оригинальном тексте.
        for (let i = 0; i < nodeLines.length; i++) {
            const charPosition = HandlerFrm.findFirstLetterPosition(nodeLines[i]);

            if (charPosition > -1) {
                indentNodeText = charPosition;
                break;
            }
        }

        // Помещаем отступы из оригинального текста в переменную.
        for (let i = 0; i < indentNodeText; i++) {
            spaces += ' ';
        }

        // Добавляем отступы из оригинального текста в заменяемый текст
        output = output.split('\n').map(line => spaces + line);
        output = `${output.join('\n').trim()}`;

        const unixText = nodeText.trim(); // При переносе строки только \n
        let windowsText = unixText; // При переносе строки \r\n

        if (!nodeText.includes('\r\r')) {
            windowsText = nodeText.trim().replace(/\n/gim, '\r\n');
        }

        if (documentRoot.includes(unixText)) {
            documentRoot = documentRoot.replace(unixText, output);
        } else if (documentRoot.includes(windowsText)) {
            documentRoot = documentRoot.replace(windowsText, output);
        }

        documentRoot = documentRoot.replace(nodeText.trim().replace(/\n/gim, '\r\n'), output);

        return documentRoot;
    }

    /**
     * Производит проверку параметров привязанных к запросам.
     * @param {object} content - бъект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * @return {Array<string>}
     * @static
     */
    static checkSqlBindParams(content) {
        let messages = [];

        // const sqlTags = Array.isArray(sql) ? sql : [sql];
        let matchComments = [],
            matchUseVars = [],
            isError = false;

        let errorsCount = 0,
            warningsCount = 0,
            cmp = content.cmp,
            cmpSearch = cmp;

        switch (cmpSearch) {
            case 'SubAction': cmpSearch = 'Action'; break;
            case 'SubSelect': cmpSearch = 'DataSet'; break;
            default: break;
        }

        let vars = content.node.find(`./cmp${cmpSearch}Var|./component[@cmptype="${cmpSearch}Var"]|./component[@cmptype="Variable"]`);
        const regComments = new RegExp('\\/\\*.*\\*\\/|--.*|\'.*\'|".*"', 'gim'),
            regCheckUseVars = new RegExp(':\\w+', 'gim'),
            useVars = new Set(),
            bindVars = new Set(),
            errors = new Set(),
            warnings = new Set();

        if (cmp === 'SubSelect') {
            const subSelectName = content.node.attr('name').value(),
                xPathD3SubSelect = `.//cmp${cmp}[@name="${subSelectName}"]/../cmpDataSetVar`,
                xPathM2SubSelect = `.//component[@cmptype="${cmpSearch}"][@name="${subSelectName}"]/../component[@cmptype="DataSet"]/Variable`,
                xmlDoc = libxml.parseXmlString(content.file.content);

            vars = xmlDoc.find(xPathD3SubSelect + '|' + xPathM2SubSelect);
        }

        // Убираем комментарии из проверяемого текста, чтобы не захватить переменные из комментариев
        while ((matchComments = regComments.exec(content.text))) {
            content.text = content.text.replace(matchComments[0], '');
        }

        while ((matchUseVars = regCheckUseVars.exec(content.text))) {
            useVars.add(matchUseVars[0].substring(1));
        }

        vars.forEach((tagVar) => {
            const nameVar = tagVar.attr('name');

            // К запросу могут быть привязаны переменные без name, например: type="count". Такие переменные не рассматриваем.
            if (nameVar) {
                bindVars.add(nameVar.value());
            }
        });

        // Проверяем привязанные переменные по отношению к используемым в запросе
        bindVars.forEach(bindVar => {
            if (!useVars.has(bindVar) && content.text) {
                warningsCount++;
                warnings.add(`${warningsCount}: name="${chalk.yellow(bindVar)}"`);
                isError = true;
            }
        });

        if (warningsCount > 0) {
            messages.push(`${chalk.yellow('Warning')}: Файл: ${chalk.yellow(content.path)}. К компоненту ${cmp} на строке ${content.line
                } с именем ${chalk.green(content.name)} привязаны перменные, которые не используется в запросе:`);

            warnings.forEach(warning => {
                messages.push(warning);
            });
        }

        // Проверяем используемые переменные по отношению к привязанным к запросу
        useVars.forEach((useVar) => {
            if (!bindVars.has(useVar)) {
                errorsCount++;
                errors.add(`${errorsCount}: name="${chalk.red(useVar)}"`);
                isError = true;
            }
        });

        if (errorsCount > 0) {
            messages.push(`${chalk.red('Error')}: Файл: ${chalk.red(content.path)}. В компоненте ${cmp} на строке ${content.line
                } с именем ${chalk.green(content.name)} используется перменные, которые не привязаны к компоненту:`);

            errors.forEach((error) => {
                messages.push(error);
            });
        }

        if (warningsCount > 0 || errors > 0) {
            messages.push('\n-------------------------------------\n');
        }

        return messages;
    }

    lint() {
        return [];
    }
}

module.exports = HandlerFrm;
