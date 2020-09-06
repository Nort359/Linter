class Handler {
    constructor(ext = [], encoding = 'utf8') {
        this.encoding = encoding;
        this.contents = {};
        this.ext = ext;
        this.ext.forEach(ext => {
            this.contents[ext] = [];
        });
    }

    handle(paths) {
        const content = this.contents;

        Array.isArray(paths) && paths.forEach(path => {
            const ext = this._getExtByPath(path);

            if (this.ext.includes(ext)) {
                const contentObj = {
                    // text: fs.readFileSync(path, this.encoding),
                    name: this._getFileNameByPath(path),
                    path: path,
                    lintFile: path,
                    line: 0,
                    ext: ext
                };

                content[ext].push(contentObj);
            }
        });

        return content;
    }

    /**
     * @abstract
     */
    lint() {
        // Базовое определение метода lint, предполагается переопределение в дочерних классах.
        throw new TypeError("Do not call abstract method lint from child.");
    }

    /**
     * Получить расширение файла по переданному пути
     * @param path Путь до файла
     * @returns {*} Расширение
     * @protected
     */
    _getExtByPath(path) {
        let ext = path.split('.');

        return ext[ext.length - 1];
    }

    /**
     * Получить имя файла по переданному пути
     * @param path Путь до файла
     * @returns {*} Расширение
     * @protected
     */
    _getFileNameByPath(path) {
        let fileName = path.split('/');
        fileName = fileName.length > 1 ? fileName : path.split('\\');

        return fileName[fileName.length - 1];
    }
}

module.exports = Handler;
