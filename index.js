const Linter = require('./classes/Linter');

const linter = new Linter();

linter.getContentTagsInFile('print_dyn_pat.frm')
      .writeToFile();
