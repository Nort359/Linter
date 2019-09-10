const Linter = require('./classes/Linter');

const linter = new Linter('./spec/resources/form.frm');

linter
  .getContentTagsInFile()
  .writeToFile();
