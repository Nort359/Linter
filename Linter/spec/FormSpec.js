const Linter = require('../classes/Linter');
const HandlerFrm = require('../classes/Handler/HandlerFrm');

describe('Form', function() {
    it('can extract components correctly', function() {
        const formLinter = new Linter();

        formLinter.addHandler(new HandlerFrm(['frm', 'dfrm']));

        const content = formLinter.handle('spec/resources/form.frm');

        formLinter.lint(false, content, false);

        // Свойство this.compareActualWithExpected (./spec/helpers/fileComparatorHelper.js)
        formLinter.getExts().forEach(language => expect(this.compareActualWithExpected(language)).toBe(true));
    });
});
