const Linter = require('../classes/Linter');

describe("Form", function() {
    it("can extract components correctly", function() {
        let formLinter = new Linter('spec/resources/form.frm');
        formLinter
          .getContentTagsInFile()
          .writeToFile();

        //TODO: получить список обрабатываемых языков из `Linter` или через `glob`
        ['js', 'sql'].forEach(language => expect(this.compareActualWithExpected(language)).toBe(true));
    });
});
