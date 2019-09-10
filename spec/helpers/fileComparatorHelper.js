const glob = require("glob");
const fs = require('fs');
const path = require('path');
const DEFAULT_ENCODING = 'utf8';

/**
 * Сравнение фактического результата линтера с ожидаемым.
 *
 * @param {string} language Язык компонента — его расширение и наименование директории, в которую складываются
 *                          результаты линтера для этого языка.
 */
function compareActualWithExpected(language) {
    glob(`temp/${language}/*`, undefined, function (er, files) {
        files.forEach(file => {
            process.stdout.write(file);
            const actualContents = fs.readFileSync(file, DEFAULT_ENCODING);
            const expectedContents = fs.readFileSync(`spec/expected/${language}/${path.basename(file)}`, DEFAULT_ENCODING);
            expect(actualContents).toEqual(expectedContents);
        });
    });
    return true;
}

beforeAll(function(){
    this.compareActualWithExpected = compareActualWithExpected;
});
