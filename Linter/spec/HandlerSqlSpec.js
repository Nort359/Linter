const Handler = require('../classes/Handler/Handler');
const HandlerSql = require('../classes/Handler/HandlerSql');
const HandlerFrm = require('../classes/Handler/HandlerFrm');
const Linter = require('../classes/Linter');

describe('Handler', function() {
    beforeEach(function(){
        this.handler = new HandlerSql(['sql']);
        this.linter = new Linter();
        this.linter.addHandler(this.handler);
        this.linter.addHandler(new HandlerFrm(['frm', 'dfrm']));

        this.absPath = __dirname.replace(/\\/g, '/');
    });

    it('must be the child of Handler', function () {
        expect(this.handler instanceof Handler).toBe(true);
    });

    it('function lin must be declared', function() {
        expect(typeof this.handler.lint).toEqual('function');
    });

    it('must check tables', function() {
        let contents = this.linter.handle(this.absPath + '/resources/sql/tablesCheck.frm');
        let errors = [];

        for (let type in contents) {
            if (contents.hasOwnProperty(type)) {
                Array.isArray(contents[type]) && contents[type].forEach(content => {
                    if (this.handler.ext.includes(content.ext)) {
                        errors = errors.concat(this.handler._checkSql.call(this.handler, new RegExp('(^|FROM|JOIN)\\s+D_(?!PKG|CL_|V_|C_|P_|STR|TP_|F_)\\S+', 'gim'), content, this.handler._checkTables));
                    }
                });
            }
        }

        expect(Array.isArray(errors) && errors.length > 0).toBe(true);
    });

    it('must check in operator without brackets', function () {
        let contents = this.linter.handle(this.absPath + '/resources/sql/inOperatorWithoutBracketsCheck.frm');
        let errors = [];

        for (let type in contents) {
            if (contents.hasOwnProperty(type)) {
                Array.isArray(contents[type]) && contents[type].forEach(content => {
                    if (this.handler.ext.includes(content.ext)) {
                        errors = errors.concat(this.handler._checkSql.call(this.handler, new RegExp('(^|\\s)(WHERE|AND|OR|NOT)\\s+[^\\s]+\\s+IN($|\\s+)[^(\\s]{1}', 'gim'), content, this.handler._checkInOperatorWithoutBrackets));
                    }
                });
            }
        }

        expect(Array.isArray(errors) && errors.length > 0).toBe(true);
    });

    it('must check pow invalid format', function () {
        let contents = this.linter.handle(this.absPath + '/resources/sql/powInvalidFormatCheck.frm');
        let errors = [];

        for (let type in contents) {
            if (contents.hasOwnProperty(type)) {
                Array.isArray(contents[type]) && contents[type].forEach(content => {
                    if (this.handler.ext.includes(content.ext)) {
                        errors = errors.concat(this.handler._checkSql.call(this.handler, new RegExp('(^|\\s)\\*\\*($|\\s)', 'gim'), content, this.handler._checkPowInvalidFormat));
                    }
                });
            }
        }

        expect(Array.isArray(errors) && errors.length > 0).toBe(true);
    });

    it('must check mod invalid format', function () {
        let contents = this.linter.handle(this.absPath + '/resources/sql/modInvalidFormatCheck.frm');
        let errors = [];

        for (let type in contents) {
            if (contents.hasOwnProperty(type)) {
                Array.isArray(contents[type]) && contents[type].forEach(content => {
                    if (this.handler.ext.includes(content.ext)) {
                        errors = errors.concat(this.handler._checkSql.call(this.handler, new RegExp('(^|\\s)MOD($|\\s)', 'gim'), content, this.handler._checkModInvalidFormat));
                    }
                });
            }
        }

        expect(Array.isArray(errors) && errors.length > 0).toBe(true);
    });

    it('must check empty declare', function () {
        let contents = this.linter.handle(this.absPath + '/resources/sql/emptyDeclareCheck.frm');
        let errors = [];

        for (let type in contents) {
            if (contents.hasOwnProperty(type)) {
                Array.isArray(contents[type]) && contents[type].forEach(content => {
                    if (this.handler.ext.includes(content.ext)) {
                        errors = errors.concat(this.handler._checkSql.call(this.handler, new RegExp('(^|\\s)DECLARE($|\\s+)BEGIN($|\\s)', 'gim'), content, this.handler._checkEmptyDeclare));
                    }
                });
            }
        }

        expect(Array.isArray(errors) && errors.length > 0).toBe(true);
    });

    it('must check multiset union', function () {
        let contents = this.linter.handle(this.absPath + '/resources/sql/multisetUnionCheck.frm');
        let errors = [];

        for (let type in contents) {
            if (contents.hasOwnProperty(type)) {
                Array.isArray(contents[type]) && contents[type].forEach(content => {
                    if (this.handler.ext.includes(content.ext)) {
                        errors = errors.concat(this.handler._checkSql.call(this.handler, new RegExp('(^|\\s)MULTISET($|\\s+)UNION($|\\s)', 'gim'), content, this.handler._checkMultisetUnion));
                    }
                });
            }
        }

        expect(Array.isArray(errors) && errors.length > 0).toBe(true);
    });

    it('must check table in brackets', function () {
        let contents = this.linter.handle(this.absPath + '/resources/sql/tableInBracketsCheck.frm');
        let errors = [];

        for (let type in contents) {
            if (contents.hasOwnProperty(type)) {
                Array.isArray(contents[type]) && contents[type].forEach(content => {
                    if (this.handler.ext.includes(content.ext)) {
                        errors = errors.concat(this.handler._checkSql.call(this.handler, new RegExp('\\(\\s*TABLE(\\s+|\\()', 'gim'), content, this.handler._checkTableInBrackets));
                    }
                });
            }
        }

        expect(Array.isArray(errors) && errors.length > 0).toBe(true);
    });

    it('must check view create without fields list', function () {
        let contents = this.linter.handle(this.absPath + '/resources/sql/viewCreateWithoutFieldsListCheck.sql');
        let errors = [];

        for (let type in contents) {
            if (contents.hasOwnProperty(type)) {
                Array.isArray(contents[type]) && contents[type].forEach(content => {
                    if (this.handler.ext.includes(content.ext)) {
                        errors = errors.concat(this.handler._checkSql.call(this.handler, new RegExp('(^|\\s)CREATE\\s+OR\\s+REPLACE\\s+VIEW\\s+(\\"[^"]+\\"|[a-zà-ÿ]{1}[a-zà-ÿ0-9_$#]*)\\s+as', 'gim'), content, this.handler._checkViewCreateWithoutFieldsList));
                    }
                });
            }
        }

        expect(Array.isArray(errors) && errors.length > 0).toBe(true);
    });

    it('must check out params in functions', function () {
        let contents = this.linter.handle(this.absPath + '/resources/sql/outParamsInFunctionsCheck.sql');
        let errors = [];

        for (let type in contents) {
            if (contents.hasOwnProperty(type)) {
                Array.isArray(contents[type]) && contents[type].forEach(content => {
                    if (this.handler.ext.includes(content.ext)) {
                        errors = errors.concat(this.handler._checkSql.call(this.handler, new RegExp('(^|\\s)FUNCTION\\s+(\\"[^"]+\\"|[a-zà-ÿ]{1}[a-zà-ÿ0-9_$#]*)\\s*\\([^)]+(\\"[^"]+\\"|[a-zà-ÿ]{1}[a-zà-ÿ0-9_$#]*)\\s+out\\s{1}', 'gim'), content, this.handler._checkOutParamsInFunctions));
                    }
                });
            }
        }

        expect(Array.isArray(errors) && errors.length > 0).toBe(true);
    });

    it('must check params number', function () {
        let contents = this.linter.handle(this.absPath + '/resources/sql/paramsNumberCheck.sql');
        let errors = [];

        for (let type in contents) {
            if (contents.hasOwnProperty(type)) {
                Array.isArray(contents[type]) && contents[type].forEach(content => {
                    if (this.handler.ext.includes(content.ext)) {
                        errors = errors.concat(this.handler._checkSql.call(this.handler, new RegExp('(^|\\s)(FUNCTION|PROCEDURE)\\s+(\\"[^"]+\\"|[a-zà-ÿ]{1}[a-zà-ÿ0-9_$#]*)\\s*\\((\\s*(\\"[^"]+\\"|[a-zà-ÿ]{1}[a-zà-ÿ0-9_$#]*)\\s+((IN\\s+OUT|IN|OUT)\\s+)?(\\"[^"]+\\"|[a-zà-ÿ]{1}[a-zà-ÿ0-9_$#]*(\\([a-zà-ÿ0-9_$#]*\\))*\\s*)((DEFAULT|:=)\\s+[^,()]+\\s*)*\\,(\\s*--[^\\n]*\\n)*){99}', 'gim'), content, this.handler._checkParamsNumber));
                    }
                });
            }
        }

        expect(Array.isArray(errors) && errors.length > 0).toBe(true);
    });

    it('must check declare with custom types or functions or procedures', function () {
        let contents = this.linter.handle(this.absPath + '/resources/sql/declareWithCustomTypesOrFunctionsOrProceduresCheck.sql');
        let errors = [];

        for (let type in contents) {
            if (contents.hasOwnProperty(type)) {
                Array.isArray(contents[type]) && contents[type].forEach(content => {
                    if (this.handler.ext.includes(content.ext)) {
                        errors = errors.concat(this.handler._checkSql.call(this.handler, new RegExp('(^|\\s)DECLARE\\s+((((?!(;)).)*;\\s*)*(PROCEDURE|FUNCTION)(\\(|\\s)|((((?!(( |	)BFILE( |	|;)|( |	)BLOB( |	|;)|( |	)NCLOB( |	|;)|( |	)CLOB( |	|;)|( |	)ROWID( |	|;)|( |	)LONG( |	|;)|( |	)DATE( |	|;)|( |	)INTERVAL( |	|;)|( |	)BINARY_FLOAT( |	|;)|( |	)BINARY_DOUBLE( |	|;)|( |	)NCHAR|( |	)CHAR|( |	)UROWID|( |	)RAW|( |	)TIMESTAMP|( |	)FLOAT|( |	)NUMBER|( |	)NVARCHAR2|( |	)VARCHAR2)).)*;)|((((?!(;)).)*;\\s*)*(((?!(( |	)BFILE( |	|;)|( |	)BLOB( |	|;)|( |	)NCLOB( |	|;)|( |	)CLOB( |	|;)|( |	)ROWID( |	|;)|( |	)LONG( |	|;)|( |	)DATE( |	|;)|( |	)INTERVAL( |	|;)|( |	)BINARY_FLOAT( |	|;)|( |	)BINARY_DOUBLE( |	|;)|( |	)NCHAR|( |	)CHAR|( |	)UROWID|( |	)RAW|( |	)TIMESTAMP|( |	)FLOAT|( |	)NUMBER|( |	)NVARCHAR2|( |	)VARCHAR2)).)*;))))', 'gim'), content, this.handler._checkDeclareWithCustomTypesOrFunctionsOrProcedures));
                    }
                });
            }
        }

        expect(Array.isArray(errors) && errors.length > 0).toBe(true);
    });

    it('must check similat functions and procedures', function () {
        let contents = this.linter.handle(this.absPath + '/resources/sql/similarFunctionsAndProceduresCheck.sql');
        let errors = [];

        for (let type in contents) {
            if (contents.hasOwnProperty(type)) {
                Array.isArray(contents[type]) && contents[type].forEach(content => {
                    if (this.handler.ext.includes(content.ext)) {
                        errors = errors.concat(this.handler._checkSimilarFunctionsAndProcedures.call(this.handler, new RegExp('(^|\\s)(FUNCTION|PROCEDURE)\\s+(\\"[^"]+\\"|[a-zà-ÿ]{1}[a-zà-ÿ0-9_$#]*)(\\s+AS|\\s+IS|\\s+RETURN|\\s*\\((\\s*(\\"[^"]+\\"|[a-zà-ÿ]{1}[a-zà-ÿ0-9_$#]*)\\s+((IN\\s+OUT|IN|OUT)\\s+)?(\\"[^"]+\\"|[a-zà-ÿ]{1}[a-zà-ÿ0-9_$#]*(\\([a-zà-ÿ0-9_$#]*\\))*\\s*)((DEFAULT|:=)\\s+[^,()]+\\s*)*\\,?(\\s*--[^\\n]*\\n)*\\s*)*\\s*\\))', 'gim'), content));
                    }
                });
            }
        }

        expect(Array.isArray(errors) && errors.length > 0).toBe(true);
    });
});
