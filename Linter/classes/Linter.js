const fs = require('fs');

const Handler = require('./Handler/Handler');

/**
 * Class Linter
 */
class Linter {
    /**
     * @constructs Linter
     * @param {string} encoding Кодировка.
     */
    constructor(encoding = 'utf8') {
        this.exts = [];           // Расширения файлов
        this.handlers = [];       // Обработчики файлов
        this.messages = [];       // Сообщения
        this.encoding = encoding; // Кодировка
        this.pathTemp = 'tempLint';
        this.linterNames = [];
    }

    /**
     * Возвращает массив с расширениями.
     * @returns {[]|*[]}
     */
    getExts() {
        return this.exts;
    }

    /**
     * Возвращает массив доступных линтеров.
     * @returns {[]|*[]}
     */
    getLinters() {
        let linters = [];

        this.linterNames.forEach(name => {
            if (name) {
                linters.push(name);
            }
        });

        return linters;
    }

    /**
     * Добавляет переданный обработчик событий в массив обработчиков.
     * @param {Handler} handler экземпляр обработчика файлов.
     * @param {object} func объект, содержащий в себе функции, которые могут быть дополнительно использованы внутри обработчика файлов.
     * @param {string} linterName имя для обработчика линтера.
     * @returns {Linter}
     */
    addHandler(handler, func = {}, linterName = null) {
        if (handler instanceof Handler) {
            this.linterNames.forEach(name => {
                if (linterName && name === linterName) {
                    throw 'Не может быть два обработчика с одинаковыми именами. Обработчик для линтера с именем ' + name + ' уже существует';
                }
            });

            this.linterNames.push(linterName);

            this.exts = this.exts.concat(handler.ext);
            this.handlers.push({
                handler: handler,
                func: func
            });
        } else {
            throw 'Переданный объект должен быть потомком класса Handler';
        }

        return this;
    }

    /**
     * Производит обработку файлов, создаёт необходимый объект, с типами всех файлов, для которых были переданы обработчики файлов.
     * @param {[]|string} paths путь к файлам, которые необходимо линтить.
     * @returns {{}}
     */
    handle(paths) {
        let contents = {};

        if (typeof paths === 'string') {
            paths = [paths];
        }

        this.handlers.forEach(handler => {
            let content = handler.handler.handle(paths, this.pathTemp, handler.func) || {};

            for (const type in content) {
                if (content.hasOwnProperty(type)) {
                    // Если в свойстве Linter::content есть свойство такое же как в вернувшемся объекте и это массив
                    if (contents.hasOwnProperty(type) && Array.isArray(contents[type])) {
                        contents[type] = contents[type].concat(content[type]); // То конкатенируем их
                    } else { // иначе добавляем это свойство в Linter::content
                        contents[type] = content[type];
                    }
                }
            }
        });

        return contents;
    }

    /**
     * Производит линтинг файлов.
     * @param {boolean} isFix флаг, показывающий, нужно ли исправлять проверяемый файл.
     * @param {{}} content сформированные объект файлов через метод Linter.handle.
     * @param {boolean} isDelete флаг, показывающий нужно ли удалять временные файлы.
     * @returns {[]}
     */
    lint(isFix, content, isDelete = true) {
        let messages = [];

        this.handlers.forEach(handler => {
            messages = messages.concat(handler.handler.lint(isFix, content, handler.func));
        });

        if (isDelete === true) {
            // Если были созданы темповые файлы - удаляем их.
            this.deleteTempFiles(this.pathTemp);
        }

        return messages;
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
