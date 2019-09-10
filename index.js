const Linter = require('./classes/Linter');

const linter = new Linter('print_dyn_pat.frm');

linter.getContentTagsInFile()
     .writeToFile();
