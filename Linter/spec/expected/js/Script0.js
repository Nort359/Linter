var DynPat = Form.DynPat = {};

DynPat.printLabDynPat = function(clone, type) {
    // Если первым аргументом передали число, значит это type.
    if (typeof clone === 'number') {
        type = clone;
        clone = null;
    }

    if (empty(getVar('soViewLabDinamics'))) {
        executeAction('getSoViewLabDinamics', function() {
            Form.DynPat.openLabDynPat(clone, getVar('soViewLabDinamics'), type);
        });
    } else {
        Form.DynPat.openLabDynPat(clone, getVar('soViewLabDinamics'), type);
    }
}

DynPat.openLabDynPat = function(clone, sysOption, type) {
    /*СО ViewLabDinamics. 0 - Окно, 1 - Отчёт*/
    var data = (clone && getClone(clone).clone.data) || {};

    if (+sysOption === 1) {
        openD3Form('Lis/Reports/Directions/lab_dynamics_patient_call', true, {
            width: 450,
            height: 160,
            vars: {
                PATIENT_ID: getVar('PATIENT_ID'),
                DS_ID: data['DIR_SERV_ID'] || getVar('DS_ID'),
                RESEARCH_ID: data['RESEARCH_ID'] || getVar('RESEARCH_ID'),
                /**1 - Исследование, 2 - Показатель */
                RES_ID: +type !== 1 ? data['RES_ID'] : null,
                DIRECTION_LINE_ID: data['DIR_LINE_ID']
            }
        });
    } else {
        openD3Form('Labmed/LabmedSamples/subforms/dinamic_history', true, {
            width: 800,
            height: 600,
            vars: {
                DS_ID: getVar('DS_ID'),
                PATIENT_ID: getVar('PATIENT_ID'),
                WORK_LIST: getVar('WORK_LIST'),
                SHOW_RSRCH_NAME: getValue('SHOW_RSRCH_NAME'),
                RESEARCH_ID: data['RESEARCH_ID'] || getVar('RESEARCH_ID'),
                RES_ID: data['RES_ID'],
                RES_NAME: data['RES_NAME'],
                LABMED_SAMPLE: getVar('LABMED_SAMPLE'),
                TYPE: type
            }
        });
    }
}
        
    
