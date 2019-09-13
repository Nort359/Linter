// const Linter = require("eslint").Linter;
// const linter = new Linter();
// const fs = require('fs');
// //"var foo = bar"
//
// const messages = linter.verify(fs.readFileSync('temp/js/Script__0.js', 'utf8'), {
//     rules: {
//         semi: 2
//     }
// }, { filename: "foo.js" });
//
// const code = linter.getSourceCode();
//
// console.log(code.text);     // "var foo = bar;"
// console.log(messages);

const CLIEngine = require("eslint").CLIEngine;

const cli = new CLIEngine({
    envs: ["browser", "mocha"],
    fix: true, // difference from last example
    useEslintrc: false,
    rules: {
        semi: 2
    }
});

// lint myfile.js and all files in lib/
const report = cli.executeOnFiles(['temp/js/Script__0.js']);

console.log(report.results[0].messages);