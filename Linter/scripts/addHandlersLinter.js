const HandlerFrm = require('../classes/Handler/HandlerFrm');
const HandlerJs = require('../classes/Handler/HandlerJs');
const HandlerSql = require('../classes/Handler/HandlerSql');
const HandlerPhp = require('../classes/Handler/HandlerPhp');

const {
    argv
} = require('yargs');

/**
 * Функция служит для добавления обработчиков в линтер.
 * @param {Linter} linter экземпляр объекта Linter.
 * @returns {Linter}
 */
const addHandlersLinter = linter => {
    // Избавляемся от зависимости регистра
    argv._ = argv._.map(item => item.toLowerCase());

    const linterHandlers = [
        {
            handler: HandlerFrm,
            ext: [
                'frm',
                'dfrm'
            ]
        },
        {
            handler: HandlerJs,
            ext: ['js'],
            func: {
                replace: HandlerFrm.replace
            },
            lintStr: 'js'
        },
        {
            handler: HandlerSql,
            ext: ['sql'],
            func: {
                check: HandlerFrm.checkSqlBindParams
            },
            lintStr: 'sql'
        },
        {
            handler: HandlerPhp,
            ext: [
                'php',
                'mdl',
                'inc'
            ],
            lintStr: 'php'
        }
    ];

    let linterCount = 0;

    // Проверяем количество переданных линтеров
    linterHandlers.forEach(handler => {
        if (handler.lintStr && argv._.includes(handler.lintStr.toLowerCase())) {
            linterCount++;
        }
    });

    if (linterCount === 0) {
        linterHandlers.forEach(handler => {
            linter.addHandler(new handler.handler(handler.ext), handler.func, handler.lintStr);
        });
    } else {
        linterHandlers.forEach(handler => {
            // Если handler.lintStr пустой то считаем, что этот обработчик обязательный
            if ((handler.lintStr && argv._.includes(handler.lintStr.toLowerCase())) || !handler.lintStr) {
                linter.addHandler(new handler.handler(handler.ext), handler.func);
            }
        });
    }

    return linter;
};

module.exports = addHandlersLinter;
