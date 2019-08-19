const fs = require('fs');

class Linter {
    constructor() {
        this.tags = [
            {
                cmp: 'cmpScript',
                extension: 'js'
            },
            {
                cmp: 'cmpAction',
                extension: 'sql'
            },
            {
                cmp: 'cmpDataSet',
                extension: 'sql'
            }
        ];

        this.contents = {};
        this.subforms = [];
    }

    /**
     * Проверяет является ли символ пустым символом.
     * @param {string} symbol - Символ, который необходимо проверить.
     * @return {boolean} - true - не пустой, false - пустой.
     */
    isLetter(symbol) {
        return symbol.toUpperCase() !== symbol.toLowerCase();
    }

    /**
     * Находит позицию первого не пустого символа.
     * @param {sting} str - Строка, где необходимо производить поиск.
     * @return {string} - Позиция первого не пустого символа.
     */
    findFirstLetterPosition(str) {
        let position = -1;

        for (let j = 0; j <= str.length; j++) {
            if (str[j] && this.isLetter(str[j])) {
                position = j;
                break;
            }
        }

        return position;
    }

    /**
     * private
     * Получает содержимое переданного тега в файле и помещает его в this.contents
     * @param {string} fileContents - Содержимое файла.
     * @param {string} cmp - Имя тега.
     */
    _getContent(fileContents, cmp) {
        let match = [];
        const regex = new RegExp(`<${cmp}[\\s\\S]*?>([\\s\\S]*?)<\\/${cmp}>`, 'gim');

        if (!Array.isArray(this.contents[cmp])) {
            this.contents[cmp] = [];
        }

        let i = this.contents[cmp].length;

        while (match = regex.exec(fileContents)) {
            this.contents[cmp].push(match[1]);

            if (this.contents[cmp][i]) {
                // Если есть обработка XML <![CDATA[ ]]>, то убираем эти символы.
                if (~this.contents[cmp][i].indexOf('<![CDATA[')) {
                    this.contents[cmp][i] = this.contents[cmp][i].replace(/<\!\[CDATA\[([\s\S]*)\]\]([\s\S]*)>/gim, '$1');
                }

                let firstSymbolPosition = -1;
                
                // Убираем лишние пробелы перед каждой строкой.
                this.contents[cmp][i] = this.contents[cmp][i].split('\n').map(line => {
                    // Находим позицию первого не пустого символа.
                    if (firstSymbolPosition === -1) {
                        firstSymbolPosition = this.findFirstLetterPosition(line);
                    }

                    // Пропускаем пустые строки, а в не пустых убираем лишнее количество табов и пробелов.
                    return line = line.trim() !== '' ? line.substr(firstSymbolPosition) : line;
                });

                if (Array.isArray(this.contents[cmp][i])) {
                    this.contents[cmp][i] = this.contents[cmp][i].join('');
                }

                // Обрезаем пустые символы и сиволы переноса строк в самом начале строки.
                this.contents[cmp][i] = this.contents[cmp][i].substr(this.findFirstLetterPosition(this.contents[cmp][i]));
            }
        
            i++;
        }
    }

    /**
     * Ищет все сабформы на форме и получает из них контент вызывая метод this.getContentTagsInFile.
     * @param {string} fileContents - Содержимое файла.
     */
    _checkSubForms(fileContents) {
        const self = this;
        const regexSubForm = new RegExp(`<cmpSubForm[\\s\\S]*?\\/>?`, 'gim');
        const regexPath = new RegExp(`path=([\\"\\'])([^\\"\\']+)\\1`, 'gim');
        let subForms = fileContents.match(regexSubForm);

        subForms.forEach(function(subForm) {
            let matchPath = [];
            
            // Получаем путь до сабформ.
            while (matchPath = regexPath.exec(subForm)) {
                //const path = `Form/${matchPath[2]}.frm`;
                const path = `${matchPath[2]}.frm`;

                if (fs.existsSync(path)) {
                    // TODO: расскоментировать
                    // self.getContentTagsInFile(path);
                }
            }
        });
    }

    /**
     * Возвращает контент для каждого тега в переданном файле. 
     * @param {string} path - Путь до файла.
     * @param {string} coding - Кодировка файла.
     * @return {object} - Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * Структура:
     * {
     *      имя_тега: [] - массив с кодом всех тегов.
     * }
     */
    getContentTagsInFile(path, coding = 'utf8') {
        const fileContents = fs.readFileSync(path, coding);

        this.tags.forEach(tag => {
            const cmp = tag.cmp;
            const regex = new RegExp(`<${cmp}[\\s\\S]*?>([\\s\\S]*?)<\\/${cmp}>`, 'gim');
            //let i = this.contents[cmp].length;
            let match = [];

            while (match = regex.exec(fileContents)) {
                if (cmp !== 'cmpAction') {
                    this._getContent(match[0], cmp);
                } else {
                    this._getContent(match[0], cmp);
                }
            }
        });

        // Рекурсивно проходимся по всем сабформам.
        this._checkSubForms(fileContents);

        return this;
    }

    /**
     * Записывает в файлы содержимое тегов.
     * @param {object} contents - Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * Структура:
     * {
     *      имя_тега: [] - массив с кодом всех тегов.
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
                fs.writeFileSync(`${pathTag}/${cmp + index}.${dir}`, content);
            });
        });

        return this;
    }
}

module.exports = Linter;
