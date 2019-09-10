const fs = require('fs');
const libxml = require('libxmljs');

/**
 * class Linter
 */
class Linter {

    /**
     * @constructs Linter
     * @param {string} path - Путь до файла.
     * @param {string} encoding - Кодировка файла.
     */
    constructor(path, encoding = 'utf8') {
        this.encoding = encoding;
        this.fileContents = fs.readFileSync(path, encoding);

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
     * Проверяет является ли символ пустым символом.
     * @param {string} symbol - Символ, который необходимо проверить.
     * @return {boolean} - true - не пустой, false - пустой.
     */
    isLetter(symbol) {
        return symbol.toUpperCase() !== symbol.toLowerCase();
    }

    /**
     * Находит позицию первого не пустого символа.
     * @param {string} str - Строка, где необходимо производить поиск.
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
     * @param {string} node - Содержимое тега.
     * @param {string} cmp - Имя тега.
     * @param {string} cmp - Атрибут name на компоненте.
     */
    _getContent(node, cmp, nodeName) {
        if (!Array.isArray(this.contents[cmp])) {
            this.contents[cmp] = [];
        }

        let i = this.contents[cmp].length;

        this.contents[cmp].push({ text: node, name: nodeName });

        if (this.contents[cmp][i].text) {
            let firstSymbolPosition = -1;
            
            // Убираем лишние пробелы перед каждой строкой.
            this.contents[cmp][i].text = this.contents[cmp][i].text.split('\n').map(line => {
                // Находим позицию первого не пустого символа.
                if (firstSymbolPosition === -1) {
                    firstSymbolPosition = this.findFirstLetterPosition(line);
                }

                // Пропускаем пустые строки, а в не пустых убираем лишнее количество табов и пробелов.
                return line = line.trim() !== '' ? line.substr(firstSymbolPosition) + '\n' : line + '\n';
            });

            if (Array.isArray(this.contents[cmp][i].text)) {
                this.contents[cmp][i].text = this.contents[cmp][i].text.join('');
            }

            // Обрезаем пустые символы и сиволы переноса строк в самом начале строки.
            this.contents[cmp][i].text = this.contents[cmp][i].text.substr(this.findFirstLetterPosition(this.contents[cmp][i].text));
        }
    
        i++;
    }

    /**
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
                console.error(`Не найдена сабформа ${path}`);
            }
        });
    }

    /**
     * Возвращает контент для каждого тега в переданном файле. 
     * @param {string} fileContents - Содержимое файла.
     * @return {object} - Объект, где ключом выступает имя тега, а значением массив с кодом для каждого тега.
     * Структура:
     * {
     *      имя_тега: [] - массив с кодом всех тегов.
     * }
     */
    getContentTagsInFile(fileContents = this.fileContents) {
        this.tags.forEach(tag => {
            const cmp = tag.cmp;
            const xmlDoc = libxml.parseXmlString(fileContents);
            const d3Nodes = xmlDoc.find(`.//cmp${cmp}`);
            const m2Nodes = xmlDoc.find(`.//component[@cmptype="${cmp}"]`);
            const nodes = d3Nodes.concat(m2Nodes);

            nodes.forEach(node => {
                const nodeAttrName = node.attr('name');
                const nodeName = nodeAttrName && nodeAttrName.value();

                if (cmp !== 'Action') {
                    // TODO: Сделать реализацию для сабэкшинов
                    this._getContent(node.text(), cmp, nodeName);
                } else {
                    this._getContent(node.text(), cmp, nodeName);
                }
            });
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
                const name = content.name;
                fs.writeFileSync(`${pathTag}/${cmp + '__' + (name ? name : index)}.${dir}`, content.text);
            });
        });

        return this;
    }
}

module.exports = Linter;
