<div cmptype="Base" name="Joursp" class="form_joursp">

    <!--
    Субформа ручного ввода результатов
    для образца (D_LABMED_SAMPLES)
    или для клетки постановки (D_LABMED_PUT_CELLS)

    @args
        LABMED_SAMPLE   [optional] - ID образца (D_LABMED_SAMPLES.ID)
        PUT_CELL        [optional] - D_LABMED_PUT_CELLS.ID
        VIEW_MODE       [optional] - true/false, режим просмотра
        WORK_LIST       [optional] - ID рабочего листа для фильтрации исследований
    -->

    <cmpSubForm path="Lis/Samples/subforms/masks"/>
    <cmpSubForm path="Labmed/LabmedSamples/subforms/utils"/>

    <cmpScript name="mainScript">
        <![CDATA[
            var Joursp = Form.Joursp = {};

            var currSample = null;
            var currPutCell = null;

            Form.getNumberFromString = function(str) {
                var position = 0;

                for (var i = 0; i < str.length; i++) {
                    if (!isNaN(+str[i]) || (str[i] === '-' && !isNaN(+str[i + 1]))) {
                        position = i;
                        break;
                    }
                }

                return parseFloat(str.substring(position));
            }

            Form.getNumbersFromComplex = function(complexNumber) {
                var numbers = [];
                var position = 0;

                if (!~complexNumber.indexOf('<') && !~complexNumber.indexOf('>') && !~complexNumber.indexOf('менее') && !~complexNumber.indexOf('более')) {
                    for (var i = 0; i < complexNumber.length; i++) {
                        if (complexNumber[i] === '*' || complexNumber[i] === '^') {
                            var number = parseFloat(complexNumber.substring(position, i).replace(',', '.'));

                            if (!isNaN(number)) {
                                numbers.push(number);
                            }

                            position = i + 1;
                        }
                    }

                    if (position !== complexNumber.length) {
                        var number = parseFloat(complexNumber.substring(position, i).replace(',', '.'));

                        if (!isNaN(number)) {
                            numbers.push(number);
                        }
                    }
                }

                return numbers;
            }

            Joursp.checkComplexNum = function(checkVal, complexNum) {
                var vals = checkVal.split('*10^');
                var answer = 0;

                if (vals) {
                    for (var i = 0; i < vals.length; i++) {
                        vals[i] = parseFloat(vals[i].replace(',', '.'));
                    }

                    if (complexNum[0][0] > 0 && vals[0] < 0) answer = -1;
                    else if (vals[1] < complexNum[0][1]) answer = -1;
                    else if (vals[1] > complexNum[1][1]) answer = 1;
                    else if ((vals[1] === complexNum[0][1] || vals[1] === complexNum[1][1]) && vals[0] < complexNum[0][0]) answer = -1;
                    else if ((vals[1] === complexNum[0][1] || vals[1] === complexNum[1][1]) && vals[0] > complexNum[0][0]) answer = 1;
                    else answer = 0;
                }

                return answer;
            }

            Joursp.setTabIndexes = function() {
                var controlls = document.querySelectorAll('[name]');

                controlls.forEach(function(controll) {
                    var classes = [];

                    [].forEach.call(controll.classList, function(cl) {
                        classes.push(cl);
                    });

                    var input = controll.querySelector('input');

                    if (input) input.tabIndex = classes && ~classes.indexOf('tabElement') ? 1 : -1;
                });
            }

            Joursp.checkNorm = function(dom) {
                ['ctrlVAL_NUM', 'ctrlVAL_POW_TEN'].forEach(function(ctrlName) {
                    var values = dom ? [dom] : document.getElementsByName(ctrlName);

                    [].forEach.call(values, function(value) {
                        if (!D3Api.hasProperty(value, 'isrepeat')) {
                            var clone = getClone(value);
                            var data = clone.clone.data;
                            closureContext(clone);
                            if (!clone.querySelector('[name="'+ctrlName+'"]')) return; //при изменении ctrlVAL_NUM терялся контекст в д3 и брался глобальный что влияло на ctrlVAL_POW_TEN и наоборот

                            var valNum = getValue(ctrlName);
                            var refValue = data && data['REF_VALUE'];
                            var refs = refValue && refValue.split(' - ');
                            var isPow = ~clone.querySelector('.refValue').innerText.indexOf('*10^');

                            var input = getControlProperty(ctrlName, 'input');

                            if (!empty(valNum)) {
                                var valNumFromStr = Form.getNumberFromString(valNum.replace(',', '.'));

                                if (refs) {
                                    if (~refs[0].indexOf('менее') || ~refs[0].indexOf('<')) {
                                        refs[1] = Form.getNumberFromString(refs[0]);
                                        refs[0] = 0;
                                    } else if (~refs[0].indexOf('более') || ~refs[0].indexOf('>')) {
                                        refs[0] = Form.getNumberFromString(refs[0]);
                                    }

                                    for (var i = 0; i < refs.length; i++) {
                                        if (~refs[i].indexOf('*10^')) {
                                            refs[i] = refs[i].split('*10^');

                                            if (refs[i]) {
                                                for (var j = 0; j < refs[i].length; j++) {
                                                    refs[i][j] = parseFloat(refs[i][j].replace(',', '.'));
                                                }
                                            }

                                            continue;
                                        }

                                        refs[i] = Form.getNumberFromString(refs[i].replace(',', '.'));
                                    }
                                }

                                if (refs && valNumFromStr < +refs[0] && Object.prototype.toString.call(refs[0] !== '[object Array]') && !isPow) { // последняя проверка костыль для комментов что ниже По задаче 223438
                                    input.style.color = 'blue';
                                    input.style.fontWeight = 'bold';
                                } else if (refs && valNumFromStr > +refs[1] && Object.prototype.toString.call(refs[1] !== '[object Array]') && !isPow) {
                                    input.style.color = 'red';
                                    input.style.fontWeight = 'bold';
                                } else if (refs && (Object.prototype.toString.call(refs[0] === '[object Array]') || Object.prototype.toString.call(refs[1] === '[object Array]'))) {
                                    // TODO: По задаче 223438, аналитик просил пока временно убрать валидацию результатов вида: 1*10:5, т.к. неизвестны точные действия.
                                    // var check = Form.Joursp.checkComplexNum(valNum, refs);
                                    //
                                    // if (check === -1) {
                                    //     input.style.color = 'blue';
                                    //     input.style.fontWeight = 'bold';
                                    // } else if (check === 1) {
                                    //     input.style.color = 'red';
                                    //     input.style.fontWeight = 'bold';
                                    // } else {
                                    //     input.style.color = 'black';
                                    //     input.style.fontWeight = 'normal';
                                    // }

                                    input.style.color = 'black';
                                    input.style.fontWeight = 'normal';
                                } else {
                                    input.style.color = 'black';
                                    input.style.fontWeight = 'normal';
                                }
                            }

                            if (!dom) {
                                input.addEventListener('keyup', function () {
                                    Form.Joursp.checkNorm(input);
                                });
                            }

                            unClosureContext();
                        }
                    });
                });
            }

            // Refresh form by sample or put_cell
            Joursp.refresh = function(sample, put_cell) {
                currSample = sample || null;
                currPutCell = put_cell || null;

                if (getVar('VIEW_MODE') || getVar('VIEW_MODE',1)) {
                    setVar('VIEW_MODE_NUM',1);
                } else {
                    setVar('VIEW_MODE_NUM',0);
                }

                setVar('_LABMED_SAMPLE', currSample);
                setVar('_PUT_CELL', currPutCell);
                refreshDataSet('Joursp.Ds', function() {
                    getRepeater('RptRsrchRes0').clones(getControl('Joursp')).forEach(function(clone) {
                        closureContext(clone);
                            var data = clone.clone.data || {};
                            if(data.VAL_STRING) {
                                var str = data.VAL_STRING.split(' ');
                                if (/^([0-9]*[.,]?[0-9]+)$/.test(str[0])) {
                                    str = (+str[0].replace(',', '.')).toFixed(+data.NUM_PRECISION || 0) + (!empty(str[1]) ? ' ' + str[1] : '');
                                } else {
                                    str = str.join(' ');
                                }
                                setValue('ctrlVAL_NUM', str);
                            }
                        unClosureContext();
                    });
                    getRepeater('RptRsrchRes7').clones(getControl('Joursp')).forEach(function(clone) {
                        closureContext(clone);
                        var data = clone.clone.data || {};
                        if (data.RESULT_TYPE != 7) {
                            return;
                        }
                        var str = data.VAL_STRING;
                        var powDif = data.POW_TEN_DIF.split(';');
                        powDif = {
                            MINDEGREE: +powDif[0],
                            MAXDEGREE: +powDif[1],
                            MINVALUE: +powDif[2],
                            MAXVALUE: +powDif[3]
                        };
                        var powRef = powDif.MINVALUE + '*10^' + powDif.MINDEGREE + ' - ' + powDif.MAXVALUE + '*10^' + powDif.MAXDEGREE;
                        setCaption('REF_VALUE', powRef);
                        if (!str || !~str.indexOf('*10^')) return;
                        var degree = str && str.match( /\^(.*)/ )[1];
                        var value = str && str.match( /([-<>]?\d?[.,]?\d*)\*/ )[1];
                        if (value.match(/([<>]+)/)) return;
                        value = +value;
                        degree = +degree;
                        var mathValue = value * Math.pow(10, degree);
                        var minMathValue = powDif.MINVALUE * Math.pow(10, powDif.MINDEGREE);
                        var maxMathValue = powDif.MAXVALUE * Math.pow(10, powDif.MAXDEGREE);
                        if ((mathValue >= minMathValue) && (mathValue <= maxMathValue)) return;
                        // костыльное решение, по хорошему числа в записи 1*10^2 надо привести к математической записи 1e2 и уже с ними нормально обращаться
                        if (value < 0) degree = -degree;
                        var refDiffer = '';
                        var refLess = function(coef) {
                            if (coef <= 1) {
                                refDiffer = '<*';
                            } else if (coef <= 2) {
                                refDiffer = '<<*';
                            } else if (coef <= 3) {
                                refDiffer = '<<<*';
                            } else {
                                refDiffer = '<<<<';
                            }
                        }
                        var refBigger = function(coef) {
                            if (coef <= 1) {
                                refDiffer = '*>';
                            } else if (coef <= 2) {
                                refDiffer = '*>>';
                            } else if (coef <= 3) {
                                refDiffer = '*>>>';
                            } else {
                                refDiffer = '>>>>';
                            }
                        }

                        if (degree < powDif.MINDEGREE) {
                            var coef = (powDif.MINDEGREE - degree)/(powDif.MAXDEGREE - powDif.MINDEGREE);
                            refLess(coef);
                        } else if (degree > powDif.MAXDEGREE) {
                            var coef = (degree - powDif.MAXDEGREE)/(powDif.MAXDEGREE- powDif.MINDEGREE);
                            refBigger(coef);
                        } else if (value < powDif.MINVALUE) {
                            var coef = (powDif.MINVALUE - value)/(powDif.MAXVALUE - powDif.MINVALUE);
                            refLess(coef);
                        } else if (value > powDif.MAXVALUE) {
                            var coef = (value - powDif.MAXVALUE)/(powDif.MAXVALUE - powDif.MINVALUE);
                            refBigger(coef);
                        }

                        setCaption('REF_DIFFER', refDiffer);
                        unClosureContext();
                    });

                    Form.Joursp.checkNorm();
                    Form.Joursp.setTabIndexes();
                });
            }

            Joursp.save = function(callback) {
                executeAction('Joursp.SaveAction', function() {
                    callback && callback(getVar('_VALID_STATUS'), getVar('_STATUS'));
                });
            }

            Joursp.autovalidate = function(callback) {
                executeAction('Autovalidate', function() {
                    callback && callback(getVar('_IS_VALID'));
                });
            }

            Form.beforeSaveJoursp = function(callback) {
                setVar('_LABMED_SAMPLE', currSample);
                setVar('_PUT_CELL', currPutCell);

                var warnings = [];
                var isStrVal = false;
                var isCritical = false;
                var clonesNodelist = getRepeater('RptRsrchRes0').clones(getControl('Joursp'));
                var clones = Array.prototype.slice.call(clonesNodelist); // преобразует NodeList в Array для старых ff

                clones.forEach(function(clone) {
                    closureContext(clone);

                    var valNum = getValue('ctrlVAL_NUM');

                    if (!empty(valNum)) {
                        var valNumFromStr;

                        // проверим на валидное число
                        if (/^([0-9]*[.,]?[0-9]+)$/.test(valNum)) {
                            valNumFromStr = +valNum.replace(',', '.');
                        } else {
                            valNumFromStr = parseInt(valNum.replace(/\D+/, ''));
                            if (isNaN(valNumFromStr)) {
                                isStrVal = true;
                                valNumFromStr = '';
                            }
                        }

                        setValue('ctrlVAL_NUM_hidden', valNumFromStr);
                    }

                    if (+getValue('ctrlCritical') === 1) {
                        isCritical = true;
                    }

                    unClosureContext();
                });

                if (isStrVal) warnings.push('Числовые показатели заполнены строковыми данными. Вы уверены, что хотите сохранить такой результат?');
                if (isCritical) warnings.push('Вы уверены, что хотите оповестить врача?');

                Form.checkWarnings(warnings, 0, Form.Joursp.save.bind(this, callback));
            }

            Joursp.beforeSave = Form.beforeSaveJoursp;

            Form.checkWarnings = function(warnings, position, onSuccess) {
                if (warnings[position]) {
                    showConfirm(warnings[position], null, '500', '200',
                        function() {
                            Form.checkWarnings(warnings, position + 1, onSuccess);
                        }, null, 'yesno');
                } else {
                    onSuccess();
                }
            }

            Joursp.onJourspCommentClick = function(ctrl) {
                var data = getClone(ctrl).clone.data;

                if(!empty(data['JOURSP_ID'])) {
                    Form.SetJourspCommentEx(ctrl, data['JOURSP_ID'], {
                        SAMPLE_CODE: getVar('vSAMPLE_CODE'),
                        RS_NAME: data['RS_NAME'],
                        RES_NAME: data['RES_NAME'],
                        'COMM_TEMPL': '4;0'
                    });
                } else {
                    showConfirm('Перед добалением комментариев необходимо сохранить введенные значения.<br/>' +
                            'Схранить введенные значения?', null, 500, 150, function(){
                        executeAction('AddUpdAction', function(){
                            Form.refresh();
                            //TODO: Открыть окно комментариев,
                            //      Для этого необходимо найти показатель, по которому кликнули, после рефреша датасета
                        });
                    });
                }
            }

            Joursp.printLabDynPat = function(clone, type) {
                if (!getVar('soViewLabDinamics')) {
                    executeAction('getSoViewLabDinamics');
                }
                /*СО ViewLabDinamics. 0 - Окно, 1 - Отчёт*/
                if (getVar('soViewLabDinamics') == 1) {
                    var data = getClone(clone).clone.data;
                    openD3Form('Lis/Reports/Directions/lab_dynamics_patient_call', true, {
                        width: 450,
                        height: 160,
                        vars: {
                            DS_ID: data['DIR_SERV_ID'],
                            RESEARCH_ID: data['RESEARCH_ID'],
                            /**1 - Исследование, 2 - Показатель */
                            RES_ID: type != 1 ? data['RES_ID'] : null,
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
                        RESEARCH_ID: getDataSet('Joursp.Ds').data[0].RESEARCH_ID,
                        RES_ID: getClone(clone).clone.data['RES_ID'],
                        RES_NAME: getClone(clone).clone.data['RES_NAME'],
                        TYPE: type,
                        LABMED_SAMPLE: getVar('LABMED_SAMPLE'),
                        WORK_LIST: getVar('WORK_LIST')
                      }
                    });
                }
            }

            Joursp.setStringFieldHeight = function(_clone, _data) {
                var height = _data.FIELD_HEIGHT || 1;
                closureContext(_clone);
                var control = getControl('ctrlVAL_STRING');
                if (!empty(control)) {
                    control.querySelector('textarea').attributes.rows.value = height;
                    control.querySelector('textarea').style.minHeight = '20px';
                    control.querySelector('textarea').style.height = height * 20 + 'px';
                }
                unClosureContext();
            }

            Joursp.isConfirmStatus = false;
            Joursp.arrConfirmStatus = [];
            Joursp.onAfterCloneIndexes = function(clone, data) {
                var containers = [
                    { name: 'ctrlConfirmStatusContainer', condition: data['CONFIRM'] > 0 },
                    { name: 'ctrlConfirmStatusAccept', condition: data['CONFIRM_STATUS'] == 2 },
                    { name: 'ctrlCommentContainer', condition: getVar('VIEW_MODE') != true },
                    { name: 'ctrlDocContainer', condition: getVar('VIEW_MODE') != true }
                ];

                containers.forEach(function(container) {
                    getControl(container.name).style.display = container.condition ? 'table-cell' : 'none';
                    if (container.name === 'ctrlConfirmStatusContainer') {
                        if (container.condition) {
                            Joursp.isConfirmStatus = true;
                        } else {
                            Joursp.arrConfirmStatus.push(getControl(container.name));
                        }
                    }
                });
                if(empty(data['CHECK_SHOW_PAT_DYN']) || data['CHECK_SHOW_PAT_DYN'] == 0){
                    setVisible('PrintLabDynPatRes', false);
                }
                Form.RefreshCommentIcon(getControl('ctrlComment'), data['COMMENTS']);
                Form.RefreshAttIcon(getControl('ctrlDoc'), data['DOCS']);
            }
            Joursp.onAfterCloneRow = function(_clone, _data) {
                closureContext(_clone);
                    for (var i = 0; i < 8; i++) {
                        if (getControl('ctrlCheckValue'+i)) {
                            if (+_data['CONFIRM_STATUS'] === 2) {
                                setEnabled('ctrlCheckValue'+i, false);
                            }
                        }
                    }
                unClosureContext();
            }
            Joursp.showConfirmStatus = function() {
                if (Joursp.isConfirmStatus) {
                    var thConfirmStatus = Array.prototype.slice.call(MainForm.DOM.querySelectorAll('.thConfirmStatus'));
                    thConfirmStatus.forEach(function(el) {
                        el.style.display = 'table-cell';
                    });
                    Joursp.arrConfirmStatus.forEach(function(el) {
                        el.style.display = 'table-cell';
                        closureContext(el);
                            getControl('ctrlConfirmStatus').style.display = 'none';
                        unClosureContext();
                    })
                }
            };

            Form.onAfterCloneJourspDs = function(data) {
                setVisible('ctrlIsCito', +data['IS_CITO'] === 1);
                Form.Joursp.showConfirmStatus();
            };

            Form.onCheckAllIndexes = function(dom, value) {
                var checks = MainForm.DOM.querySelectorAll('.checkValue:not(.ctrl_disable)');

                if (value) setValue('ctrlCheckValueAll', value);

                [].forEach.call(checks, function(check) {
                    if (!D3Api.hasProperty(check, 'isrepeat')) {
                        setValue(check, value ? value : getValue(dom));
                    }
                });
            }
        ]]>
    </cmpScript>

    <cmpSubForm path="Lis/Samples/subforms/joursp_scripts"/>
    <cmpAction name="getSoViewLabDinamics">
      <![CDATA[
          begin
            :SO := D_PKG_OPTIONS.GET('ViewLabDinamics',:LPU);
          end;
        ]]>
      <cmpActionVar name="LPU" src="LPU"               srctype="session"    get="LPU"/>
      <cmpActionVar name="SO"  src="soViewLabDinamics" srctype="var"        put="psoViewLabDinamics"/>
    </cmpAction>
    <cmpDataSet name="Joursp.Ds" activateoncreate="false" compile="true">
        <![CDATA[
            select t.DIR_LINE_ID,
                   t.RESEARCH_ID,
                   t.RES_ID,
                   t.RES_LINK_ID,
                   t.ALT_MEAS_ID,
                   t.RES_VAL_ID,
                   t.DIR_SERV_ID,
                   t.JOURSP_ID,
                   t.MIN_VAL,
                   t.MAX_VAL,
                   t.DATE_MASK,
                   t.IS_CITO,
                   t.NUM_PRECISION,
                   t.RS_NAME,
                   case when lrrl.NECESSARILY = 1 then t.RES_NAME || '*' else t.RES_NAME end RES_NAME,
                   t.RESULT_TYPE,
                   t.HOTKEY,
                   t.VAL_NUM_MEASURE_VALUE,
                   t.VAL_NUM_MEASURE_CAPTION,
                   t.VAL_ENUM_VALUE,
                   t.VAL_ENUM_CAPTION,
                   t.VAL_STRING_VALUE,
                   t.VAL_STRING_CAPTION,
                   t.RV_NUM,
                   t.RV_DATE,
                   t.RES_VAL,
                   t.DATE_VALUE,
                   t.NUM_VALUE,
                   t.NUM_VALUE_BMU,
                   t.STR_VALUE,
                   t.IS_JOURSP,
                   t.COMMENTS,
                   t.DOCS,
                   t.CALC_TYPE,
                   t.CONFIRM_STATUS,
                   t.ENABLED,
                   t.CONFIRM,
                   t.SAMPLE_ID,
                   t.PUT_CELL_ID,
                   t.VAL_STRING,
                   t.VAL_NUM_MEASURE,
                   t.VAL_ENUM,
                   t.VAL_DATE,
                   t.VAL_TITR_NUM,
                   t.WORTH,
                   t.ORDER_ROWNUM,
                   t.CRITICAL,
                   (select lrv.MINDEGREE || ';' || lrv.MAXDEGREE || ';' || lrv.MINVALUE || ';' || lrv.MAXVALUE
                      from D_V_LABMED_REF_VAL lrv
                     where lrv.RSRCH_RES_ID = t.RES_ID
                           and rownum = 1) POW_TEN_DIF,
                   t.REF_VALUE,
                   t.DEVICE DEVICE_ID,
                   lrrl.FIELD_HEIGHT,
                   (
		             select count(*)
                      from D_V_LABMED_RSRCH_JOURSP_BASE lrj
                           join D_V_LABMED_DIRECTION_LINE_BASE ldl on ldl.ID = lrj.DIR_LINE
                           join D_V_DIRECTION_SERVICES_BASE ds on ds.ID = ldl.DIR_SERV
                           join D_V_DIRECTIONS_BASE d on d.ID = ds.PID
                           join D_V_PERSMEDCARD_BASE p on p.ID = d.PATIENT
                     where lrj.FILL_DATE < trunc(sysdate)
                           and ldl.STATUS = 5
                           and p.ID = :PATIENT_ID
                           and lrj.CONFIRM_STATUS = 2
                           and lrj.IS_ACTUAL = 1
                           and lrj.LPU = :LPU
                           and lrj.RESULT_ID in t.RES_ID
		           ) CHECK_SHOW_PAT_DYN
              from table(D_PKG_LABMED_RSRCH_JOURSP.GET_JOURSP_DATA(fnLPU           => :LPU,
                                                                   fnLABMED_SAMPLE => :LABMED_SAMPLE,
                                                                   fnPUT_CELL      => :PUT_CELL,
                                                                   fnWORKLIST      => :WORK_LIST,
                                                                   fnVIEW_MODE     => :VIEW_MODE_NUM)) t
                   join D_V_LABMED_RSRCH_RES_LINK lrrl on lrrl.RES_RESULT = t.RES_ID
             where t.RESULT_TYPE != 5
               and lrrl.IS_SERVICE != 1
               and t.RESEARCH_ID = lrrl.RESEARCH_ID
               and t.IS_ACTUAL = 1
               @if (!empty(:DIRLINE_ID)) {
                   and exists (select null
                         from (select regexp_substr (:DIRLINE_ID, '[^;]+', 1, rownum) PR
                                 from dual
                              connect by level <= length (regexp_replace (:DIRLINE_ID, '[^;]+'))  + 1) r
                                where r.PR = t.DIR_LINE_ID)
               @}
               @if (:IS_MICRO) {
                   and t.RESEARCH_ID in (select RESEARCH_ID
                                           from D_V_LABMED_DIRECTION_LINE ldl
                                                join D_V_LABMED_RESEARCH lr on ldl.RESEARCH_ID = lr.ID
                                                left join D_V_LABMED_RESEARCH_RES lrr on lrr.pid = lr.id
                                          where lr.rtype = 1 and (lrr.RESULT_TYPE != 5 or lrr.RESULT_TYPE is null))
               @}
             order by t.WORTH desc, t.ORDER_ROWNUM asc
        ]]>
        <cmpDataSetVar name="LPU"           src="LPU"            srctype="session" />
        <cmpDataSetVar name="LOGON_DATE"    src="LOGON_DATE"     srctype="session" />
        <cmpDataSetVar name="LABMED_SAMPLE" src="_LABMED_SAMPLE" srctype="var"     />
        <cmpDataSetVar name="PUT_CELL"      src="_PUT_CELL"      srctype="var"     />
        <cmpDataSetVar name="VIEW_MODE_NUM" src="VIEW_MODE_NUM"  srctype="var"     />
        <cmpDataSetVar name="WORK_LIST"     src="WORK_LIST"      srctype="var"     />
        <cmpDataSetVar name="IS_MICRO"      src="IS_MICRO"       srctype="var"     />
        <cmpDataSetVar name="DIRLINE_ID"    src="DIRLINE_ID"     srctype="var"     />
        <cmpDataSetVar name="PATIENT_ID"    src="PATIENT_ID"        srctype="var"     />
    </cmpDataSet> <!-- Joursp.Ds -->

    <cmpDataSet name="Joursp.DsDevices">
        <![CDATA[
            select ID, D_NAME NAME
              from D_V_LABMED_DEVICES
        ]]>
    </cmpDataSet>

    <cmpAction name="Joursp.SaveAction">
        <cmpActionVar name="LABMED_SAMPLE" src="_LABMED_SAMPLE" srctype="var" />
        <cmpActionVar name="PUT_CELL"      src="_PUT_CELL"      srctype="var" />

        <cmpSubAction name="Rsrch1Action" repeatername="RptRsrch" execon="each">
            <!-- Числовое значение -->
            <cmpSubAction name="RsrchRes0Action" repeatername="RptRsrchRes0" execon="each">
                <![CDATA[
                  declare
                    nRESULT    NUMBER(17);
                    nNUM_VAL   NUMBER;
                  begin
                      if :CONFIRM_STATUS in (1, 2) then
                          D_PKG_LABMED_AV_RULES.ADD_PAR_IF_NOT_EXIST(:DS_JOURSP_ID, :LABMED_SAMPLE);
                          RETURN;
                      end if;

                      begin
                        select t1.RESULT_ID
                          into nRESULT
                          from D_V_LABMED_RSRCH_JOURSP t1
                         where t1.ID  = :DS_JOURSP_ID
                           and t1.LPU = :LPU;
                      exception when NO_DATA_FOUND then
                        D_PKG_MSG.RECORD_NOT_FOUND(:DS_JOURSP_ID, 'LABMED_RSRCH_JOURSP');
                      end;

                      if :VAL_NUM is not null then
                        begin
                          nNUM_VAL:= D_PKG_NUM_TOOLS.STR_TO_NUM(fsNUMB => :VAL_NUM);
                        exception when others then
                          d_p_exc('Числовое значение введено не корректно');
                        end;
                      end if;

                      D_PKG_LABMED_RSRCH_JOURSP.UPD(pnID => :DS_JOURSP_ID,
                                                    pnLPU => :LPU,
                                                    pnRESULT => nRESULT,
                                                    psSTR_VALUE => :psSTR_VALUE,
                                                    pnNUM_VALUE => nNUM_VAL);

                      if :CALC_TYPE != 1 then
                          if :VAL_NUM is not null then
                              D_PKG_LABMED_RSRCH_JOURSP.SET_NUM_VAL(
                                  :DS_JOURSP_ID,
                                  :LPU,
                                  D_PKG_NUM_TOOLS.STR_TO_NUM(:VAL_NUM),
                                  :VAL_NUM_MEASURE
                              );
                          end if;
                              D_PKG_LABMED_RSRCH_JOURSP.SET_STR_VAL(
                                  :DS_JOURSP_ID,
                                  :LPU,
                                  :psSTR_VALUE
                            );
                      end if;
                      D_PKG_LABMED_AV_RULES.ADD_PAR_IF_NOT_EXIST(:DS_JOURSP_ID, :LABMED_SAMPLE);
                  end;
                ]]>
                <cmpActionVar name="LPU"             src="LPU"                 srctype="session"                           />
                <cmpActionVar name="PUT_CELL"        src="_PUT_CELL"           srctype="var"                               />
                <cmpActionVar name="RES_ID"          src="_clonedata_"         srctype="var"     property="RES_ID"         />
                <cmpActionVar name="DIR_LINE_ID"     src="_clonedata_"         srctype="var"     property="DIR_LINE_ID"    />
                <cmpActionVar name="CONFIRM_STATUS"  src="_clonedata_"         srctype="var"     property="CONFIRM_STATUS" />
                <cmpActionVar name="CALC_TYPE"       src="_clonedata_"         srctype="var"     property="CALC_TYPE"      />
                <cmpActionVar name="VAL_NUM"         src="ctrlVAL_NUM_hidden"  srctype="ctrl"                              />
                <cmpActionVar name="psSTR_VALUE"     src="ctrlVAL_NUM"         srctype="ctrl"                              />
                <cmpActionVar name="VAL_NUM_MEASURE" src="ctrlVAL_NUM_MEASURE" srctype="ctrl"                              />
                <cmpActionVar name="pnCRITICAL"      src="ctrlCritical"        srctype="ctrl"                              />
                <cmpActionVar name="pnDEVICE"        src="ctrlDevice"          srctype="ctrl"                              />
                <cmpActionVar name="LABMED_SAMPLE"   src="_LABMED_SAMPLE"      srctype="var"                               />
                <cmpActionVar name="DS_JOURSP_ID"    src="_clonedata_"         srctype="var"     property="JOURSP_ID"      />
            </cmpSubAction> <!-- RsrchRes0Action -->

            <!-- Перечислимое значение -->
            <cmpSubAction name="RsrchRes1Action" repeatername="RptRsrchRes1" execon="each">
                <![CDATA[
                    declare
                        nJOURSP_ID NUMBER;

                    begin
                        if :CONFIRM_STATUS in (1, 2) then
                            D_PKG_LABMED_AV_RULES.ADD_PAR_IF_NOT_EXIST(:DS_JOURSP_ID, :LABMED_SAMPLE);
                            RETURN;
                        end if;

                        D_PKG_LABMED_RSRCH_JOURSP.FIND_OR_ADD(
                            pnLPU                 => :LPU,
                            pnDIR_LINE            => :DIR_LINE_ID,
                            pnRESULT              => :RES_ID,
                            pnPUT_CELL            => :PUT_CELL,
                            pnJOUR_SP             => nJOURSP_ID,
                            pnCONFIRM_STATUS_FIND => 1,
                            pnCONFIRM_STATUS_UPD  => 0
                        );

                        if :CALC_TYPE != 1 then
                            D_PKG_LABMED_RSRCH_JOURSP.SET_RES_VAL(nJOURSP_ID, :LPU, :VAL_ENUM);
                        end if;

                        D_PKG_LABMED_AV_RULES.ADD_PAR_IF_NOT_EXIST(nJOURSP_ID, :LABMED_SAMPLE);

                        D_PKG_LABMED_RSRCH_JOURSP.SET_CRITICAL(
                            pnID       => nJOURSP_ID,
                            pnLPU      => :LPU,
                            pnCRITICAL => :pnCRITICAL
                        );

                        D_PKG_LABMED_RSRCH_JOURSP.SET_DEVICE(
                            pnID     => nJOURSP_ID,
                            pnLPU    => :LPU,
                            pnDEVICE => :pnDEVICE
                        );
                    end;
                ]]>
                <cmpActionVar name="LPU"            src="LPU"            srctype="session"                        />
                <cmpActionVar name="PUT_CELL"       src="_PUT_CELL"      srctype="var"                            />
                <cmpActionVar name="RES_ID"         src="_clonedata_"    srctype="var"  property="RES_ID"         />
                <cmpActionVar name="DIR_LINE_ID"    src="_clonedata_"    srctype="var"  property="DIR_LINE_ID"    />
                <cmpActionVar name="CONFIRM_STATUS" src="_clonedata_"    srctype="var"  property="CONFIRM_STATUS" />
                <cmpActionVar name="CALC_TYPE"      src="_clonedata_"    srctype="var"  property="CALC_TYPE"      />
                <cmpActionVar name="VAL_ENUM"       src="ctrlVAL_ENUM"   srctype="ctrl"                           />
                <cmpActionVar name="pnCRITICAL"     src="ctrlCritical1"  srctype="ctrl"                           />
                <cmpActionVar name="pnDEVICE"       src="ctrlDevice1"    srctype="ctrl"                           />
                <cmpActionVar name="LABMED_SAMPLE"  src="_LABMED_SAMPLE" srctype="var"                            />
                <cmpActionVar name="DS_JOURSP_ID"   src="_clonedata_"    srctype="var"  property="JOURSP_ID"      />
            </cmpSubAction> <!-- RsrchRes1Action -->

            <!-- Текстовое значение -->
            <cmpSubAction name="RsrchRes2Action_data2clob" repeatername="RptRsrchRes2" execon="each" query_type="server_php">
                <![CDATA[
                    if(!class_exists('ClobBuffer'))
                        D3Api::includeCode('System/ClobBuffer');

                    $vars['CLOB_ID'] = !empty($vars['VAL_TEMPL'])
                        ? ClobBuffer::data2clob($vars['VAL_TEMPL'])
                        : null;
                ]]>
                <cmpActionVar name="VAL_TEMPL"      src="ctrlVAL_TEMPL" srctype="ctrl"                           />
                <cmpActionVar name="RES_VAL_ID"     src="_clonedata_"   srctype="var"  property="RES_VAL_ID"     />
                <cmpActionVar name="CONFIRM_STATUS" src="_clonedata_"   srctype="var"  property="CONFIRM_STATUS" />
                <cmpActionVar name="CALC_TYPE"      src="_clonedata_"   srctype="var"  property="CALC_TYPE"      />
                <cmpActionVar name="CLOB_ID"        src="CLOB_ID"       srctype="var"  put="pCLOB_ID"            />

                <cmpSubAction name="RsrchRes2_upd">
                    <![CDATA[
                        declare
                            nJOURSP_ID NUMBER;
                            clDATA     CLOB;

                        begin
                            if :CONFIRM_STATUS in (1, 2) then
                                D_PKG_LABMED_AV_RULES.ADD_PAR_IF_NOT_EXIST(:DS_JOURSP_ID, :LABMED_SAMPLE);
                                RETURN;
                            end if;

                            D_PKG_LABMED_RSRCH_JOURSP.FIND_OR_ADD(
                                pnLPU                 => :LPU,
                                pnDIR_LINE            => :DIR_LINE_ID,
                                pnRESULT              => :RES_ID,
                                pnPUT_CELL            => :PUT_CELL,
                                pnJOUR_SP             => nJOURSP_ID,
                                pnCONFIRM_STATUS_FIND => 1,
                                pnCONFIRM_STATUS_UPD  => 0
                            );
                            --
                            if :CLOB_ID is null then
                                if :IS_JOURSP = 1 then
                                    begin
                                        select t.RV_TEMPL
                                          into clDATA
                                          from D_V_LABMED_RSRCH_RES_VAL t
                                         where t.ID = :RES_VAL_ID;
                                     exception when NO_DATA_FOUND then null;
                                    end;
                                else
                                    begin
                                        select t.TEXT_VALUE
                                          into clDATA
                                          from D_V_LABMED_RSRCH_JOURSP t
                                         where t.ID = nJOURSP_ID;
                                     exception when NO_DATA_FOUND then null;
                                    end;
                                end if;
                            else
                                clDATA := D_PKG_CLOB_BUFFER.GET(:CLOB_ID, 1);
                            end if;
                            --
                            if :CALC_TYPE != 1 then
                                D_PKG_LABMED_RSRCH_JOURSP.SET_TEXT_VAL(nJOURSP_ID, :LPU, clDATA);
                            end if;

                            D_PKG_LABMED_AV_RULES.ADD_PAR_IF_NOT_EXIST(nJOURSP_ID, :LABMED_SAMPLE);

                            D_PKG_LABMED_RSRCH_JOURSP.SET_CRITICAL(
                                pnID       => nJOURSP_ID,
                                pnLPU      => :LPU,
                                pnCRITICAL => :pnCRITICAL
                            );

                            D_PKG_LABMED_RSRCH_JOURSP.SET_DEVICE(
                                pnID     => nJOURSP_ID,
                                pnLPU    => :LPU,
                                pnDEVICE => :pnDEVICE
                            );
                        end;
                    ]]>
                    <cmpActionVar name="LPU"            src="LPU"            srctype="session"                       />
                    <cmpActionVar name="PUT_CELL"       src="_PUT_CELL"      srctype="var"                           />
                    <cmpActionVar name="RES_ID"         src="_clonedata_"    srctype="var"    property="RES_ID"      />
                    <cmpActionVar name="DIR_LINE_ID"    src="_clonedata_"    srctype="var"    property="DIR_LINE_ID" />
                    <cmpActionVar name="IS_JOURSP"      src="_clonedata_"    srctype="var"    property="IS_JOURSP"   />
                    <cmpActionVar name="RES_VAL_ID"     src="RES_VAL_ID"     srctype="parent"                        />
                    <cmpActionVar name="CLOB_ID"        src="CLOB_ID"        srctype="parent"                        />
                    <cmpActionVar name="CONFIRM_STATUS" src="CONFIRM_STATUS" srctype="parent"                        />
                    <cmpActionVar name="CALC_TYPE"      src="CALC_TYPE"      srctype="parent"                        />
                    <cmpActionVar name="LABMED_SAMPLE"  src="_LABMED_SAMPLE" srctype="var"                           />
                    <cmpActionVar name="DS_JOURSP_ID"   src="_clonedata_"    srctype="var"     property="JOURSP_ID"  />
                    <cmpActionVar name="pnCRITICAL"     src="ctrlCritical2"  srctype="ctrl"                          />
                    <cmpActionVar name="pnDEVICE"       src="ctrlDevice2"    srctype="ctrl"                          />
                </cmpSubAction> <!-- RsrchRes2_upd -->
            </cmpSubAction> <!-- RsrchRes2Action_data2clob -->

            <!-- Значение дата\время -->
            <cmpSubAction name="RsrchRes3Action" repeatername="RptRsrchRes3" execon="each">
                <![CDATA[
                    declare
                        nJOURSP_ID NUMBER;

                    begin
                        if :CONFIRM_STATUS in (1, 2) then
                            D_PKG_LABMED_AV_RULES.ADD_PAR_IF_NOT_EXIST(:DS_JOURSP_ID, :LABMED_SAMPLE);
                            RETURN;
                        end if;

                        D_PKG_LABMED_RSRCH_JOURSP.FIND_OR_ADD(
                            pnLPU                 => :LPU,
                            pnDIR_LINE            => :DIR_LINE_ID,
                            pnRESULT              => :RES_ID,
                            pnPUT_CELL            => :PUT_CELL,
                            pnJOUR_SP             => nJOURSP_ID,
                            pnCONFIRM_STATUS_FIND => 1,
                            pnCONFIRM_STATUS_UPD  => 0
                        );

                        if :CALC_TYPE != 1 then
                            D_PKG_LABMED_RSRCH_JOURSP.SET_DATE_VAL(
                                nJOURSP_ID,
                                :LPU,
                                D_PKG_LABMED_RSRCH_RES_LINK.GET_DATE_BY_MASK(:DATE_MASK, :VAL_DATE)
                            );
                        end if;

                        D_PKG_LABMED_AV_RULES.ADD_PAR_IF_NOT_EXIST(nJOURSP_ID, :LABMED_SAMPLE);

                        D_PKG_LABMED_RSRCH_JOURSP.SET_CRITICAL(
                            pnID       => nJOURSP_ID,
                            pnLPU      => :LPU,
                            pnCRITICAL => :pnCRITICAL
                        );

                        D_PKG_LABMED_RSRCH_JOURSP.SET_DEVICE(
                            pnID     => nJOURSP_ID,
                            pnLPU    => :LPU,
                            pnDEVICE => :pnDEVICE
                        );
                    end;
                ]]>
                <cmpActionVar name="LPU"            src="LPU"            srctype="session"                        />
                <cmpActionVar name="PUT_CELL"       src="_PUT_CELL"      srctype="var"                            />
                <cmpActionVar name="RES_ID"         src="_clonedata_"    srctype="var"  property="RES_ID"         />
                <cmpActionVar name="DIR_LINE_ID"    src="_clonedata_"    srctype="var"  property="DIR_LINE_ID"    />
                <cmpActionVar name="DATE_MASK"      src="_clonedata_"    srctype="var"  property="DATE_MASK"      />
                <cmpActionVar name="CONFIRM_STATUS" src="_clonedata_"    srctype="var"  property="CONFIRM_STATUS" />
                <cmpActionVar name="CALC_TYPE"      src="_clonedata_"    srctype="var"  property="CALC_TYPE"      />
                <cmpActionVar name="VAL_DATE"       src="ctrlVAL_DATE"   srctype="ctrl"                           />
                <cmpActionVar name="LABMED_SAMPLE"  src="_LABMED_SAMPLE" srctype="var"                            />
                <cmpActionVar name="DS_JOURSP_ID"   src="_clonedata_"    srctype="var"  property="JOURSP_ID"      />
                <cmpActionVar name="pnCRITICAL"     src="ctrlCritical3"  srctype="ctrl"                           />
                <cmpActionVar name="pnDEVICE"       src="ctrlDevice3"    srctype="ctrl"                           />
            </cmpSubAction> <!-- RsrchRes3Action -->

            <!-- Значение типа титр -->
            <cmpSubAction name="RsrchRes4Action" repeatername="RptRsrchRes4" execon="each">
                <![CDATA[
                    declare
                        nJOURSP_ID NUMBER;

                    begin
                        if :CONFIRM_STATUS in (1, 2) then
                            D_PKG_LABMED_AV_RULES.ADD_PAR_IF_NOT_EXIST(:DS_JOURSP_ID, :LABMED_SAMPLE);
                            RETURN;
                        end if;

                        D_PKG_LABMED_RSRCH_JOURSP.FIND_OR_ADD(
                            pnLPU                   => :LPU,
                            pnDIR_LINE              => :DIR_LINE_ID,
                            pnRESULT                => :RES_ID,
                            pnPUT_CELL              => :PUT_CELL,
                            pnJOUR_SP               => nJOURSP_ID,
                            pnCONFIRM_STATUS_FIND   => 1,
                            pnCONFIRM_STATUS_UPD    => 0
                        );

                        if :CALC_TYPE != 1 then
                            D_PKG_LABMED_RSRCH_JOURSP.SET_NUM_VAL(
                                nJOURSP_ID,
                                :LPU,
                                D_PKG_NUM_TOOLS.STR_TO_NUM(:VAL_TITR_NUM),
                                null
                            );
                        end if;

                        D_PKG_LABMED_AV_RULES.ADD_PAR_IF_NOT_EXIST(nJOURSP_ID, :LABMED_SAMPLE);

                        D_PKG_LABMED_RSRCH_JOURSP.SET_CRITICAL(
                            pnID       => nJOURSP_ID,
                            pnLPU      => :LPU,
                            pnCRITICAL => :pnCRITICAL
                        );

                        D_PKG_LABMED_RSRCH_JOURSP.SET_DEVICE(
                            pnID     => nJOURSP_ID,
                            pnLPU    => :LPU,
                            pnDEVICE => :pnDEVICE
                        );
                    end;
                ]]>
                <cmpActionVar name="LPU"            src="LPU"              srctype="session"                        />
                <cmpActionVar name="PUT_CELL"       src="_PUT_CELL"        srctype="var"                            />
                <cmpActionVar name="RES_ID"         src="_clonedata_"      srctype="var"  property="RES_ID"         />
                <cmpActionVar name="DIR_LINE_ID"    src="_clonedata_"      srctype="var"  property="DIR_LINE_ID"    />
                <cmpActionVar name="CONFIRM_STATUS" src="_clonedata_"      srctype="var"  property="CONFIRM_STATUS" />
                <cmpActionVar name="CALC_TYPE"      src="_clonedata_"      srctype="var"  property="CALC_TYPE"      />
                <cmpActionVar name="VAL_TITR_NUM"   src="ctrlVAL_TITR_NUM" srctype="ctrl"                           />
                <cmpActionVar name="LABMED_SAMPLE"  src="_LABMED_SAMPLE"   srctype="var"                            />
                <cmpActionVar name="DS_JOURSP_ID"   src="_clonedata_"      srctype="var"  property="JOURSP_ID"      />
                <cmpActionVar name="pnCRITICAL"     src="ctrlCritical4"    srctype="ctrl"                           />
                <cmpActionVar name="pnDEVICE"       src="ctrlDevice4"      srctype="ctrl"                           />
            </cmpSubAction> <!-- RsrchRes4Action -->

            <!-- Строковое значение -->
            <cmpSubAction name="RsrchRes6Action" repeatername="RptRsrchRes6" execon="each">
                <![CDATA[
                    declare
                        nJOURSP_ID    NUMBER;

                    begin
                        if :CONFIRM_STATUS in (1, 2) then
                            D_PKG_LABMED_AV_RULES.ADD_PAR_IF_NOT_EXIST(:DS_JOURSP_ID, :LABMED_SAMPLE);
                            RETURN;
                        end if;

                        D_PKG_LABMED_RSRCH_JOURSP.FIND_OR_ADD(
                            pnLPU                   => :LPU,
                            pnDIR_LINE              => :DIR_LINE_ID,
                            pnRESULT                => :RES_ID,
                            pnPUT_CELL              => :PUT_CELL,
                            pnJOUR_SP               => nJOURSP_ID,
                            pnCONFIRM_STATUS_FIND   => 1,
                            pnCONFIRM_STATUS_UPD    => 0
                        );

                        if :CALC_TYPE != 1 then
                            D_PKG_LABMED_RSRCH_JOURSP.SET_STR_VAL(nJOURSP_ID, :LPU, :VAL_STRING);
                        end if;

                        D_PKG_LABMED_AV_RULES.ADD_PAR_IF_NOT_EXIST(nJOURSP_ID, :LABMED_SAMPLE);

                        D_PKG_LABMED_RSRCH_JOURSP.SET_CRITICAL(
                            pnID       => nJOURSP_ID,
                            pnLPU      => :LPU,
                            pnCRITICAL => :pnCRITICAL
                        );

                        D_PKG_LABMED_RSRCH_JOURSP.SET_DEVICE(
                            pnID     => nJOURSP_ID,
                            pnLPU    => :LPU,
                            pnDEVICE => :pnDEVICE
                        );
                    end;
                ]]>
                <cmpActionVar name="LPU"            src="LPU"            srctype="session"                           />
                <cmpActionVar name="PUT_CELL"       src="_PUT_CELL"      srctype="var"                               />
                <cmpActionVar name="RES_ID"         src="_clonedata_"    srctype="var"     property="RES_ID"         />
                <cmpActionVar name="DIR_LINE_ID"    src="_clonedata_"    srctype="var"     property="DIR_LINE_ID"    />
                <cmpActionVar name="CONFIRM_STATUS" src="_clonedata_"    srctype="var"     property="CONFIRM_STATUS" />
                <cmpActionVar name="CALC_TYPE"      src="_clonedata_"    srctype="var"     property="CALC_TYPE"      />
                <cmpActionVar name="VAL_STRING"     src="ctrlVAL_STRING" srctype="ctrl"                              />
                <cmpActionVar name="pnCRITICAL"     src="ctrlCritical6"  srctype="ctrl"                              />
                <cmpActionVar name="pnDEVICE"       src="ctrlDevice6"    srctype="ctrl"                              />
                <cmpActionVar name="LABMED_SAMPLE"  src="_LABMED_SAMPLE" srctype="var"                               />
                <cmpActionVar name="DS_JOURSP_ID"   src="_clonedata_"    srctype="var"     property="JOURSP_ID"      />
            </cmpSubAction> <!-- RsrchRes6Action -->
        </cmpSubAction> <!-- Rsrch1Action -->

        <!-- Числовое значение -->
        <cmpSubAction name="RsrchRes7Action" repeatername="RptRsrchRes7" execon="each">
            <![CDATA[
                declare
                    nJOURSP_ID NUMBER;

                begin
                    if :CONFIRM_STATUS in (1, 2) then RETURN; end if;

                    D_PKG_LABMED_RSRCH_JOURSP.FIND_OR_ADD(
                        pnLPU                 => :LPU,
                        pnDIR_LINE            => :DIR_LINE_ID,
                        pnRESULT              => :RES_ID,
                        pnPUT_CELL            => :PUT_CELL,
                        pnJOUR_SP             => nJOURSP_ID,
                        pnCONFIRM_STATUS_FIND => 1,
                        pnCONFIRM_STATUS_UPD  => 0
                    );

                    if :CALC_TYPE != 1 then
                        if :VAL_POW_TEN is not null then
                            D_PKG_LABMED_RSRCH_JOURSP.SET_NUM_VAL(
                                nJOURSP_ID,
                                :LPU,
                                D_PKG_NUM_TOOLS.STR_TO_NUM(:VAL_POW_TEN),
                                :VAL_POW_TEN_MEASURE
                            );
                        end if;

                        D_PKG_LABMED_RSRCH_JOURSP.SET_STR_VAL(
                            nJOURSP_ID,
                            :LPU,
                            :psSTR_VALUE
                        );
                    end if;

                    D_PKG_LABMED_RSRCH_JOURSP.SET_CRITICAL(
                        pnID       => nJOURSP_ID,
                        pnLPU      => :LPU,
                        pnCRITICAL => :pnCRITICAL
                    );

                    D_PKG_LABMED_RSRCH_JOURSP.SET_DEVICE(
                        pnID     => nJOURSP_ID,
                        pnLPU    => :LPU,
                        pnDEVICE => :pnDEVICE
                    );
                end;
            ]]>
            <cmpActionVar name="LPU"                 src="LPU"                     srctype="session"                        />
            <cmpActionVar name="PUT_CELL"            src="_PUT_CELL"               srctype="var"                            />
            <cmpActionVar name="RES_ID"              src="_clonedata_"             srctype="var"  property="RES_ID"         />
            <cmpActionVar name="DIR_LINE_ID"         src="_clonedata_"             srctype="var"  property="DIR_LINE_ID"    />
            <cmpActionVar name="CONFIRM_STATUS"      src="_clonedata_"             srctype="var"  property="CONFIRM_STATUS" />
            <cmpActionVar name="CALC_TYPE"           src="_clonedata_"             srctype="var"  property="CALC_TYPE"      />
            <cmpActionVar name="VAL_POW_TEN"         src="ctrlVAL_POW_TEN_hidden"  srctype="ctrl"                           />
            <cmpActionVar name="psSTR_VALUE"         src="ctrlVAL_POW_TEN"         srctype="ctrl"                           />
            <cmpActionVar name="VAL_POW_TEN_MEASURE" src="ctrlVAL_POW_TEN_MEASURE" srctype="ctrl"                           />
            <cmpActionVar name="pnCRITICAL"          src="ctrlCritical7"           srctype="ctrl"                           />
            <cmpActionVar name="pnDEVICE"            src="ctrlDevice7"             srctype="ctrl"                           />
        </cmpSubAction> <!-- RsrchRes7Action -->

        <cmpSubAction name="Rsrch2Action">
            <![CDATA[
                declare
                    nPUT       NUMBER;
                    nCONFIRMED NUMBER;

                begin
                    if :PUT_CELL is not null then
                        begin
                            select t.PID
                              into nPUT
                              from D_V_LABMED_PUT_CELLS t
                             where t.ID = :PUT_CELL;
                         exception when NO_DATA_FOUND then null;
                        end;

                        D_PKG_LABMED_PUT.SET_COMPLETE(
                            pnID  => nPUT,
                            pnLPU => :LPU
                        );

                        begin
                            select t.STATUS
                              into :STATUS
                              from D_V_LABMED_PUT_CELLS t
                             where t.ID = :PUT_CELL;
                         exception when NO_DATA_FOUND then null;
                        end;
                    else
                        D_PKG_LABMED_SAMPLES.SET_COMPLETE(
                            pnID  => :LABMED_SAMPLE,
                            pnLPU => :LPU
                        );

                        :STATUS := null;
                    end if;

                    if :STATUS = 2 then
                        :VALID_STATUS := 2;
                    elsif :STATUS = 1 then

                        begin
                            select count(1)
                              into nCONFIRMED
                              from D_V_LABMED_RSRCH_JOURSP js
                             where js.PUT_CELL = :PUT_CELL
                               and js.IS_ACTUAL = 1
                               and js.CONFIRM_STATUS = 1
                               and rownum = 1;
                         exception when NO_DATA_FOUND then nCONFIRMED := 0;
                        end;

                        if nCONFIRMED = 1 then
                            :VALID_STATUS := 1;
                        else
                            :VALID_STATUS := 0;
                        end if;
                    else
                        :VALID_STATUS := 0;
                    end if;
                end;
            ]]>
            <cmpActionVar name="LPU"           src="LPU"            srctype="session"                             />
            <cmpActionVar name="LABMED_SAMPLE" src="_LABMED_SAMPLE" srctype="var"                                 />
            <cmpActionVar name="PUT_CELL"      src="_PUT_CELL"      srctype="var"                                 />
            <cmpActionVar name="STATUS"        src="_STATUS"        srctype="var"     put="pSTATUS"       len="2" />
            <cmpActionVar name="VALID_STATUS"  src="_VALID_STATUS"  srctype="var"     put="pVALID_STATUS" len="2" />
        </cmpSubAction> <!-- Rsrch2Action -->
    </cmpAction> <!-- AddUpdAction -->

    <cmpAction name="Autovalidate">
        <![CDATA[
            declare
                nIS_AV_RULES_EXISTS NUMBER;

            begin
                select count(*)
                  into nIS_AV_RULES_EXISTS
                  from D_V_LABMED_DIRECTION_LINE_BASE dl
                       join D_V_LABMED_RESEARCH_BASE r on r.ID = dl.RESEARCH
                       join D_V_LABMED_RESEARCH_METHODS rm on rm.PID = r.ID
                       join D_V_LABMED_RM_AVR rma on rma.PID = rm.ID
                       join D_V_LABMED_AV_RULES a on a.ID = rma.AV_CAT
                 where dl.ID in (select *
                                   from table(D_PKG_LABMED_AV_RULES.GET_IDTAB_FR_IDSTR(:DIRLINE_ID)))
                   and a.IS_ACTIVE = 1
                   and rm.AUTO_VALID = 1
                   and rownum = 1;

                if nIS_AV_RULES_EXISTS = 1 then
                    :nIS_VALID := D_PKG_LABMED_AV_RULES.VALIDATE_RESEARCHES(:LABMED_SAMPLE, :DIRLINE_ID, :LPU, :WORK_LIST);
                end if;
            end;
        ]]>
        <cmpActionVar name="WORK_LIST"     src="WORK_LIST"      srctype="var"                             />
        <cmpActionVar name="LPU"           src="LPU"            srctype="session"                         />
        <cmpActionVar name="LABMED_SAMPLE" src="_LABMED_SAMPLE" srctype="var"                             />
        <cmpActionVar name="DIRLINE_ID"    src="DIRLINE_ID"     srctype="var"                             />
        <cmpActionVar name="nIS_VALID"     src="_IS_VALID"      srctype="var"     put="_IS_VALID" len="1" />
    </cmpAction>

    <table class="form-table tableIndex">
        <colgroup>
            <col width="100%"/>
            <col width="300px"/>
        </colgroup>
        <tbody dataset="Joursp.Ds"
               repeat="0"
               repeatername="RptRsrch"
               keyfield="RESEARCH_ID"
               distinct="RESEARCH_ID"
               onafter_clone="Form.onAfterCloneJourspDs(data);setVisible('PrintLabDynPatRsrch', getVar('CHECK_DYN_PAT_SAMP') == 0);">
            <tr cmptype="tmp" name="RSRCH_NAME">
                <td colspan="5">
                    <cmpLabel caption="Исследование:"/>
                    <cmpImage name="ctrlIsCito" src="Images/Icons/PopUpMenu/exclamation-red.png"/>
                    <cmpLabel class="bold" data="caption:RS_NAME"/>
                    <img cmptype="HyperLink" name="PrintLabDynPatRsrch" src="Images/Icons/graph.png" class="icon-link"
                         title="Динамика показателей по пациенту" onclick="Form.Joursp.printLabDynPat(this, 1);" style="cursor: pointer;"/>
                </td>
                <td class="thConfirmStatus" style="display:none;"></td>
            </tr>
            <tr class="tableHeader">
                <td />
                <td>
                    <table style="width: 100%">
                        <thead>
                            <th style="padding: 0; width: 25px;">!</th>
                            <th style="padding: 0; width: 120px;">Значение</th>
                            <th style="padding: 0; width: 4px;"></th>
                            <th style="padding: 0; width: 160px;">Ед.Изм.</th>
                            <th style="padding: 0; width: 160px;">Норма</th>
                            <th style="padding: 0; width: 130px;">Устройство</th>
                            <th style="padding: 0; width: 30px; text-align: center;">
                                <cmpCheckBox name="ctrlCheckValueAll" onclick="Form.onCheckAllIndexes(this);" />
                            </th>
                        </thead>
                    </table>
                </td>
                <td colspan="3" />
                <td class="thConfirmStatus" style="display:none;"></td>
            </tr>
            <tr cmpparse="true" dataset="Joursp.Ds" repeat="0" repeatername="RptRsrchResLnk" keyfield="RES_LINK_ID"
                distinct="RES_LINK_ID" parent="RptRsrch:RESEARCH_ID"
                onafter_clone="Form.Joursp.onAfterCloneIndexes(this, data);">
                <td valign="top" class="res_name">
                    <cmpLabel data="caption:RES_NAME" />
                </td>
                <td valign="top">
                    <!-- Числовое значение -->
                    <section dataset="Joursp.Ds" repeat="0" repeatername="RptRsrchRes0" keyfield="RES_LINK_ID"
                             distinct="RES_LINK_ID" condition="RESULT_TYPE=0" parent="RptRsrchResLnk:RES_LINK_ID"
                             onafter_clone="Form.Joursp.onAfterCloneRow(clone, data);"
                             >
                        <table class="tableSection">
                            <tbody>
                                <tr>
                                    <td style="border: none;">
                                        <cmpCheckBox name="ctrlCritical" data="value:CRITICAL" class="сriticalCheckBox" />
                                    </td>
                                    <td style="border: none;">
                                        <cmpEdit name="ctrlVAL_NUM" data="value:VAL_STRING;enabled:ENABLED" width="120px" mask_empty="false" class="tabElement" />
                                        <cmpEdit name="ctrlVAL_NUM_hidden" style="display: none;" />
                                        <cmpEdit name="ctrlVAL_STR_hidden" style="display: none;" />
                                    </td>
                                    <td class="p-r4" style="border: none;"/>
                                    <td style="border: none !important;">
                                        <cmpComboBox name="ctrlVAL_NUM_MEASURE" data="value:VAL_NUM_MEASURE;enabled:ENABLED"
                                                     width="160px" readonly="true" anyvalue="false" tabindex="-1" onshow="Form.setTabIndexToChildInput(this);">
                                            <cmpComboItem />
                                            <cmpComboItem data="value:VAL_NUM_MEASURE_VALUE;caption:VAL_NUM_MEASURE_CAPTION"
                                                          dataset="Joursp.Ds" repeat="0" keyfield="ALTER_MEASURE_ID"
                                                          parent="RptRsrchRes0:RES_LINK_ID"/>
                                        </cmpComboBox>
                                    </td>
                                    <td style="text-align: center; border: none;" >
                                        <cmpLabel data="caption:REF_VALUE" class="refValue" />
                                    </td>
                                    <td style="border: none;">
                                        <cmpComboBox name="ctrlDevice" data="value:DEVICE_ID" width="130px">
                                            <cmpComboItem />
                                            <cmpComboItem dataset="Joursp.DsDevices" data="value:ID;caption:NAME" repeat="0" />
                                        </cmpComboBox>
                                    </td>
                                    <td style="text-align: center; border: none;">
                                        <cmpCheckBox name="ctrlCheckValue0" class="checkValue" style="width: 30px;" />
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                        <cmpMask controls="ctrlVAL_NUM"/>
                        <cmpDependences required="!ctrlVAL_NUM" depend="ButtonAccept;ButtonSave"/>
                    </section>

                    <!-- Перечислимое значение -->
                    <section dataset="Joursp.Ds" repeat="0" repeatername="RptRsrchRes1" keyfield="RES_LINK_ID"
                             distinct="RES_LINK_ID" condition="RESULT_TYPE=1" parent="RptRsrchResLnk:RES_LINK_ID"
                             cmptype="tmp" name="RsrchRes1Container"
                             onafter_clone="Form.Joursp.onAfterCloneRow(clone, data);">
                        <table style="width: 100%;" class="tableSection">
                            <colgroup>
                                <col />
                                <col width="70" />
                                <col width="80" />
                                <col width="30" />
                            </colgroup>
                            <tbody>
                                <tr>
                                    <td style="border: none;">
                                        <cmpCheckBox name="ctrlCritical1" data="value:CRITICAL" class="сriticalCheckBox" />
                                    </td>
                                    <td colspan="2" style="border: none;">
                                        <cmpComboBox name="ctrlVAL_ENUM" data="value:VAL_ENUM;enabled:ENABLED" width="284px" class="tabElement"
                                                     readonly="true" anyvalue="false" tabindex="-1" onshow="Form.setTabIndexToChildInput(this);">
                                            <cmpComboItem />
                                            <cmpComboItem data="value:VAL_ENUM_VALUE;caption:VAL_ENUM_CAPTION"
                                                          dataset="Joursp.Ds" repeat="0" keyfield="ALTER_MEASURE_ID"
                                                          parent="RptRsrchRes1:RES_LINK_ID"/>
                                        </cmpComboBox>
                                    </td>
                                    <td style="text-align: center; border: none;">
                                        <cmpLabel data="caption:REF_VALUE" class="refValue" />
                                    </td>
                                    <td style="border: none;">
                                        <cmpComboBox name="ctrlDevice1" data="value:DEVICE_ID" width="130px">
                                            <cmpComboItem />
                                            <cmpComboItem dataset="Joursp.DsDevices" data="value:ID;caption:NAME" repeat="0" />
                                        </cmpComboBox>
                                    </td>
                                    <td style="text-align: center; border: none;">
                                        <cmpCheckBox name="ctrlCheckValue1" class="checkValue" style="width: 30px;" />
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </section>

                    <!-- Текстовое значение -->
                    <section cmpparse="true" dataset="Joursp.Ds" repeat="0" repeatername="RptRsrchRes2" keyfield="RES_LINK_ID"
                             distinct="RES_LINK_ID" condition="RESULT_TYPE=2" parent="RptRsrchResLnk:RES_LINK_ID"
                             cmptype="tmp" name="RsrchRes2Container"
                             onafter_clone="Form.Joursp.onAfterCloneRow(clone, data);">
                        <table style="width: 100%;" class="tableSection">
                            <colgroup>
                                <col width="20" />
                                <col width="285" />
                                <col />
                                <col />
                            </colgroup>
                            <tbody>
                                <tr>
                                    <td style="border: none;">
                                        <cmpCheckBox name="ctrlCritical2" data="value:CRITICAL" class="сriticalCheckBox" />
                                    </td>
                                    <td style="border: none;">
                                        <cmpHyperLink caption="Редактировать" onclick="Form.Joursp.editValTempl(this);" style="display: block; width: 100%; margin-left: 5px;" />
                                        <cmpTextArea name="ctrlVAL_TEMPL" visible="false"/>
                                    </td>
                                    <td style="text-align: center; border: none;">
                                        <cmpLabel data="caption:REF_VALUE" class="refValue" />
                                    </td>
                                    <td style="border: none;">
                                        <cmpComboBox name="ctrlDevice2" data="value:DEVICE_ID" width="130px">
                                            <cmpComboItem />
                                            <cmpComboItem dataset="Joursp.DsDevices" data="value:ID;caption:NAME" repeat="0" />
                                        </cmpComboBox>
                                    </td>
                                    <td style="text-align: center; border: none;">
                                        <cmpCheckBox name="ctrlCheckValue2" class="checkValue" style="width: 30px;" />
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </section>

                    <!-- Значение дата\время -->
                    <section cmpparse="true" dataset="Joursp.Ds" repeat="0" repeatername="RptRsrchRes3" keyfield="RES_LINK_ID"
                             distinct="RES_LINK_ID" condition="RESULT_TYPE=3" parent="RptRsrchResLnk:RES_LINK_ID"
                             onafter_clone="Form.InitDateMask(data['DATE_MASK'], getControl('maskValDate'), getControl('ctrlVAL_DATE'));Form.Joursp.onAfterCloneRow(clone, data);"
                             cmptype="tmp" name="RsrchRes3Container">
                        <table style="width: 100%;" class="tableSection">
                            <colgroup>
                                <col />
                                <col width="70" />
                                <col width="80" />
                                <col width="30" />
                            </colgroup>
                            <tbody>
                                <tr>
                                    <td style="border: none;">
                                        <cmpCheckBox name="ctrlCritical3" data="value:CRITICAL" class="сriticalCheckBox" />
                                    </td>
                                    <td style="border: none;">
                                        <cmpEdit name="ctrlVAL_DATE" data="value:VAL_DATE;placeholder:DATE_MASK;enabled:ENABLED"
                                                 mask_check_regular="^$" mask_template_regular="^$" width="284px" class="tabElement" />
                                    </td>
                                    <td style="text-align: center; border: none;">
                                        <cmpLabel data="caption:REF_VALUE" class="refValue" />
                                    </td>
                                    <td style="border: none;">
                                        <cmpComboBox name="ctrlDevice3" data="value:DEVICE_ID" width="130px">
                                            <cmpComboItem />
                                            <cmpComboItem dataset="Joursp.DsDevices" data="value:ID;caption:NAME" repeat="0" />
                                        </cmpComboBox>
                                    </td>
                                    <td style="text-align: center; border: none;">
                                        <cmpCheckBox name="ctrlCheckValue3" class="checkValue" style="width: 30px;" />
                                        <cmpMask name="maskValDate" controls=""/>
                                        <cmpDependences required="!ctrlVAL_DATE" depend="ButtonAccept;ButtonSave"/>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </section>

                    <!-- Значение типа титр -->
                    <section dataset="Joursp.Ds" repeat="0" repeatername="RptRsrchRes4" keyfield="RES_LINK_ID"
                             distinct="RES_LINK_ID" condition="RESULT_TYPE=4" parent="RptRsrchResLnk:RES_LINK_ID"
                             cmptype="tmp" name="RsrchRes4Container"
                             onafter_clone="Form.Joursp.onAfterCloneRow(clone, data);">
                        <table style="width: 100%;" class="tableSection">
                            <colgroup>
                                <col />
                                <col width="70" />
                                <col width="80" />
                                <col width="30" />
                            </colgroup>
                            <tbody>
                                <tr>
                                    <td style="border: none;">
                                        <cmpCheckBox name="ctrlCritical4" data="value:CRITICAL" class="сriticalCheckBox" />
                                    </td>
                                    <td style="border: none;">
                                        1 : <cmpEdit name="ctrlVAL_TITR_NUM" data="value:VAL_TITR_NUM;enabled:ENABLED" width="265px"
                                                     mask_is_titr="true" class="tabElement"
                                                     mask_check_function="return Form.Joursp.maskCheckFunction(this, value);"
                                                     mask_template_function="return Form.Joursp.maskTemplateFunction(this, value);"/>
                                    </td>
                                    <td style="text-align: center; border: none;">
                                        <cmpLabel data="caption:REF_VALUE" class="refValue" />
                                    </td>
                                    <td style="border: none;">
                                        <cmpComboBox name="ctrlDevice4" data="value:DEVICE_ID" width="130px">
                                            <cmpComboItem />
                                            <cmpComboItem dataset="Joursp.DsDevices" data="value:ID;caption:NAME" repeat="0" />
                                        </cmpComboBox>
                                    </td>
                                    <td style="text-align: center; border: none;">
                                        <cmpCheckBox name="ctrlCheckValue4" class="checkValue" style="width: 30px;" />
                                        <cmpMask controls="ctrlVAL_TITR_NUM"/>
                                        <cmpDependences required="!ctrlVAL_TITR_NUM" depend="ButtonAccept;ButtonSave"/>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </section>

                    <!-- Строковое значение -->
                    <section dataset="Joursp.Ds"
                             repeat="0"
                             repeatername="RptRsrchRes6"
                             keyfield="RES_LINK_ID"
                             distinct="RES_LINK_ID"
                             condition="RESULT_TYPE=6"
                             parent="RptRsrchResLnk:RES_LINK_ID"
                             onafter_clone="setValue('ctrlVAL_STRING', data['VAL_STRING']);
                                            Form.Joursp.setStringFieldHeight(clone, data);
                                            Form.Joursp.onAfterCloneRow(clone, data);"
                    >
                        <table style="width: 100%;" class="tableSection">
                            <tbody>
                                <tr>
                                    <td style="border: none;">
                                        <cmpCheckBox name="ctrlCritical6" data="value:CRITICAL" class="сriticalCheckBox" />
                                    </td>
                                    <td style="border: none;">
                                        <div class="field_string_section">
                                            <cmpComboBox name="ctrlVAL_STRING_TPL" data="enabled:ENABLED" width="284px" class="tabElement"
                                                         onchange="setValue('ctrlVAL_STRING', getCaption('ctrlVAL_STRING_TPL'));"
                                                         readonly="true" anyvalue="false" tabindex="-1" onshow="Form.setTabIndexToChildInput(this);">
                                                <cmpComboItem />
                                                <cmpComboItem data="value:VAL_STRING_VALUE;caption:VAL_STRING_CAPTION"
                                                              dataset="Joursp.Ds" repeat="0" keyfield="ALTER_MEASURE_ID"
                                                              parent="RptRsrchRes6:RES_LINK_ID"/>
                                            </cmpComboBox>
                                            <div class="field_string_fix"/>
                                            <cmpTextArea name="ctrlVAL_STRING" data="enabled:ENABLED" width="263px" rows="5" class="field_string"/>
                                        </div>
                                    </td>
                                    <td style="text-align: center; border: none;">
                                        <cmpLabel data="caption:REF_VALUE" class="refValue" />
                                    </td>
                                    <td style="border: none;">
                                        <cmpComboBox name="ctrlDevice6" data="value:DEVICE_ID" width="130px">
                                            <cmpComboItem />
                                            <cmpComboItem dataset="Joursp.DsDevices" data="value:ID;caption:NAME" repeat="0" />
                                        </cmpComboBox>
                                    </td>
                                    <td style="text-align: center; border: none;">
                                        <cmpCheckBox name="ctrlCheckValue6" class="checkValue" style="width: 30px;" />
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </section>

                    <!-- Степень десяти -->
                    <section dataset="Joursp.Ds" repeat="0" repeatername="RptRsrchRes7" keyfield="RES_LINK_ID"
                             distinct="RES_LINK_ID" condition="RESULT_TYPE=7" parent="RptRsrchResLnk:RES_LINK_ID"
                             onafter_clone="Form.Joursp.onAfterCloneRow(clone, data);">
                        <table class="tableSection">
                            <tbody>
                                <tr>
                                    <td style="border: none;">
                                        <cmpCheckBox name="ctrlCritical7" data="value:CRITICAL" class="сriticalCheckBox" />
                                        <cmpLabel name="REF_DIFFER" style="display: none;" /> <!-- display: none; Task: 223438. Comment: 40, point: 3 -->
                                    </td>
                                    <td style="border: none;">
                                        <cmpEdit name="ctrlVAL_POW_TEN" data="value:VAL_STRING;enabled:ENABLED" width="120px" mask_empty="false" class="tabElement" />
                                        <cmpEdit name="ctrlVAL_POW_TEN_hidden" style="display: none;" />
                                    </td>
                                    <td class="p-r4" style="border: none;"/>
                                    <td style="border: none;">
                                        <cmpComboBox name="ctrlVAL_POW_TEN_MEASURE" data="value:VAL_NUM_MEASURE;enabled:ENABLED"
                                                     width="160px" readonly="true" anyvalue="false" tabindex="-1" onshow="Form.setTabIndexToChildInput(this);">
                                            <cmpComboItem />
                                            <cmpComboItem data="value:VAL_NUM_MEASURE_VALUE;caption:VAL_NUM_MEASURE_CAPTION"
                                                          dataset="Joursp.Ds" repeat="0" keyfield="ALTER_MEASURE_ID"
                                                          parent="RptRsrchRes7:RES_LINK_ID"/>
                                        </cmpComboBox>
                                    </td>
                                    <td style="text-align: center; border: none;">
                                        <cmpLabel name="REF_VALUE" data="caption:REF_VALUE" class="refValue" />
                                    </td>
                                    <td style="border: none;">
                                        <cmpComboBox name="ctrlDevice7" data="value:DEVICE_ID" width="130px">
                                            <cmpComboItem />
                                            <cmpComboItem dataset="Joursp.DsDevices" data="value:ID;caption:NAME" repeat="0" />
                                        </cmpComboBox>
                                    </td>
                                    <td style="text-align: center; border: none;">
                                        <cmpCheckBox name="ctrlCheckValue7" class="checkValue" style="width: 30px;" />
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                        <cmpMask controls="ctrlVAL_POW_TEN"/>
                        <cmpDependences required="!ctrlVAL_POW_TEN" depend="ButtonAccept;ButtonSave"/>
                    </section>

                    <cmpLabel name="ctrlWarningLabel" class="warning_lable"/>
                </td>
                <td valign="top" class="p-t4">
                    <img cmptype="HyperLink" class="icon-link" name="PrintLabDynPatRes" src="Images/Icons/graph.png"
                         title="Динамика показателей по пациенту" onclick="Form.Joursp.printLabDynPat(this, 2);" style="cursor: pointer;"/>
                </td>
                <td valign="top" class="p-t4" cmptype="tmp" name="ctrlCommentContainer">
                    <img cmptype="HyperLink" class="icon-link" name="ctrlComment" src="Images/Icons/PopUpMenu/blue-document-plus.png" title="Комментарии"
                         onclick="Form.Joursp.onJourspCommentClick(this);"/>
                </td>
                <td valign="top" class="p-t4" cmptype="tmp" name="ctrlDocContainer">
                    <img cmptype="HyperLink" class="icon-link" name="ctrlDoc" src="Images/Icons/PopUpMenu/chain-plus.png" title="Документы"
                         onclick="Form.Joursp.onJourspAttrClick(this);"/>
                </td>
                <td valign="top" class="p-t4" cmptype="tmp" name="ctrlConfirmStatusContainer">
                    <img cmptype="HyperLink" class="icon-link" name="ctrlConfirmStatus" title="Отвергнутые результаты"
                         src="Images/Icons/light_cross.png" onclick="Form.Joursp.onValidationResultClick(this);"/>
                </td>
            </tr>
        </tbody>
    </table>

    <style>
        .form_joursp .icon-link {
            cursor: pointer;
            display: inline-block;
            margin-right: 5px;
            width: 16px;
            height: 16px;
        }

        .form_joursp .bold {
            font-weight: bold;
        }

        .form_joursp .text-field > div> div> textarea {
            overflow:hidden;
            min-height: 0;
        }

        .form_joursp .text-field-btn {
            opacity: .7;
            position: relative;
            float: right;
            bottom: 18px;
        }

        .form_joursp .text-field-btn:hover {
            opacity: 1;
        }

        .form_joursp .field_string_fix {
            position: relative;
            top: -21px;
            right: 21px;
            width: 1px;
            height: 20px;
            background-color: white;
            float: right;
            z-index: 100;
        }

        .form_joursp .res_name {
            padding-left: 20px;
        }

        .form_joursp .res_name > span {
            line-height: 14px;
        }

        .form_joursp .warning_lable {
            font-size: 11px;
            color:#FF8888;
        }

        .form_joursp .p-t4 {
            padding-top: 4px;
            vertical-align: middle;
        }

        .form_joursp .p-r4 {
            padding-right: 4px;
        }

        .tableIndex td {
            border: 1px solid rgba(0, 0, 0, .3);
            border-collapse: collapse;
        }

        .сriticalCheckBox {
            width: 20px;
            padding-left: 5px;
            text-align: center;
        }

        .tableIndex_noBorder {
            border: none !important;
        }

        .tableSection td {
            border: none !important:
        }

        .refValue {
            display: inline-block; width: 160px;
        }

        .form_joursp .field_string_section {
            margin-bottom: -22px;
        }

        .form_joursp .field_string {
            position: relative;
            top: -23px;
            width: 263px
        }

        .form_joursp .field_string {
            position: relative;
            top: -23px;
        }

        .form_joursp .field_string_fix {
            position: relative;
            top: -21px;
            right: 21px;
            width: 1px;
            height: 20px;
            background-color: white;
            float: right;
            z-index: 100;
        }
    </style>
</div>
