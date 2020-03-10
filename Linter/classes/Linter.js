const fs = require('fs');
const path = require('path');
const chalk = require('chalk');
const libxml = require('libxmljs'),
    {CLIEngine} = require('eslint');

/**
 * Class Linter
 */
class Linter {
    /**
     * @constructs Linter
     * @param {string|Array<string>} filePath - Путь до файла.
     * @param {string} startPath              - Путь, откуда начинать поиск в случае, если массив с путями до файлов не передан.
     * @param {string} encoding           - Кодировка файла.
     */
    constructor(filePath, startPath, encoding = 'utf8') {
        this.paths = [];
        this.encoding = encoding;
        this.fileContents = [];
        this.pathTemp = 'tempLint';
        this.checkExt = [
            'frm',
            'dfrm',
            'php',
            'mdl',
            'inc'
        ];
        this.phpExtensions = [
            'inc',
            'mdl',
            'php'
        ];
        this.phpPaths = [];
        this.jsPaths = [];

        if (filePath) {
            this.paths = !Array.isArray(filePath) ? [filePath] : filePath;
        } else {
            this.getFilePaths(startPath, this.checkExt, [
                'node_modules',
                '.git',
                '.idea',
                'temp',
                'external'
            ]);
        }

        for (let i = 0; i < this.paths.length; i++) {
            let ext = this.paths[i].split('.'),
                fileName = this.paths[i].split('/');

            fileName = fileName.length > 1 ? fileName : this.paths[i].split('\\');
            fileName = fileName[fileName.length - 1];
            ext = ext[ext.length - 1];

            // Закидываем файлы с php кодом в отдельный массив.
            if (~this.phpExtensions.indexOf(ext)) {
                this.phpPaths.push(this.paths[i]);
            }

            if (ext === 'js') {
                const jsTempPath = `${this.pathTemp}/js/${fileName}`;

                if (!fs.existsSync(this.pathTemp)) {
                    fs.mkdirSync(this.pathTemp);
                    fs.mkdirSync(`${this.pathTemp}/js/`);
                }

                if (fs.existsSync(this.paths[i])) {
                    fs.writeFileSync(jsTempPath, fs.readFileSync(this.paths[i], 'utf-8'));
                    this.jsPaths.push({
                        name: fileName,
                        path: this.paths[i],
                        lintFile: jsTempPath,
                        line: 0
                    });
                }
            }

            if (ext !== 'frm') {
                continue;
            }

            this.fileContents.push({
                path: this.paths[i],
                content: fs.readFileSync(this.paths[i], encoding),
                isSubForm: false
            });
        }

        this.paths = [];
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
            if (str[j] && Linter.isLetter(str[j])) {
                position = j;
                break;
            }
        }

        return position;
    }

    /**
     * Метод рекурсивно прохоится по всем директориям в проекте и ищет файлы с заданными расширениеми.
     * @param {string|Array<string>} startPath          - Директория, в которой необходимо начать поиск.
     * @param {string|Array<string>} filters            - Расширения файлов, которые необходимо найти.
     * @param {string|Array<string>|null} exceptionPath - Пути до директорий, которые необходимо пропустить при поиске.
     */
    getFilePaths(startPath, filters, exceptionPath = null) {
        const self = this;

        if (!Array.isArray(exceptionPath)) {
            exceptionPath = [exceptionPath];
        }

        if (!~exceptionPath.indexOf(startPath)) {
            if (!fs.existsSync(startPath)) {
                return;
            }

            const files = fs.readdirSync(startPath);

            files.forEach((file) => {
                const fileName = path.join(startPath, file),
                    stat = fs.lstatSync(fileName);

                if (stat.isDirectory()) {
                    self.getFilePaths(fileName, filters); // Recurse
                } else {
                    filters.forEach((filter) => {
                        if (fileName.includes(`.${filter}`)) {
                            self.paths.push(fileName);
                        }
                    });
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

    /**
     * Private
     * Получает содержимое переданного тега в файле и помещает его в this.contents
     * @param {object} file      - Содержимое файла.
     * @param {object} node      - Содержимое тега.
     * @param {string} cmp       - Имя тега.
     * @param {string} nodeName  - Атрибут name на компоненте.
     */
    _getContent(file, node, cmp, nodeName) {
        const {path} = file, // Путь до проверяемого файла.
            {isSubForm} = file, // Флаг-показатель, является ли файл сабформой.
            line = node.line(), // Номер строки исходного файла, где был обнаружен текущий тег.
            nodeText = node.text(); // Содержимое тега.

        if (!Array.isArray(this.contents[cmp])) {
            this.contents[cmp] = [];
        }

        const i = this.contents[cmp].length;

        this.contents[cmp].push({
            file,
            node,
            text: nodeText,
            cmp,
            name: nodeName,
            path,
            line,
            isSubForm
        });

        if (this.contents[cmp][i].text) {
            let firstSymbolPosition = -1;
            
            // Убираем лишние пробелы перед каждой строкой.
            this.contents[cmp][i].text = this.contents[cmp][i].text.split('\n').map((line) => {
                // Находим позицию первого не пустого символа.
                if (firstSymbolPosition === -1) {
                    firstSymbolPosition = Linter.findLetterPosition(line);
                }

                line = line.replace(/\t/g, '    '); // Заменяем таб на 4 пробела.

                // Пропускаем пустые строки, а в не пустых убираем лишнее количество табов и пробелов.
                return line.trim() !== '' ? `${line.substr(firstSymbolPosition)}\n` : `${line}\n`;
            });

            if (Array.isArray(this.contents[cmp][i].text)) {
                this.contents[cmp][i].text = this.contents[cmp][i].text.join('');
            }

            // Обрезаем пустые символы и сиволы переноса строк в самом начале строки.
            this.contents[cmp][i].text = this.contents[cmp][i].text.substr(Linter.findLetterPosition(this.contents[cmp][i].text));
            // Обрезаем пустые символы и сиволы переноса строк в конце строки.
            const symbolsCount = this.contents[cmp][i].text.length - Linter.findLetterPosition(this.contents[cmp][i].text, false);

            this.contents[cmp][i].text = this.contents[cmp][i].text.substr(0, this.contents[cmp][i].text.length - symbolsCount + 1);
        }
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
     * Private
     * Ищет все сабформы на форме и получает из них контент вызывая метод this.getContentTagsInFile.
     * @param {string} fileContents - Содержимое файла.
     */
    _checkSubForms(fileContents) {
        const self = this,
            subForms = Linter._getXPathComponent(libxml.parseXmlString(fileContents), 'SubForm');

        subForms.forEach((subForm) => {
            const path = `Forms\/${subForm.attr('path').value()}.frm`;

            if (fs.existsSync(path)) {
                const subFormContent = [];

                subFormContent.push({path,
                    content: fs.readFileSync(path, this.encoding),
                    isSubForm: true});
                self.getContentTagsInFile(subFormContent);
            } else {
                console.error(`Не найдена сабформа ${chalk.red(path)}`);
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
     * @return {object<Linter>}
     */
    getContentTagsInFile(fileContents = this.fileContents) {
        const self = this;

        if (!Array.isArray(fileContents)) {
            fileContents = [fileContents];
        }

        fileContents.forEach((file) => {
            self.tags.forEach((tag) => {
                const {cmp} = tag,
                    xmlDoc = libxml.parseXmlString(file.content),
                    nodes = Linter._getXPathComponent(xmlDoc, cmp);

                nodes.forEach((node) => {
                    const nodeAttrName = node.attr('name'),
                        nodeName = nodeAttrName && nodeAttrName.value();

                    if (tag.extension === 'sql') {
                        [
                            'SubAction',
                            'SubSelect'
                        ].forEach((subCmp) => {
                            const subNodes = Linter._getXPathComponent(xmlDoc, subCmp);

                            subNodes.forEach((n) => {
                                n.remove();
                            });
                        });
                    }

                    if (node.text().trim() !== '') {
                        self._getContent(file, node, cmp, nodeName);
                    }
                });
            });

            /*
             * Рекурсивно проходимся по всем сабформам.
             * Раскомментировать при необходимости линтить сабформы.
             * self._checkSubForms(file.content);
             */
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
     * @return {object<Linter>}
     */
    writeToFile(contents = this.contents) {
        if (!fs.existsSync(this.pathTemp)) {
            fs.mkdirSync(this.pathTemp);
        }

        this.tags.forEach((tag) => {
            const dir = tag.extension,
                {cmp} = tag,
                pathTag = `${this.pathTemp}/${dir}/`;

            if (!fs.existsSync(pathTag)) {
                fs.mkdirSync(pathTag);
            }

            Array.isArray(contents[cmp]) && contents[cmp].forEach((content, index) => {
                const {name} = content,
                    newFilePath = `${pathTag}${`${cmp}__${name ? name : index}`}.${dir}`;

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
     */
    replaceFixedTag(content, replaceText) {
        const nodeLines = content.node.text().split('\n');
        let spaces = '',
            indentNodeText = 0,
            output = replaceText,
            nodeText = content.node.text(),
            documentRoot = content.file.content;

        // Определяем количество отступов в оригинальном тексте.
        for (let i = 0; i < nodeLines.length; i++) {
            const charPosition = Linter.findFirstLetterPosition(nodeLines[i]);

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
        output = output.split('\n').map((line) => spaces + line);
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
     * Метод линтит переданные JS файлы и выводит найденные ошибки в консоль.
     * @param {boolean} isFix - Флаг, показывающий нужно ли исправлять найденные ошибки.
     * @param {object} contents - Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * Структура:
     * {
     *      имя_тега: [] - Массив с кодом всех тегов.
     * }
     * @return {object<Linter>}
     */
    lintJS(isFix = false, contents = this.contents) {
        console.log('\n\n================================= JavaScript =================================\n\n');

        const self = this,
            cli = new CLIEngine({
                envs: [
                    'browser',
                    'mocha'
                ],
                fix: isFix,
                useEslintrc: true
            });

        let globalErrorCount = 0;

        contents['Script'] = contents['Script'].concat(this.jsPaths);

        Array.isArray(contents['Script']) && contents['Script'].forEach((content) => {
            const report = cli.executeOnFiles(content.lintFile);

            report.results.forEach(function(result) {
                // Если существует значение у content.cmp - значит имеем дело с тегом.
                if (content.cmp && result.output) {
                    fs.writeFileSync(content.path, self.replaceFixedTag(content, result.output));
                } else if (result.output) {
                    fs.writeFileSync(content.path, result.output);
                }

                console.log(`\nФайл${content.isSubForm ? ' (Сабформа)' : ''}: ${chalk.green(content.path)
                }${content.line !== 0 ? `, тег '${content.cmp}' на строке: ${chalk.green(content.line)}` : ''
                }, имя скрипта: ${chalk.green(content.name ? content.name : '[Атрибут \'name\' у тега \'Script\' отсутсвует]')}.`);

                if (result.errorCount === 0) {
                    console.log(chalk.green('+ Замечаний к файлу нет.'));
                } else {
                    console.log(`Найдено ${chalk.red(`${result.errorCount} ошибок`)} и ${chalk.yellow(`${result.warningCount} предупреждений`)}.\n`);
                }

                result.messages.forEach(function(message) {
                    console.log(`Строка: ${content.line + message.line + 1}, Столбец: ${message.column}: ${chalk.red(message.ruleId)} ${message.message}`);
                    globalErrorCount++;
                });

                console.log('\n-------------------------------------\n');
            });
        });

        if (globalErrorCount === 0) {
            console.log('Ошибки не обнаружены\n');
        } else {
            console.log(`Всего обнаружено ошибок: ${globalErrorCount}\n`);
        }

        return this;
    }

    /**
     * Производит проверку параметров привязанных к запросам.
     * @param {array} sql - Массив всех собранных sql запросов.
     * @return {object<Linter>}
     */
    _checkUseSqlParams(sql) {
        console.log('*** Проверка переданных/используемых параметров ***\n');

        const sqlTags = Array.isArray(sql) ? sql : [sql];
        let matchComments = [],
            matchUseVars = [],
            isError = false;

        sqlTags.forEach((sqlTag) => {
            let errorsCount = 0,
                warningsCount = 0,
                {cmp} = sqlTag,
                cmpSearch = cmp;

            switch (cmpSearch) {
                case 'SubAction': cmpSearch = 'Action'; break;
                case 'SubSelect': cmpSearch = 'DataSet'; break;
            }

            let vars = sqlTag.node.find(`./cmp${cmpSearch}Var|./component[@cmptype="${cmpSearch}Var"]|./component[@cmptype="Variable"]`);
            const regComments = new RegExp('\\/\\*.*\\*\\/|--.*|\'.*\'|".*"', 'gim'),
                regCheckUseVars = new RegExp(':\\w+', 'gim'),
                useVars = new Set(),
                bindVars = new Set(),
                errors = new Set(),
                warnings = new Set();

            if (cmp === 'SubSelect') {
                const subSelectName = sqlTag.node.attr('name').value();
                const xPathD3SubSelect = `.//cmp${cmp}[@name="${subSelectName}"]/../cmpDataSetVar`;
                const xPathM2SubSelect = `.//component[@cmptype="${cmpSearch}"][@name="${subSelectName}"]/../component[@cmptype="DataSet"]/Variable`;
                const xmlDoc = libxml.parseXmlString(sqlTag.file.content);

                vars = xmlDoc.find(xPathD3SubSelect + '|' + xPathM2SubSelect);
            }

            // Убираем комментарии из проверяемого текста, чтобы не захватить переменные из комментариев
            while (matchComments = regComments.exec(sqlTag.text)) {
                sqlTag.text = sqlTag.text.replace(matchComments[0], '');
            }

            while (matchUseVars = regCheckUseVars.exec(sqlTag.text)) {
                useVars.add(matchUseVars[0].substring(1));
            }

            vars.forEach((tagVar) => {
                const nameVar = tagVar.attr('name');

                bindVars.add(nameVar && nameVar.value());
            });

            // Проверяем привязанные переменные по отношению к используемым в запросе
            bindVars.forEach((bindVar) => {
                if (!useVars.has(bindVar) && sqlTag.text) {
                    warningsCount++;
                    warnings.add(`${warningsCount}: name="${chalk.yellow(bindVar)}"`);
                    isError = true;
                }
            });

            if (warningsCount > 0) {
                console.log(`${chalk.yellow('Warning')}: Файл: ${chalk.yellow(sqlTag.path)}. К компоненту ${cmp} с именем ${sqlTag.name
                } на строке ${sqlTag.line} привязаны перменные, которые не используется в запросе:`);

                warnings.forEach((warning) => {
                    console.log(warning);
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
                console.log(`${chalk.red('Error')}: Файл: ${chalk.red(sqlTag.path)}. В компоненте ${cmp} с именем ${sqlTag.name
                } на строке ${sqlTag.line} используется перменные, которые не привязаны к компоненту:`);

                errors.forEach((error) => {
                    console.log(error);
                });
            }

            if (warningsCount > 0 || errors > 0) {
                console.log('\n-------------------------------------\n');
            }
        });

        if (!isError) {
            console.log(chalk.green('Ошибок с переменными запроса не обнаружено'));
        }

        console.log('\n*** Проверка переданных/используемых параметров завершена ***\n\n');

        return this;
    }

    /**
     * Метод линтит все sql файлы на предмет использование таблиц в запросе
     * и выводит ошибки в консоль если совпадения были найдены.
     * @param {boolean} isFix - Флаг, показывающий нужно ли исправлять найденные ошибки.
     * @param {object} sql - Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * @return {object<Linter>}
     */
    _checkTables(isFix = false, sql) {
        console.log('*** Проверка использования таблиц ***\n');

        let match = [],
            globalErrors = 0;
        const sqlTags = sql,
            regex = new RegExp('(^|FROM|JOIN)\\s+D_(?!PKG|CL_|V_|C_|P_|STR|TP_|F_)\\S+', 'gim');

        sqlTags.forEach((sqlTag) => {
            const sqlFile = fs.readFileSync(sqlTag.lintFile, this.encoding);
            let errors = 0;

            while (match = regex.exec(sqlFile)) {
                errors++;

                const sqlLines = match.input.split('\n'),
                    strMatches = match[0].split(' '),
                    tableName = strMatches && strMatches[strMatches.length - 1];
                let lineError = 0;

                if (sqlLines) {
                    for (let i = 0; i < sqlLines.length; i++) {
                        if (sqlLines[i].includes(match[0])) {
                            lineError = i;
                            break;
                        }
                    }
                }

                console.log(`Файл: ${chalk.green(sqlTag.path)}. Найдено использование таблицы ${chalk.red(tableName)} в запросе компонента ` +
                    `${sqlTag.cmp} с именем ${chalk.green(sqlTag.name)}, на строке: ${lineError + sqlTag.line + 1}`);

                errors++;
            }

            globalErrors += errors;
        });

        if (globalErrors === 0) {
            console.log(chalk.green('+ Использование таблиц в файле не обнаружено'));
        }

        console.log('\n*** Проверка использования таблиц завершено ***\n\n');

        return this;
    }

    /**
     * Метод линтит переданные SQL файлы и выводит найденные ошибки в консоль.
     * @param {boolean} isFix - Флаг, показывающий нужно ли исправлять найденные ошибки.
     * @param {object} contents - Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * Структура:
     * {
     *      имя_тега: [] - Массив с кодом всех тегов.
     * }
     * @return {object<Linter>}
     */
    lintSQL(isFix = false, contents = this.contents) {
        console.log('\n\n================================= SQL =================================\n\n');

        let sql = [];

        // Помещаем все теги
        this.tags.forEach((tag) => {
            if (tag.extension === 'sql') {
                sql = sql.concat(contents[tag.cmp]);
            }
        });

        this._checkUseSqlParams(sql).
            _checkTables(isFix, sql);

        return this;
    }

    /**
     * Линтит php файлы, с PHP кодом.
     * @param {function} execFunc - Функция, для выполнения команды линтинга файлов в консоли
     * @param {boolean} isFix - Флаг, показывающий нужно ли исправлять найденные ошибки.
     * @returns {Promise<any>}
     */
    lintPHPFiles(execFunc, isFix = false) {
        return new Promise((resolve, reject) => {
            if (typeof execFunc === 'function') {
                if (this.phpPaths.length > 0) {
                    execFunc(`${isFix ? 'phpcbf' : 'phpcs'} --standard=PSR2 ${this.phpPaths.join(' ')}`, (err, stdout) => {
                        console.log(stdout);
                        resolve();
                    });
                } else {
                    resolve();
                }
            } else {
                reject('Передана некорректная exec функция.');
            }
        });
    }

    /**
     * Удаляет временные файлы, созданные для выполнения линтинга.
     * @param {string} path - Путь, по которому будут удаляться временные файлы.
     * @return {object<Linter>}
     */
    deleteTempFiles(path = this.pathTemp) {
        const self = this;

        if (fs.existsSync(path)) {
            fs.readdirSync(path).forEach((file) => {
                const curPath = `${path}/${file}`;

                if (fs.lstatSync(curPath).isDirectory()) { // Recurse
                    self.deleteTempFiles(curPath);
                } else { // Delete file
                    fs.unlinkSync(curPath);
                }
            });

            fs.rmdirSync(path);
        }

        return this;
    }
}

module.exports = Linter;