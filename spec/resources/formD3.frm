<div>
    <!--
     Форма общих действия над NR_REQUEST: смена статуса, добавление, исправление, удаление, проверка прав.
     Принимает переменные NR_REQUEST NOS_REGISTR AGENT
     functions:
        GetRights(id, callback)
            vars NOS_REGISTR
        ChangeStatus(id, status)
            vars: ~ AGENT
                  ~ NOS_REGISTR
                  ~ ChangeStatusCallback - function callback on success
        RequestDelete(id, callback)

     -->
    <cmpScript name="NrRequestScipt">
        <![CDATA[
        Form.GetRights = function(id, callback) {
            setVar('NR_REQUEST', id);
            executeAction('GetRightsNrRequest', function () {
                callback && callback(getVar('_RIGHTS'));
            });
        };
        Form.RequestDelete = function (id, _callback) {
            setVar('NR_REQUEST', id);
            var callback = function(){
                if (typeof _callback === 'function') {
                    _callback.call();
                }
            };
            executeAction('DeleteNrRequest', callback);
        };
        Form.changeStatusRequest = function(status) {
            var callback = (status == 4) ? function () {
                executeAction('getPatientRequest', function () {
                    if (getVar('NR_PATIENT')) {
                        openD3Form('NR/cancer_registr_edit', true, {
                            width: 1020, height: 700,
                            vars: {
                                NR_PATIENT: getVar('NR_PATIENT'),
                                NOS_REGISTR: getVar('NOS_REGISTR'),
                                READ_ONLY: false
                            }
                        });
                    }
                })
            } : null;
            setVar('ChangeStatusCallback', callback);
            Form.ChangeStatus(getVar('NR_REQUEST')||getValue('NR_REQ'), status);
        };
        Form.ChangeStatus = function(id, status) {
            setVar('NR_REQUEST', id);
            setVar('STATUS', status);
            setVar('NEED_ADD', 0);
            if (status == 4) {
                _callback = function () {
                    if (getVar('IS_FIRST') == 1) {
                        openD3Form('NR/subforms/include_confirm_info', true, {
                            width: 500, height: 165,
                            vars: {
                                NR_ID: id,
                                NR_NEW_STATUS: status,
                                NR_AGENT: getValue('ctrlAGENT'),
                                NOS_REGISTR: getVar('NOS_REGISTR')
                            },
                            onclose: function (mod) {
                                if (mod && mod.ModalResultOD == 1) {
                                    Form.AfterChangeStatus();
                                }
                            }
                        });
                    } else {
                        Form.PostChangeStatus();
                    }
                };
                executeAction('ChecksBeforeConfirm', function () {
                    if (!empty(getVar('WARNING'))) {
                        showConfirm(getVar('WARNING') + '\nПерезаписать данные в регистре?', 'Утверждение', null, null, _callback, emptyFunction(), 'yesno')
                    } else {
                        _callback();
                    }
                });
            } else if (status == 5) {
                // openD3Form('NR/subforms/decline_reason', true, {
                //     width: 700, height: 500})
                openD3Form('NR/subforms/decline_reason', true, {
                    width: 700, height: 500,
                    vars: {
                        'NR_ID': id,
                        'NR_NEW_STATUS': 5
                    },
                    onclose: function (mod) {
                        if (mod && mod.ModalResult == 1) {
                            Form.AfterChangeStatus();
                            refreshDataSet('DS_CASE_REQUEST');
                        }
                    }
                });
            } else if (status == 6) {
                //subforms/commentary
                Form.AddComment(id, Form.AfterChangeStatus);
            } else {
                Form.PostChangeStatus();
            }
        };

        Form.AfterChangeStatus = function () {
            var callback = function(){
                if (typeof getVar('ChangeStatusCallback') === 'function') {
                    getVar('ChangeStatusCallback').call();
                    setVar('ChangeStatusCallback', null);
                }
            }
            if (getVar('NEED_ADD') == 1){
                executeAction('AfterChangeStatus', function () {
                    if (getVar('AGENT')) {
                        getPage(0).setVar('AGENT', getVar('AGENT'));
                        var win = openWindow({
                            name: 'Persmedcard/persmedcard_add_by_agent',
                            vars: getVar('DEF_VALS')
                        }, true, 770, 650);
                        win.addListener('onshow', function () {
                            getPage().setValue('IS_REG', 1);
                            base().Reg_Patient();
                        });
                        win.onclose(callback);
                    }
                }, null, false);
            }else{
                callback.call();
            }
        };
        Form.PostChangeStatus = function () {
            executeAction('ChangeStatus', Form.AfterChangeStatus);
        };
        ]]>
    </cmpScript>
    <cmpAction name="DELETE_NR_REQ" action="DELETE" unit="NR_REQUEST">
        <cmpActionVar name="pnLPU" src="LPU"    srctype="session"/>
        <cmpActionVar name="pnID"  src="NR_REQUEST" srctype="var" get="NR_REQ"/>
    </cmpAction>

    <cmpAction name="getPatientRequest">
        begin
           select np.ID
             into :NR_PATIENT
             from D_V_NR_REQUEST nr
                  join D_V_NR_PATIENTS np on np.AGENT_ID = nr.AGENT_PAT
                                             and np.NOS_REGISTR_ID = nr.TYPE_REG
            where nr.ID = :NR_REQUEST;
        exception when NO_DATA_FOUND then
            :NR_PATIENT := null;
        end;
        <cmpActionVar name="NR_REQUEST" src="NR_REQUEST" srctype="var" get="NR_REQUEST"/>
        <cmpActionVar name="NR_PATIENT" src="NR_PATIENT" srctype="var" put="NR_PATIENT" len="17"/>
    </cmpAction>

    <cmpAction name="ChecksBeforeConfirm">
        begin
            D_PKG_NR_REQUEST.CHECKS_BEFORE_CONFIRM(pnID => :pnID, pnLPU => :pnLPU, psWARNING => :psWARNING);
            begin
                select case when p.ID is null
                              or exists(select rzd.MKB_ID
                                          from dual
                                         minus
                                        select p1.MKB_ID
                                          from D_V_ZNO_DATA p1
                                         where p1.PID = p.ID
                                           and not exists(select null from D_V_ZNO_DATA_REGISTR_OUT p2 where p2.PID = p1.ID))
                            then 1 else 0 end,
                       case when p.ID is null then 1 else 0 end
                  into :IS_FIRST,
                       :NEED_ADD
                  from D_V_NR_REQUEST t
                       join D_V_R_ZNO_DATA rzd on rzd.PID = t.ID
                       left join D_V_NR_PATIENTS p on p.NOS_REGISTR_ID = t.TYPE_REG and p.AGENT_ID = t.AGENT_PAT
                 where t.ID = :pnID
                   and not exists(select null
                                    from D_V_NR_PATIENTS p
                                         join D_V_ZNO_DATA p1 on p1.PID = p.ID
                                   where p.NOS_REGISTR_ID = t.TYPE_REG
                                     and p.AGENT_ID = t.AGENT_PAT
                                     and p1.MKB_ID = rzd.MKB_ID
                                     and not exists(select null from D_V_ZNO_DATA_REGISTR_OUT p2 where p2.PID = p1.ID));
            exception when no_data_found then
                :psWARNING := null;
                :IS_FIRST := null;
                :NEED_ADD := null;
            end;
        end;
        <cmpActionVar name="pnID"         src="NR_REQUEST"  srctype="var" get="vNR_REQUEST"/>
        <cmpActionVar name="pnLPU"        src="LPU"         srctype="session"/>
        <cmpActionVar name="psWARNING"    src="WARNING"     srctype="var" put="psWARNING" len="4000"/>
        <cmpActionVar name="IS_FIRST"     src="IS_FIRST"    srctype="var" put="pIS_FIRST" len="2"/>
        <cmpActionVar name="NEED_ADD"     src="NEED_ADD"    srctype="var" put="pNEED_ADD" len="2"/>
    </cmpAction>
    <cmpAction name="AfterChangeStatus">
        <![CDATA[
        declare
          dBIRTHDATE date;
          nAGENT number(17);
        begin
          :AGENT := null;
          begin
            select t.AGENT_PAT, coalesce((select min(d.DATE_IN) from D_V_ZNO_DATA d where d.PID = t1.ID),t1.REGISTR_DATE), t2.BIRTHDATE
              into nAGENT, :LPU_REG_DATE, dBIRTHDATE
              from D_V_NR_REQUEST t
                   join D_V_NR_PATIENTS t1 on t1.AGENT_ID = t.AGENT_PAT and t1.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0, :LPU, 'NR_PATIENTS')
                        join D_V_AGENTS_BASE t2 on t2.ID = t1.AGENT_ID
             where t.ID = :NR_REQUEST;
          exception when NO_DATA_FOUND or TOO_MANY_ROWS then
            return;
          end;
          declare
            nADDR    number(17);
            nLPU number(17);
            sRP_CODE varchar2(20);
              function get_caption(nlpu number, nid number, sunit varchar2, scomp varchar2) return varchar2
              is
              begin
                return D_PKG_SHOW_METHOD.GET_CI_IC(0, D_PKG_COMPOSITION.GET(0, sunit, scomp),null, nid, nlpu, 0);
              end;
          begin
              :REG_TYPE := 1;
              nADDR := D_PKG_AGENT_ADDRS.GET_ACTUAL_ON_DATE(nAGENT, :LPU_REG_DATE, 0);
              sRP_CODE := case when months_between(:LPU_REG_DATE, dBIRTHDATE) < 18 then '2' else '1' end;
              select D_PKG_SITE_STREETS.GET_SITE_BY_STREET_FULL(:LPU,t.STREET_ID,t.HOUSE,t.HOUSELIT,t.BLOCK,sRP_CODE,null,null)
                into :LPU_REG_LPU_SITE
                from D_V_AGENT_ADDRS t
               where t.ID = nADDR;
              select t.DIVISION_ID, l.LPUDICT_ID, l.ID
                into :DIVISION, :LPU_REG, nLPU
                from D_V_SITES t
                     join D_V_LPU l on l.ID = t.LPU
               where t.ID = :LPU_REG_LPU_SITE;
               /*обязательно должна быть определена nLPU прикрепления к этому моменту*/
              :LPU_REG_LPU_SITE_NAME := get_caption(nLPU, :LPU_REG_LPU_SITE, 'SITES', 'DIV_SITES');
              :DIVISION_NAME := get_caption(nLPU, :DIVISION, 'DIVISIONS', 'GRID');
              :LPU_REG_NAME := get_caption(nLPU, :LPU_REG, 'LPUDICT', 'LPUDICT_BY_LPU');
              select t.ID
                into :REGISTER_PURPOSE
                from D_V_REGISTER_PURPOSES t
               where t.RP_CODE = sRP_CODE
                 and t.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(1,nLPU,'REGISTER_PURPOSES');
                begin
                /*Если нашли регистрацию в найденном по участку ЛПУ, то не надо добавлять*/
                    select t.AGENT
                      into nAGENT
                      from D_V_PERSMEDCARD_BASE t
                           join D_V_PMC_REGISTRATION_BASE t1
                             on t1.PID = t.ID
                                and (t1.BEGIN_DATE <= :LPU_REG_DATE)
                                and (t1.END_DATE is null or t1.END_DATE >= :LPU_REG_DATE)
                                and t1.REGISTER_PURPOSE = :REGISTER_PURPOSE
                     where t.LPU = nLPU
                       and t.AGENT = nAGENT
                       and rownum = 1;
                exception when NO_DATA_FOUND then :AGENT := nAGENT;
                end;
          exception when NO_DATA_FOUND then null;
          end;
        end;
        ]]>
        <cmpActionVar name="LPU"                    src="LPU"                  srctype="session" />
        <cmpActionVar name="NR_REQUEST"             src="NR_REQUEST"           srctype="var"  get="gNR_REQUEST"/>
        <cmpActionVar name="AGENT"                  src="AGENT"                srctype="var"  put="pAGENT"              len="2"/>
        <cmpActionVar name="LPU_REG"                src="DEF_VALS"             srctype="var"  put="pLPU_REG"            property="LPU_REG_DEFAULT"            len="20"/>
        <cmpActionVar name="LPU_REG_NAME"           src="DEF_VALS"             srctype="var"  put="pLPU_REG_NAME"       property="LPU_REG_DEFAULT_CAPTION"    len="240"/>
        <cmpActionVar name="DIVISION"               src="DEF_VALS"             srctype="var"  put="pDIVISION"           property="DIVISION_DEFAULT"           len="20"/>
        <cmpActionVar name="DIVISION_NAME"          src="DEF_VALS"             srctype="var"  put="pDIVISION_NAME"      property="DIVISION_DEFAULT_CAPTION"   len="240"/>
        <cmpActionVar name="REGISTER_PURPOSE"       src="DEF_VALS"             srctype="var"  put="pREGISTER_PURPOSE"   property="REGISTER_PURPOSE_DEFAULT"   len="20"/>
        <cmpActionVar name="REG_TYPE"               src="DEF_VALS"             srctype="var"  put="pREG_TYPE"           property="REG_TYPE_DEFAULT"           len="20"/>
        <cmpActionVar name="LPU_REG_LPU_SITE"       src="DEF_VALS"             srctype="var"  put="pLPU_REG_LPU_SITE"   property="LPU_REG_LPU_SITE_DEFAULT"   len="20"/>
        <cmpActionVar name="LPU_REG_LPU_SITE_NAME"  src="DEF_VALS"             srctype="var"  put="pLPU_REG_LPU_SITE_NAME" property="LPU_REG_LPU_SITE_DEFAULT_CAPTION" len="20"/>
        <cmpActionVar name="LPU_REG_DATE"           src="DEF_VALS"             srctype="var"  put="pLPU_REG_DATE"       property="LPU_REG_DATE_DEFAULT"       len="20"/>
    </cmpAction>
    <cmpAction name="DeleteNrRequest" action="D_PKG_NR_REQUEST.DEL">
        <cmpActionVar name="pnLPU" src="LPU"        srctype="session"/>
        <cmpActionVar name="pnID"  src="NR_REQUEST" srctype="var" get="vNR_REQUEST"/>
    </cmpAction>
    <cmpAction name="ChangeStatusNrRequest" action="D_PKG_NR_REQUEST.SET_STATUS">
        <cmpActionVar name="pnLPU"       src="LPU"          srctype="session"/>
        <cmpActionVar name="pnID"        src="NR_REQUEST"   srctype="var" get="vNR_REQUEST"/>
        <cmpActionVar name="pnSTATUS"    src="STATUS"       srctype="var" get="gSTATUS"/>
    </cmpAction>
    <cmpAction name="GetRightsNrRequest">
        declare
          rNR_REQUEST D_V_NR_REQUEST%rowtype;
          nUPD NUMBER;
        begin

          begin
            select t.* into rNR_REQUEST from D_V_NR_REQUEST t where t.ID = :NR_REQUEST;
          exception when NO_DATA_FOUND then
            null;
          end;

          nUPD                := D_PKG_URPRIVS.CHECK_BPPRIV(:LPU,'NOS_REGISTRS_UPDATE', null, 0);
          :RIGHT_ADD          := D_PKG_CSE_ACCESSES.CHECK_RIGHT(:LPU,'NOS_REGISTRS', :NOS_REGISTR, '1')
                                   * D_PKG_URPRIVS.CHECK_BPPRIV(:LPU,'NOS_REGISTRS_INSERT', null, 0);
          :RIGHT_SHOW         := D_PKG_CSE_ACCESSES.CHECK_RIGHT(:LPU,'NR_REQUEST_STATUS', rNR_REQUEST.STATUS_ID, '3');
          :RIGHT_UPD          := 0;
          :RIGHT_DEL          := 0;
          :RIGHT_TO_UTV       := 0;
          :RIGHT_FROM_UTV     := 0;
          :RIGHT_UTV          := 0;
          :RIGHT_TO_EXP       := 0;
          :RIGHT_EXP          := 0;
          :RIGHT_CANCEL_UTV   := 0;
          :RIGHT_COMMENT      := 0;

          if nUPD = 1 and rNR_REQUEST.STATUS_ID = 1 then
            if rNR_REQUEST.CREATE_EMP = :EMPLOYER then
              :RIGHT_UPD      := 1;
            else
              :RIGHT_UPD      := D_PKG_CSE_ACCESSES.CHECK_RIGHT(:LPU,'NOS_REGISTRS',:NOS_REGISTR, '9');
            end if;
            :RIGHT_TO_UTV     := D_PKG_CSE_ACCESSES.CHECK_RIGHT(:LPU,'NR_REQUEST_STATUS', 2, '4');
            :RIGHT_DEL        := D_PKG_CSE_ACCESSES.CHECK_RIGHT(:LPU,'NOS_REGISTRS', :NOS_REGISTR, '2')
                                   * D_PKG_URPRIVS.CHECK_BPPRIV(:LPU,'NOS_REGISTRS_DELETE', null, 0);

          elsif nUPD = 1 and rNR_REQUEST.STATUS_ID = 2 then
            :RIGHT_FROM_UTV   := D_PKG_CSE_ACCESSES.CHECK_RIGHT(:LPU,'NR_REQUEST_STATUS', 1, '4');
            :RIGHT_UTV        := D_PKG_CSE_ACCESSES.CHECK_RIGHT(:LPU,'NR_REQUEST_STATUS', 4, '4');
            :RIGHT_TO_EXP     := D_PKG_CSE_ACCESSES.CHECK_RIGHT(:LPU,'NR_REQUEST_STATUS', 3, '4');
            :RIGHT_COMMENT    := D_PKG_CSE_ACCESSES.CHECK_RIGHT(:LPU,'NR_REQUEST_STATUS', 6, '4');
          elsif nUPD = 1 and rNR_REQUEST.STATUS_ID = 3 then
            :RIGHT_UTV        := D_PKG_CSE_ACCESSES.CHECK_RIGHT(:LPU,'NR_REQUEST_STATUS', 4, '4');
            :RIGHT_UPD        := D_PKG_CSE_ACCESSES.CHECK_RIGHT(:LPU,'NOS_REGISTRS', :NOS_REGISTR, '9');
            :RIGHT_EXP        := D_PKG_CSE_ACCESSES.CHECK_RIGHT(:LPU,'NR_REQUEST_STATUS', 3, '4');
            :RIGHT_COMMENT    := D_PKG_CSE_ACCESSES.CHECK_RIGHT(:LPU,'NR_REQUEST_STATUS', 6, '4');
          elsif nUPD = 1 and rNR_REQUEST.STATUS_ID = 4 then
            :RIGHT_CANCEL_UTV := D_PKG_CSE_ACCESSES.CHECK_RIGHT(:LPU,'NR_REQUEST_STATUS', 4, '4');
          elsif nUPD = 1 and rNR_REQUEST.STATUS_ID = 6 then
            if rNR_REQUEST.CREATE_EMP = :EMPLOYER then
              :RIGHT_UPD      := 1;
            else
              :RIGHT_UPD      := D_PKG_CSE_ACCESSES.CHECK_RIGHT(:LPU,'NOS_REGISTRS',:NOS_REGISTR, '9');
            end if;
            :RIGHT_TO_UTV     := D_PKG_CSE_ACCESSES.CHECK_RIGHT(:LPU,'NR_REQUEST_STATUS', 2, '4');
            :RIGHT_DEL        := D_PKG_CSE_ACCESSES.CHECK_RIGHT(:LPU,'NOS_REGISTRS', :NOS_REGISTR, '2')
                                   * D_PKG_URPRIVS.CHECK_BPPRIV(:LPU,'NOS_REGISTRS_DELETE', null, 0);
          end if;
        end;
        <cmpActionVar name="LPU"              src="LPU"         srctype="session"/>
        <cmpActionVar name="EMPLOYER"         src="EMPLOYER"    srctype="session"/>
        <cmpActionVar name="NOS_REGISTR"      src="NOS_REGISTR" srctype="var" get="NOS_REGISTR"/>
        <cmpActionVar name="NR_REQUEST"       src="NR_REQUEST"  srctype="var" get="NR_REQUEST"/>
        <cmpActionVar name="RIGHT_ADD"        src="_RIGHTS"     srctype="var" put="pRIGHT_ADD"        property="ADD"        len="1"/>
        <cmpActionVar name="RIGHT_SHOW"       src="_RIGHTS"     srctype="var" put="pRIGHT_SHOW"       property="SHOW"       len="1"/>
        <cmpActionVar name="RIGHT_UPD"        src="_RIGHTS"     srctype="var" put="pRIGHT_UPD"        property="UPD"        len="1"/>
        <cmpActionVar name="RIGHT_DEL"        src="_RIGHTS"     srctype="var" put="pRIGHT_DEL"        property="DEL"        len="1"/>
        <cmpActionVar name="RIGHT_TO_UTV"     src="_RIGHTS"     srctype="var" put="pRIGHT_TO_UTV"     property="TO_UTV"     len="1"/>
        <cmpActionVar name="RIGHT_FROM_UTV"   src="_RIGHTS"     srctype="var" put="pRIGHT_FROM_UTV"   property="FROM_UTV"   len="1"/>
        <cmpActionVar name="RIGHT_UTV"        src="_RIGHTS"     srctype="var" put="pRIGHT_UTV"        property="UTV"        len="1"/>
        <cmpActionVar name="RIGHT_TO_EXP"     src="_RIGHTS"     srctype="var" put="pRIGHT_TO_EXP"     property="TO_EXP"     len="1"/>
        <cmpActionVar name="RIGHT_EXP"        src="_RIGHTS"     srctype="var" put="pRIGHT_EXP"        property="FROM_EXP"   len="1"/>
        <cmpActionVar name="RIGHT_CANCEL_UTV" src="_RIGHTS"     srctype="var" put="pRIGHT_CANCEL_UTV" property="CANCEL_UTV" len="1"/>
        <cmpActionVar name="RIGHT_COMMENT"    src="_RIGHTS"     srctype="var" put="pRIGHT_COMMENT"    property="COMMENT"    len="1"/>
    </cmpAction>
    <cmpAction name="ChangeStatus" action="D_PKG_NR_REQUEST.SET_STATUS">
        <cmpActionVar name="pnLPU"    src="LPU"        srctype="session"/>
        <cmpActionVar name="pnID"     src="NR_REQUEST" srctype="var" get="NR_REQUEST"/>
        <cmpActionVar name="pnSTATUS" src="STATUS"     srctype="var" get="STATUS"/>
    </cmpAction>
    <cmpSubForm path="NR/subforms/commentary"/> <!-- SendComment -->
</div>