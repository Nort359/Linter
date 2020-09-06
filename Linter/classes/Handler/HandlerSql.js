const fs = require('fs');
const chalk = require('chalk');

const Handler = require('./Handler');

class HandlerSql extends Handler {
    /**
     * Метод линтит переданные SQL скрипты и возвращет массив с ошибками.
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
        let errors = [];

        for (let type in contents) {
            if (contents.hasOwnProperty(type)) {
                Array.isArray(contents[type]) && contents[type].forEach(content => {
                    if (this.ext.includes(content.ext)) {
                        let checkFunc = [
                            content.text ? this._checkSql.bind(this, new RegExp('(^|FROM|JOIN)\\s+D_(?!PKG|CL_|V_|C_|P_|STR|TP_|F_)\\S+', 'gim'), content, this._checkTables) : null,
                            this._checkSql.bind(this, new RegExp('(^|\\s)(WHERE|AND|OR|NOT)\\s+[^\\s]+\\s+IN($|\\s+)[^(\\s]{1}', 'gim'), content, this._checkInOperatorWithoutBrackets),
                            this._checkSql.bind(this, new RegExp('(^|\\s)\\*\\*($|\\s)', 'gim'), content, this._checkPowInvalidFormat),
                            this._checkSql.bind(this, new RegExp('(^|\\s)MOD($|\\s)', 'gim'), content, this._checkModInvalidFormat),
                            this._checkSql.bind(this, new RegExp('(^|\\s)DECLARE($|\\s+)BEGIN($|\\s)', 'gim'), content, this._checkEmptyDeclare),
                            this._checkSql.bind(this, new RegExp('(^|\\s)MULTISET($|\\s+)UNION($|\\s)', 'gim'), content, this._checkMultisetUnion),
                            this._checkSql.bind(this, new RegExp('\\(\\s*TABLE(\\s+|\\()', 'gim'), content, this._checkTableInBrackets),
                            this._checkSql.bind(this, new RegExp('(^|\\s)CREATE\\s+OR\\s+REPLACE\\s+VIEW\\s+(\\"[^"]+\\"|[a-zа-я]{1}[a-zа-я0-9_$#]*)\\s+as', 'gim'), content, this._checkViewCreateWithoutFieldsList),
                            this._checkSql.bind(this, new RegExp('(^|\\s)FUNCTION\\s+(\\"[^"]+\\"|[a-zа-я]{1}[a-zа-я0-9_$#]*)\\s*\\([^)]+(\\"[^"]+\\"|[a-zа-я]{1}[a-zа-я0-9_$#]*)\\s+out\\s{1}', 'gim'), content, this._checkOutParamsInFunctions),
                            this._checkSql.bind(this, new RegExp('(^|\\s)(FUNCTION|PROCEDURE)\\s+(\\"[^"]+\\"|[a-zа-я]{1}[a-zа-я0-9_$#]*)\\s*\\((\\s*(\\"[^"]+\\"|[a-zа-я]{1}[a-zа-я0-9_$#]*)\\s+((IN\\s+OUT|IN|OUT)\\s+)?(\\"[^"]+\\"|[a-zа-я]{1}[a-zа-я0-9_$#]*(\\([a-zа-я0-9_$#]*\\))*\\s*)((DEFAULT|:=)\\s+[^,()]+\\s*)*\\,(\\s*--[^\\n]*\\n)*){99}', 'gim'), content, this._checkParamsNumber),
                            this._checkSql.bind(this, new RegExp('(^|\\s)DECLARE\\s+((((?!(;)).)*;\\s*)*(PROCEDURE|FUNCTION)(\\(|\\s)|((((?!(( |	)BFILE( |	|;)|( |	)BLOB( |	|;)|( |	)NCLOB( |	|;)|( |	)CLOB( |	|;)|( |	)ROWID( |	|;)|( |	)LONG( |	|;)|( |	)DATE( |	|;)|( |	)INTERVAL( |	|;)|( |	)BINARY_FLOAT( |	|;)|( |	)BINARY_DOUBLE( |	|;)|( |	)NCHAR|( |	)CHAR|( |	)UROWID|( |	)RAW|( |	)TIMESTAMP|( |	)FLOAT|( |	)NUMBER|( |	)NVARCHAR2|( |	)VARCHAR2)).)*;)|((((?!(;)).)*;\\s*)*(((?!(( |	)BFILE( |	|;)|( |	)BLOB( |	|;)|( |	)NCLOB( |	|;)|( |	)CLOB( |	|;)|( |	)ROWID( |	|;)|( |	)LONG( |	|;)|( |	)DATE( |	|;)|( |	)INTERVAL( |	|;)|( |	)BINARY_FLOAT( |	|;)|( |	)BINARY_DOUBLE( |	|;)|( |	)NCHAR|( |	)CHAR|( |	)UROWID|( |	)RAW|( |	)TIMESTAMP|( |	)FLOAT|( |	)NUMBER|( |	)NVARCHAR2|( |	)VARCHAR2)).)*;))))', 'gim'), content, this._checkDeclareWithCustomTypesOrFunctionsOrProcedures),
                            // На простых примерах работает, но когда много текста очень долго ищет совпадения
                            //this._checkSql.bind(this, new RegExp('(^|\\s)((FUNCTION|PROCEDURE)\\s+(\\"[^"]+\\"|[a-zа-я]{1}[a-zа-я0-9_$#]*)(\\s+AS|\\s+IS|\\s+RETURN|\\s*\\((\\s*(\\"[^"]+\\"|[a-zа-я]{1}[a-zа-я0-9_$#]*)\\s+((IN\\s+OUT|IN|OUT)\\s+)?(\\"[^"]+\\"|[a-zа-я]{1}[a-zа-я0-9_$#]*(\\([a-zа-я0-9_$#]*\\))*\\s*)((DEFAULT|:=)\\s+[^,()]+\\s*)*\\,?(\\s*--[^\\n]*\\n)*\\s*)*\\s*\\)(\\s+RETURN\\s+(?!(IS|AS))(\\"[^"]+\\"|[a-zа-я]{1}[a-zа-я0-9_$#]*(\\([a-zа-я0-9_$#]*\\))*\\s*))*(\\s+AS|\\s+IS))\\s+(\\s*(?!(BEGIN|FUNCTION|PROCEDURE))[a-zа-я]{1}[a-zа-я0-9_$#]*\\s+[a-zа-я]{1}[a-zа-я0-9_$#]*(\\([a-zа-я0-9_$#]*\\))*\\s*[^;]*;)*\\s*){3}\\s*(BEGIN|FUNCTION|PROCEDURE)', 'gim'), content, this._checkNestedInNestedFuncsAndProcs),
                            this._checkSimilarFunctionsAndProcedures.bind(this, new RegExp('(^|\\s)(FUNCTION|PROCEDURE)\\s+(\\"[^"]+\\"|[a-zа-я]{1}[a-zа-я0-9_$#]*)(\\s+AS|\\s+IS|\\s+RETURN|\\s*\\((\\s*(\\"[^"]+\\"|[a-zа-я]{1}[a-zа-я0-9_$#]*)\\s+((IN\\s+OUT|IN|OUT)\\s+)?(\\"[^"]+\\"|[a-zа-я]{1}[a-zа-я0-9_$#]*(\\([a-zа-я0-9_$#]*\\))*\\s*)((DEFAULT|:=)\\s+[^,()]+\\s*)*\\,?(\\s*--[^\\n]*\\n)*\\s*)*\\s*\\))', 'gim'), content),
                        ];

                        checkFunc.forEach(func => {
                            if (typeof func === 'function') {
                                errors = errors.concat(func());
                            }
                        });

                        // Если свойства path и lintFile разные - значит имеем дело с тегом.
                        if (content.path !== content.lintFile && typeof func.check === 'function') {
                            errors = errors.concat(func.check(content));
                        }
                    }
                });
            }
        }

        if (errors.length > 0) {
            errors.unshift('\n==== SQL ====\n');
        }

        return errors;
    }

    /**
     * Метод линтит переданный sql скрипт в объекте content и возвращет массив с ошибками.
     * @param {object<RegExp>} regExp - Регулярное выражение для проверки.
     * @param {object} content - Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * @param {object<function>} errorHandler - Функция, обрабатывающая найденную ошибку.
     * @return {Array<string>}
     * @private
     */
    _checkSql(regExp, content, errorHandler) {
        let match = [];
        let regex = regExp;
        let errors = [];
        let sqlFile = content.text ? content.text : fs.readFileSync(content.lintFile, this.encoding);

        while ((match = regex.exec(sqlFile))) {
            if (typeof errorHandler === 'function') {
                errors.push(errorHandler(match, content));
            }
        }

        return errors
    }

    /**
     * Метод линтит на предмет использование таблиц и возвращет ошибку.
     * @param {object} match - Объект, полученный в результате выполения функции Regexp.exec().
     * @param {object} content - Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * @return {string}
     * @private
     */
    _checkTables(match, content) {
        let errorLine = match.input.substr(0, match.index).split('\n').length,
            strMatches = match[0].replace('\n', ' ').trim().split(' '),
            tableName = strMatches && strMatches[strMatches.length - 1];

        return `\nФайл: ${chalk.green(content.path)}. Найдено использование таблицы ${chalk.red(tableName.replace('\n', ' ').trim())} на строке: ${errorLine + content.line}`;
    }

    /**
     * Метод линтит на предмет использование оператора IN и возвращет ошибку.
     * @param {object} match - Объект, полученный в результате выполения функции Regexp.exec().
     * @param {object} content - Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * @return {string}
     * @private
     */
    _checkInOperatorWithoutBrackets(match, content) {
        let errorLine = match.input.substr(0, match.index).split('\n').length;
        return `\nФайл: ${chalk.green(content.path)}. Найдено использование использование оператора IN с одним значением без скобок на строке: ${errorLine + content.line}`;
    }

    /**
     * Метод линтит на предмет использование оператора ** и возвращет ошибку.
     * @param {object} match - Объект, полученный в результате выполения функции Regexp.exec().
     * @param {object} content - Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * @return {string}
     * @private
     */
    _checkPowInvalidFormat(match, content) {
        let errorLine = match.input.substr(0, match.index).split('\n').length;
        return `Файл: ${chalk.green(content.path)}. Найдено использование оператора ** для возведения в степень на строке: ${errorLine + content.line}`;
    }

    /**
     * Метод линтит на предмет использование оператора MOD и возвращет ошибку.
     * @param {object} match - Объект, полученный в результате выполения функции Regexp.exec().
     * @param {object} content - Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * @return {string}
     * @private
     */
    _checkModInvalidFormat(match, content) {
        let errorLine = match.input.substr(0, match.index).split('\n').length;
        return `Файл: ${chalk.green(content.path)}. Найдено использование оператора MOD в неправильном формате на строке: ${errorLine + content.line}`;
    }

    /**
     * Метод линтит на предмет использование блока declare без содержимого и возвращет ошибку.
     * @param {object} match - Объект, полученный в результате выполения функции Regexp.exec().
     * @param {object} content - Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * @return {string}
     * @private
     */
    _checkEmptyDeclare(match, content) {
        let errorLine = match.input.substr(0, match.index).split('\n').length;
        return `Файл: ${chalk.green(content.path)}. Найдено использование блока declare без содержимого на строке: ${errorLine + content.line}`;
    }

    /**
     * Метод линтит на предмет использование оператора MULTISET UNION и возвращет ошибку.
     * @param {object} match - Объект, полученный в результате выполения функции Regexp.exec().
     * @param {object} content - Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * @return {string}
     * @private
     */
    _checkMultisetUnion(match, content) {
        let errorLine = match.input.substr(0, match.index).split('\n').length;
        return`Файл: ${chalk.green(content.path)}. Найдено использование оператора MULTISET UNION, строка: ${errorLine + content.line}`;
    }

    /**
     * Метод линтит на предмет заключения конструкции TABLE в скобки.
     * @param {object} match - Объект, полученный в результате выполения функции Regexp.exec().
     * @param {object} content - Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * @return {string}
     * @private
     */
    _checkTableInBrackets(match, content) {
        let errorLine = match.input.substr(0, match.index).split('\n').length;
        return `Файл: ${chalk.green(content.path)}. Найдено использование конструкции TABLE в скобках, строка: ${errorLine + content.line}`;
    }

    /**
     * Метод линтит на предмет создания представлений без указания состава полей.
     * @param {object} match - Объект, полученный в результате выполения функции Regexp.exec().
     * @param {object} content - Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * @return {string}
     * @private
     */
    _checkViewCreateWithoutFieldsList(match, content) {
        let errorLine = match.input.substr(0, match.index).split('\n').length;
        return `Файл: ${chalk.green(content.path)}. Найдено использование конструкции CREATE VIEW без указания состава полей, строка: ${errorLine + content.line}`;
    }

    /**
     * Метод линтит на предмет наличия в функциях OUT-параметров.
     * @param {object} match - Объект, полученный в результате выполения функции Regexp.exec().
     * @param {object} content - Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * @return {string}
     * @private
     */
    _checkOutParamsInFunctions(match, content) {
        let errorLine = match.input.substr(0, match.index).split('\n').length;
        return `Файл: ${chalk.green(content.path)}. Найдено использование OUT-параметров в функции, строка: ${errorLine + content.line}`;
    }

    /**
     * Метод линтит на количество параметров в процедурах и функциях(не должно быть 100 и более).
     * @param {object} match - Объект, полученный в результате выполения функции Regexp.exec().
     * @param {object} content - Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * @return {string}
     * @private
     */
    _checkParamsNumber(match, content) {
        let errorLine = match.input.substr(0, match.index).split('\n').length;
        return `Файл: ${chalk.green(content.path)}. Найдено использование функции или процедуры со 100 или более параметрами, строка: ${errorLine + content.line}`;
    }

    /**
     * Метод линтит на анонимные блоки с кастомными типами или внутренними процедурами/функциями.
     * @param {object} match - Объект, полученный в результате выполения функции Regexp.exec().
     * @param {object} content - Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * @return {string}
     * @private
     */
    _checkDeclareWithCustomTypesOrFunctionsOrProcedures(match, content) {
        let errorLine = match.input.substr(0, match.index).split('\n').length;
        return `Файл: ${chalk.green(content.path)}. Найдено использование анонимного блока с кастомными типами или внутренними процедурами/функциями, строка: ${errorLine + content.line}`;
    }

    /**
     * Метод линтит на вложенные функции/процедуры во вложенных процедурах/функциях.
     * @param {object} match - Объект, полученный в результате выполения функции Regexp.exec().
     * @param {object} content - Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * @return {string}
     * @private
     */
    _checkNestedInNestedFuncsAndProcs(match, content) {
        let errorLine = match.input.substr(0, match.index).split('\n').length;
        return `Файл: ${chalk.green(content.path)}. Найдено использование вложенных функций/процедур во вложенных процедурах/функциях, строка: ${errorLine + content.line}`;
    }

    /**
     * Метод линтит на функции и процедуры с одинаковым названием и параметрами.
     * @param {object} match - Объект, полученный в результате выполения функции Regexp.exec().
     * @param {object} content - Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * @return {string}
     * @private
     */
    _checkSimilarFunctionsAndProcedures(regExp, content) {
        let match = [];
        let regex = regExp;
        let regexIs = new RegExp('\\s+is$', 'gim');
        let regexAs = new RegExp('\\s+as$', 'gim');
        let regexReturn = new RegExp('\\s+return$', 'gim');
        let errors = [];
        let sqlFile = content.text ? content.text : fs.readFileSync(content.lintFile, this.encoding);
        let funcsAndProcs = [];
        let funcsAndProcsLines = [];
        let errorLine, i, j, iParams, jParams, iParamNums, jParamNums, iName, jName;

        while ((match = regex.exec(sqlFile))) {
            funcsAndProcs.push(match[0].toLowerCase().trim());
            funcsAndProcsLines.push(match.input.substr(0, match.index).split('\n').length);
        }

        for (i = 0; i < funcsAndProcs.length - 1; i++) {
            for (j = i + 1; j < funcsAndProcs.length; j++) {
                if (funcsAndProcs[i].indexOf('(') == -1) {
                    if (funcsAndProcs[i].split('function').length == 1) {
                        if (funcsAndProcs[i].search(regexIs) == -1) {
                            iName = funcsAndProcs[i].substring(funcsAndProcs[i].indexOf('procedure') + 'procedure'.length, funcsAndProcs[i].search(regexAs)).trim();
                        } else if (funcsAndProcs[i].search(regexAs) == -1) {
                            iName = funcsAndProcs[i].substring(funcsAndProcs[i].indexOf('procedure') + 'procedure'.length, funcsAndProcs[i].search(regexIs)).trim();
                        }
                    } else {
                        iName = funcsAndProcs[i].substring(funcsAndProcs[i].indexOf('function') + 'function'.length, funcsAndProcs[i].search(regexReturn)).trim();
                    }

                    iParamNums = 0;
                } else {
                    if (funcsAndProcs[i].split('function').length == 1) {
                        iName = funcsAndProcs[i].substring(funcsAndProcs[i].indexOf('procedure') + 'procedure'.length, funcsAndProcs[i].indexOf('(')).trim();
                    } else {
                        iName = funcsAndProcs[i].substring(funcsAndProcs[i].indexOf('function') + 'function'.length, funcsAndProcs[i].indexOf('(')).trim();
                    }

                    iParams = funcsAndProcs[i].substring(funcsAndProcs[i].indexOf('(') + 1, funcsAndProcs[i].lastIndexOf(')')).trim();
                    if (iParams.length == 0) {
                        iParamNums = 0;
                    } else {
                        iParamNums = funcsAndProcs[i].substring(funcsAndProcs[i].indexOf('(') + 1, funcsAndProcs[i].lastIndexOf(')')).split(',').length;
                    }
                }


                if (funcsAndProcs[j].indexOf('(') == -1) {
                    if (funcsAndProcs[j].split('function').length == 1) {
                        if (funcsAndProcs[j].search(regexIs) == -1) {
                            jName = funcsAndProcs[j].substring(funcsAndProcs[j].indexOf('procedure') + 'procedure'.length, funcsAndProcs[j].search(regexAs)).trim();
                        } else if (funcsAndProcs[j].search(regexAs) == -1) {
                            jName = funcsAndProcs[j].substring(funcsAndProcs[j].indexOf('procedure') + 'procedure'.length, funcsAndProcs[j].search(regexIs)).trim();
                        }
                    } else {
                        jName = funcsAndProcs[j].substring(funcsAndProcs[j].indexOf('function') + 'function'.length, funcsAndProcs[j].search(regexReturn)).trim();
                    }

                    jParamNums = 0;
                } else {
                    if (funcsAndProcs[j].split('function').length == 1) {
                        jName = funcsAndProcs[j].substring(funcsAndProcs[j].indexOf('procedure') + 'procedure'.length, funcsAndProcs[j].indexOf('(')).trim();
                    } else {
                        jName = funcsAndProcs[j].substring(funcsAndProcs[j].indexOf('function') + 'function'.length, funcsAndProcs[j].indexOf('(')).trim();
                    }

                    jParams = funcsAndProcs[j].substring(funcsAndProcs[j].indexOf('(') + 1, funcsAndProcs[j].lastIndexOf(')')).trim();
                    if (jParams.length == 0) {
                        jParamNums = 0;
                    } else {
                        jParamNums = funcsAndProcs[j].substring(funcsAndProcs[j].indexOf('(') + 1, funcsAndProcs[j].lastIndexOf(')')).split(',').length;
                    }
                }

                if (iName == jName && iParamNums == jParamNums) {
                    errorLine = funcsAndProcsLines[j];
                    errors.push(`Файл: ${chalk.green(content.path)}. Найдено использование функций и процедур с одинаковыми названиями и параметрами, строка: ${errorLine + content.line}`);
                }
            }
        }

        return errors;
    }
}

module.exports = HandlerSql;
