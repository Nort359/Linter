const Linter = require('./classes/Linter');

// [
//     './spec/resources/form.frm',
//     './spec/resources/formM2.frm',
//     './spec/resources/formD3.frm'
// ]

const linter = new Linter();

linter
  .getContentTagsInFile()
  .writeToFile();
