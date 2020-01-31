<div>
    <cmpScript name="myTest">
        <![CDATA[
            Form.test = function () {
                var test = 1;
            };
        ]]>
    </cmpScript>

    <cmpAction name="AddUpdAction" compile="true">
        declare
        nTYPE             NUMBER := 0;
        begin
        :NR_REQUEST := :ID;

        /* Заявка на изменение нозологического регистра */
        -- Определяем D_NR_REQUEST.TYPE
        -- если пациента нет в регистре, то 0,
        -- если он есть, то 1,
        -- если заполнена вкладка "Снятие с учета", то 2

        select count(1)
        into nTYPE
        from D_V_NR_PATIENTS p
        where p.AGENT_ID       = :AGENT
        and p.NOS_REGISTR_ID = :NOS_REGISTR
        and p.REMOVE_DATE is null
        and rownum = 1;

        if :DATE_OUT /*Дата снятия с учета*/ is not null then
        nTYPE := 2;
        end if;

        @if(!:ID){
        D_PKG_NR_REQUEST.ADD(pnD_INSERT_ID        => :NR_REQUEST,
        pnLPU                => :LPU,
        pnTYPE_REG           => :NOS_REGISTR,            -- Ссылка на D_NOS_REGISTRS
        pnNUMB               => :NUMB,                   -- Номер заявки
        pdDATE_CREATE        => :DATE_CREATE,            -- Дата формирования
        pnEMPLOYER           => :EMPLOYER,               /* Оформил (специалист)*/
        pnVISIT              => :VISIT,                  -- Посещение, на котором оформлена заявка
        pnHH_ID              => :HH_ID,                  -- ИБ, с которой сделали заявку
        pnAGENT              => :AGENT,                  -- Контрагент пациента
        pnMKB                => null,                    -- Диагноз МКБ
        pnTYPE               => nTYPE,                   -- Тип заявки (0-добавление записи, 1- изменение, 2-исключение)
        psCREATE_EMP_PHONE   => :EMP_PHONE,              -- Телефон ответственного специалиста
        pnLPUDICT            => :LPUDICT,                -- Сформировавшее ЛПУ
        pnLPU_TO             => :LPU_TO,                   -- ЛПУ, куда направляется документ);
        psNOTE               => :NOTE);
        @} else{
        D_PKG_NR_REQUEST.UPD(pnID                 => :ID,
        pnLPU                => :LPU,
        pnNUMB               => :NUMB,
        pdDATE_CREATE        => :DATE_CREATE,            -- Дата формирования
        pnEMPLOYER           => :EMPLOYER,               /* Оформил (специалист)*/
        pnVISIT              => :VISIT,                  -- Посещение, на котором оформлена заявка
        pnMKB                => null,                    -- Диагноз МКБ
        psCREATE_EMP_PHONE   => :EMP_PHONE,              -- Телефон ответственного специалиста
        pnLPUDICT            => :LPUDICT,                -- Сформировавшее ЛПУ
        pnLPU_TO             => :LPU_TO,               -- ЛПУ, куда направляется документ
        psNOTE                => :NOTE);
        @}
        end;
        <cmpActionVar name="LPU"              src="LPU"                  srctype="session"/>
        <cmpActionVar name="ID"               src="NR_REQUEST"           srctype="var"  get="gNR_REQUEST"/>
        <cmpActionVar name="NR_REQUEST"       src="NR_REQUEST"           srctype="var"  put="pNR_REQUEST"     len="17"/>
        <cmpActionVar name="NOS_REGISTR"      src="NOS_REGISTR"          srctype="var"  get="gNOS_REGISTR"/>
        <cmpActionVar name="AGENT"            src="ctrlAGENT"            srctype="ctrl" get="gAGENT"/>
        <cmpActionVar name="VISIT"            src="VISIT"                srctype="var"  get="gVISIT"/>
        <cmpActionVar name="HH_ID"            src="HH_ID"                srctype="var"  get="gHH_ID"/>
        <cmpActionVar name="NUMB"             src="ctrlNUMB"             srctype="ctrl" get="gNUMB"/>
        <cmpActionVar name="DATE_CREATE"      src="ctrlDATE_CREATE"      srctype="ctrl" get="gDATE_CREATE"/>
        <cmpActionVar name="NOTE"             src="ctrlNOTE"             srctype="ctrl" get="gNOTE"/>
        <cmpActionVar name="EMPLOYER"         src="ctrlEMPLOYER"         srctype="ctrl" get="gEMPLOYER"/>
        <cmpActionVar name="EMP_PHONE"        src="ctrlEMP_PHONE"        srctype="ctrl" get="gEMP_PHONE"/>
        <cmpActionVar name="LPUDICT"          src="ctrlLPUDICT"          srctype="ctrl" get="gLPUDICT"/>
        <cmpActionVar name="LPU_TO"           src="ctrlLPU_TO"           srctype="ctrl" get="gLPU_TO"/>

        <cmpActionVar name="DATE_OUT"         src="ctrlDATE_OUT"         srctype="ctrl" get="gDATE_OUT"/>

        <!-- Данные о риске заболевания ЗНО: Добавление/Редактирование -->
        <cmpSubAction name="ZnoRiskDataAddUpdAction">
            begin
            :RISK_DATA := :ID; -- out

            if :RISK_DATA is null then -- Add
            D_PKG_R_ZNO_RISK_DATA.ADD(pnD_INSERT_ID => :RISK_DATA,
            pnLPU         => :LPU,
            pnPID         => :NR_REQUEST,           -- Нозологические регистры: пациенты
            pdDATE_IN     => :DATE_IN,              -- Дата включения в регистр
            pnREG_KIND    => :REG_KIND,             -- Включен в регистр: 0 – первично, 1 – повторно
            pnDISCOVERED  => :DISCOVERED,           -- Заболевание выявлено
            pnSUMM_RISK   => :SUMM_RISK,            -- Суммарный риск заболевания ЗНО
            pnQUESTIONARY => :QUESTIONARY);         -- Заполненная анкета
            else -- Upd
            D_PKG_R_ZNO_RISK_DATA.UPD(pnID          => :ID,
            pnLPU         => :LPU,
            pdDATE_IN     => :DATE_IN,              -- Дата включения в регистр
            pnREG_KIND    => :REG_KIND,             -- Включен в регистр: 0 – первично, 1 – повторно
            pnDISCOVERED  => :DISCOVERED,           -- Заболевание выявлено
            pnSUMM_RISK   => :SUMM_RISK,            -- Суммарный риск заболевания ЗНО
            pnQUESTIONARY => :QUESTIONARY);         -- Заполненная анкета
            end if;
            end;
            <cmpActionVar name="LPU"          src="LPU"                  srctype="session"/>
            <cmpActionVar name="NR_REQUEST"   src="NR_REQUEST"           srctype="parent"  get="gNR_REQUEST"/>
            <cmpActionVar name="ID"           src="RISK_DATA"            srctype="var"     get="gRISK_DATA"/>
            <cmpActionVar name="RISK_DATA"    src="RISK_DATA"            srctype="var"     put="pRISK_DATA"    len="17"/>
            <cmpActionVar name="DATE_IN"      src="ctrlDATE_IN"          srctype="ctrl"    get="gDATE_IN"/>
            <cmpActionVar name="REG_KIND"     src="ctrlREG_KIND"         srctype="ctrl"    get="gREG_KIND"/>
            <cmpActionVar name="DISCOVERED"   src="ctrlDISCOVERED"       srctype="ctrl"    get="gDISCOVERED"/>
            <cmpActionVar name="SUMM_RISK"    src="ctrlSUMM_RISK"        srctype="ctrl"    get="gSUMM_RISK"/>
            <cmpActionVar name="QUESTIONARY"  src="ctrlQUESTIONARY"      srctype="ctrl"    get="gQUESTIONARY"/>

            <!-- Причины включения пациента в регистр: Удаление -->
            <cmpSubAction name="ZnoRiskDataReasons1DelAction" repeatername="RptZnoRiskDataReasons" execon="del"
                          action="D_PKG_R_ZNO_RISK_DATA_REASONS.DEL">
                <cmpActionVar name="pnLPU"                src="LPU"            srctype="session"/>
                <cmpActionVar name="pnID"                 src="_clonedata_"    srctype="var"     property="ID" get="gID"/>
            </cmpSubAction> <!-- ZnoRiskDataReasons1DelAction -->

            <!-- Причины включения пациента в регистр: Добавление\Редактирование -->
            <cmpSubAction name="ZnoRiskDataReasons2AddUpdAction" repeatername="RptZnoRiskDataReasons" execon="each">
                begin
                :D_INSERT_ID := :ID; -- out

                if :D_INSERT_ID is null then -- Add
                D_PKG_R_ZNO_RISK_DATA_REASONS.ADD(pnD_INSERT_ID => :D_INSERT_ID,
                pnLPU         => :LPU,
                pnPID         => :PID,      -- Данные о риске заболевания ЗНО: заявка
                pnREASON      => :REASON);  -- Причина включения в регистр
                else -- Upd
                D_PKG_R_ZNO_RISK_DATA_REASONS.UPD(pnID          => :ID,
                pnLPU         => :LPU,
                pnREASON      => :REASON);
                end if;
                end;
                <cmpActionVar name="LPU"                src="LPU"            srctype="session"/>
                <cmpActionVar name="ID"                 src="_clonedata_"    srctype="var"     property="ID" get="gID"/>
                <cmpActionVar name="D_INSERT_ID"        src="_clonedata_"    srctype="var"     property="ID" put="pID" len="17"/>
                <cmpActionVar name="PID"                src="RISK_DATA"      srctype="parent"  get="gPID"/>
                <cmpActionVar name="REASON"             src="ctrlREASON"     srctype="ctrl"    get="gREASON"/>
            </cmpSubAction> <!-- ZnoRiskDataReasons2AddUpdAction -->

            <!-- История изменения диагноза: Добавление/Редактирование -->
            <cmpSubAction name="ZnoRiskDataDiagns2AddUpdAction" compile="true">
                begin
                :RISK_DATA_DIAGNS := :ID; --out

                @if(:ID){
                D_PKG_R_ZNO_RISK_DATA_DIAGNS.UPD(pnID          => :ID,
                pnLPU         => :LPU,
                pnMKB         => :MKB,           -- Диагноз
                pdDATE_BEGIN  => :DATE_BEGIN,    -- Дата установления диагноза
                pdDATE_END    => :DATE_END,      -- Дата исключения диагноза
                pnDIAGN_LPU   => :DIAGN_LPU,     -- ЛПУ установления диагноза
                pnEMPLOYER    => :EMPLOYER,      -- Врач, установивший диагноз
                pnIS_FIRST    => :IS_FIRST);     -- Заболевание установлено впервые: 0 – нет, 1 – да
                @} else{
                D_PKG_R_ZNO_RISK_DATA_DIAGNS.ADD(pnD_INSERT_ID => :RISK_DATA_DIAGNS,
                pnLPU         => :LPU,
                pnPID         => :RISK_DATA,     -- Данные о риске заболевания ЗНО: заявка
                pnMKB         => :MKB,           -- Диагноз
                pdDATE_BEGIN  => :DATE_BEGIN,    -- Дата установления диагноза
                pdDATE_END    => :DATE_END,      -- Дата исключения диагноза
                pnDIAGN_LPU   => :DIAGN_LPU,     -- ЛПУ установления диагноза
                pnEMPLOYER    => :EMPLOYER,      -- Врач, установивший диагноз
                pnIS_FIRST    => :IS_FIRST);     -- Заболевание установлено впервые: 0 – нет, 1 – да
                @}
                end;
                <cmpActionVar name="LPU"              src="LPU"                     srctype="session"/>
                <cmpActionVar name="RISK_DATA"        src="RISK_DATA"               srctype="parent"  get="gRISK_DATA"/>
                <cmpActionVar name="ID"               src="RISK_DATA_DIAGNS_ID"     srctype="var"     get="gRISK_DATA_DIAGNS_ID"/>
                <cmpActionVar name="RISK_DATA_DIAGNS" src="RISK_DATA_DIAGNS_ID"     srctype="var"     put="pRISK_DATA_DIAGNS_ID"    len="17"/>
                <cmpActionVar name="MKB"              src="ctrlDIAGN_MKB"           srctype="ctrl"    get="gMKB"/>
                <cmpActionVar name="DATE_BEGIN"       src="ctrlDIAGN_DATE_BEGIN"    srctype="ctrl"    get="gDATE_BEGIN"/>
                <cmpActionVar name="DATE_END"         src="DATE_END"                srctype="var"     get="gDATE_END"/>
                <cmpActionVar name="DIAGN_LPU"        src="ctrlDIAGN_LPU"           srctype="ctrl"    get="gDIAGN_LPU"/>
                <cmpActionVar name="EMPLOYER"         src="gEMPLOYER"               srctype="var"     get="gEMPLOYER"/>
                <cmpActionVar name="IS_FIRST"         src="ctrlDIAGN_IS_FIRST"      srctype="ctrl"    get="gIS_FIRST"/>
            </cmpSubAction> <!-- ZnoRiskDataDiagns2AddUpdAction -->
        </cmpSubAction> <!-- ZnoRiskDataAddUpdAction -->

        <!-- Данные о постановке на учет в ЛПУ прикрепления: Добавление/Редактирование -->
        <cmpSubAction name="ZnoRiskDisp2AddUpdAction">
            begin
            :RISK_DISP := :ID; --out

            if :RISK_DISP is null then -- Add
            D_PKG_R_ZNO_RISK_DISP.ADD(pnD_INSERT_ID   => :RISK_DISP,
            pnLPU           => :LPU,
            pnPID           => :NR_REQUEST,         -- Нозологические регистры: пациенты
            pnDISP_LPU      => :DISP_LPU,           -- ЛПУ наблюдения
            pdREG_DATE      => :REG_DATE,           -- Дата взятия на учет
            pdREMOVE_DATE   => :REMOVE_DATE,        -- Дата прекращения наблюдения
            pnREMOVE_REASON => :REMOVE_REASON,      -- Причина прекращения наблюдения
            pnDISP_EMP      => :DISP_EMP,           -- Наблюдающий врач
            pnIS_FIRST      => :IS_FIRST);          -- Взят на учет впервые: 0 – нет, 1 – да
            else -- Upd
            D_PKG_R_ZNO_RISK_DISP.UPD(pnID            => :RISK_DISP,
            pnLPU           => :LPU,
            pnDISP_LPU      => :DISP_LPU,           -- ЛПУ наблюдения
            pdREG_DATE      => :REG_DATE,           -- Дата взятия на учет
            pdREMOVE_DATE   => :REMOVE_DATE,        -- Дата прекращения наблюдения
            pnREMOVE_REASON => :REMOVE_REASON,      -- Причина прекращения наблюдения
            pnDISP_EMP      => :DISP_EMP,           -- Наблюдающий врач
            pnIS_FIRST      => :IS_FIRST);          -- Взят на учет впервые: 0 – нет, 1 – да
            end if;
            end;
            <cmpActionVar name="LPU"              src="LPU"                     srctype="session"/>
            <cmpActionVar name="NR_REQUEST"       src="NR_REQUEST"              srctype="parent"  get="gNR_REQUEST"/>
            <cmpActionVar name="RISK_DISP"        src="RISK_DISP_ID"            srctype="var"     put="pRISK_DISP"    len="17"/>
            <cmpActionVar name="ID"               src="RISK_DISP_ID"            srctype="var"     get="gRISK_DISP_ID"/>
            <cmpActionVar name="DISP_LPU"         src="ctrlDISP_LPU"            srctype="ctrl"    get="gDISP_LPU"/>
            <cmpActionVar name="REG_DATE"         src="ctrlREG_DATE"            srctype="ctrl"    get="gREG_DATE"/>
            <cmpActionVar name="REMOVE_DATE"      src="ctrlREMOVE_DATE"         srctype="ctrl"    get="gREMOVE_DATE"/>
            <cmpActionVar name="REMOVE_REASON"    src="ctrlDISP_REMOVE_REASON"  srctype="ctrl"    get="gREMOVE_REASON"/>
            <cmpActionVar name="DISP_EMP"         src="ctrlDISP_EMP"            srctype="ctrl"    get="gDISP_EMP"/>
            <cmpActionVar name="IS_FIRST"         src="ctrlIS_FIRST"            srctype="ctrl"    get="gIS_FIRST"/>
        </cmpSubAction> <!-- ZnoRiskDisp2AddUpdAction -->

        <!-- Данные о выполнении плана диспансерного учета: Добавление/Редактирование -->
        <cmpSubAction name="ZnoRiskControlAddUpdAction" repeatername="RptZnoRiskControl" execon="each">
            declare
            nVIS_STATUS         NUMBER := 0;
            begin
            :RISK_CONTROL := :ID; --out

            -- Определяем Статус посещения
            if :NO_VISIT = 1 then
            nVIS_STATUS := 2; -- пациент не явился
            elsif :VISIT_DATE is not null then
            nVIS_STATUS := 1; -- оказана
            end if;

            if :RISK_CONTROL is null then -- Add
            D_PKG_R_ZNO_RISK_CONTROL.ADD(pnD_INSERT_ID       => :RISK_CONTROL,
            pnLPU               => :LPU ,
            pnPID               => :NR_REQUEST,          -- Заявки на изменение нозологического регистра
            pdPLAN_DATE         => :PLAN_DATE,           -- Плановая дата посещения
            pnPLAN_LPU          => :PLAN_LPU,            -- ЛПУ посещения по плану
            pdVISIT_DATE        => :VISIT_DATE,          -- Дата явки
            pnVIS_STATUS        => nVIS_STATUS,          -- Статус посещения
            pnDIRECTION_SERVICE => :DIRECTION_SERVICE,   -- Направление на услугу
            pnVIS_RESULT        => :VIS_RESULT,          -- Мониторинг контроля состояния
            pnIS_POK            => :IS_POK,
            pnABSENCE_REASON    => :C_TURNOUT);          -- Причина не явки
            else -- Upd
            D_PKG_R_ZNO_RISK_CONTROL.UPD(pnID                => :RISK_CONTROL,
            pnLPU               => :LPU ,
            pdPLAN_DATE         => :PLAN_DATE,           -- Плановая дата посещения
            pnPLAN_LPU          => :PLAN_LPU,            -- ЛПУ посещения по плану
            pdVISIT_DATE        => :VISIT_DATE,          -- Дата явки
            pnVIS_STATUS        => nVIS_STATUS,          -- Статус посещения
            pnDIRECTION_SERVICE => :DIRECTION_SERVICE,   -- Направление на услугу
            pnVIS_RESULT        => :VIS_RESULT,          -- Мониторинг контроля состояния
            pnIS_POK            => :IS_POK,
            pnABSENCE_REASON    => :C_TURNOUT);          -- Причина не явки
            end if;
            end;
            <cmpActionVar name="LPU"                src="LPU"             srctype="session"/>
            <cmpActionVar name="NR_REQUEST"         src="NR_REQUEST"      srctype="parent"  get="gNR_REQUEST"/>
            <cmpActionVar name="C_TURNOUT"          src="c_turnout"       srctype="ctrl"    get="gC_TURNOUT"/>
            <cmpActionVar name="ID"                 src="_clonedata_"     srctype="var"     property="ID" get="gRISK_CONTROL"/>
            <cmpActionVar name="RISK_CONTROL"       src="_clonedata_"     srctype="var"     property="ID" put="pRISK_CONTROL"    len="17"/>
            <cmpActionVar name="PLAN_DATE"          src="ctrlPLAN_DATE"   srctype="ctrl"    get="gPLAN_DATE"/>
            <cmpActionVar name="PLAN_LPU"           src="ctrlPLAN_LPU"    srctype="ctrl"    get="gPLAN_LPU"/>
            <cmpActionVar name="VISIT_DATE"         src="ctrlVISIT_DATE"  srctype="ctrl"    get="gVISIT_DATE"/>
            <cmpActionVar name="NO_VISIT"           src="ctrlNO_VISIT"    srctype="ctrl"    get="gNO_VISIT"/>
            <cmpActionVar name="IS_POK"             src="ctrlIS_POK"      srctype="ctrl"    get="gctrlIS_POK"/>
            <cmpActionVar name="VIS_RESULT"         src="ctrlVIS_RESULT"  srctype="ctrl"    get="gVIS_RESULT"/>
            <cmpActionVar name="DIRECTION_SERVICE"  src="_clonedata_"     srctype="var"     property="DIRECTION_SERVICE" get="gDIRECTION_SERVICE"/>

            <!-- Данные о выполнении плана диспансерного учета: результаты наблюдения: Удаление -->
            <cmpSubAction name="ZnoRiskContrRes1DelAction" repeatername="RptZnoRiskContrRes" execon="del"
                          action="D_PKG_R_ZNO_RISK_CONTR_RES.DEL">
                <cmpActionVar name="pnLPU"                src="LPU"            srctype="session"/>
                <cmpActionVar name="pnID"                 src="_clonedata_"    srctype="var"     property="ID" get="gID"/>
            </cmpSubAction> <!-- ZnoRiskContrRes1DelAction -->

            <!-- Данные о выполнении плана диспансерного учета: результаты наблюдения: Добавление/Редактирование -->
            <cmpSubAction name="ZnoRiskContrRes2AddUpdAction" repeatername="RptZnoRiskContrRes" execon="each">
                begin
                :D_INSERT_ID := :ID; -- out

                if :D_INSERT_ID is null then -- Add
                D_PKG_R_ZNO_RISK_CONTR_RES.ADD(pnD_INSERT_ID => :D_INSERT_ID,
                pnLPU         => :LPU,
                pnPID         => :PID,                      -- Данные о выполнении плана диспансерного учета: заявки
                pnLPU_TO      => :LPU_TO,                   -- ЛПУ, в которое направлен пациент
                pdREC_DATE    => :REC_DATE,                 -- Дата и время записи на услугу
                pnSERVICe     => :SERVICE,                  -- Услуга, на которую направлен пациент
                pnDIRECTION_SERVICE => :DIRECTION_SERVICE); -- Направление на услугу
                else -- Upd
                D_PKG_R_ZNO_RISK_CONTR_RES.UPD(pnID          => :D_INSERT_ID,
                pnLPU         => :LPU,
                pnLPU_TO      => :LPU_TO,
                pdREC_DATE    => :REC_DATE,
                pnSERVICe     => :SERVICE,
                pnDIRECTION_SERVICE => :DIRECTION_SERVICE);
                end if;
                end;
                <cmpActionVar name="LPU"                src="LPU"            srctype="session"/>
                <cmpActionVar name="D_INSERT_ID"        src="_clonedata_"    srctype="var"     property="ID" put="gID"  len="17"/>
                <cmpActionVar name="ID"                 src="_clonedata_"    srctype="var"     property="ID" get="gID"/>
                <cmpActionVar name="PID"                src="RISK_CONTROL"   srctype="parent"  get="gPID"/>
                <cmpActionVar name="LPU_TO"             src="ctrlREС_LPU_TO" srctype="ctrl"    get="gLPU_TO"/>
                <cmpActionVar name="REC_DATE"           src="ctrlREC_DATE"   srctype="ctrl"    get="gREC_DATE"/>
                <cmpActionVar name="SERVICE"            src="ctrlSERVICE"    srctype="ctrl"    get="gSERVICE"/>
                <cmpActionVar name="DIRECTION_SERVICE"  src="_clonedata_"    srctype="var"     property="DIRECTION_SERVICE" get="gDIRECTION_SERVICE"/>
            </cmpSubAction> <!-- ZnoRiskContrRes2UpdAction -->
        </cmpSubAction> <!-- ZnoRiskControlAddUpdAction -->
        <!-- Данные о выполнении плана диспансерного учета: Удаление -->
        <cmpSubAction name="ZnoRiskControl1DelAction" repeatername="RptZnoRiskControl" execon="del"
                      action="D_PKG_R_ZNO_RISK_CONTROL.DEL">
            <cmpActionVar name="pnLPU"                src="LPU"            srctype="session"/>
            <cmpActionVar name="pnID"                 src="_clonedata_"     srctype="var"     property="ID" get="gRISK_CONTROL1"/>
        </cmpSubAction> <!-- ZnoRiskControl1DelAction -->
        <!-- Данные о снятии пациента с учета: Добавление/Редактирование/Удаление -->
        <cmpSubAction name="ZnoRiskOutAction">
            begin
            :RISK_OUT := :ID; -- out

            -- Если заполнено поле Дата снятия с учета, то добавляем\редактируем данные
            -- если не заполнено - удаляем
            if :DATE_OUT is not null and :RISK_OUT is null then -- Add
            D_PKG_R_ZNO_RISK_OUT.ADD(pnD_INSERT_ID    => :RISK_OUT,
            pnLPU            => :LPU,
            pnPID            => :NR_REQUEST,         -- Заявки на изменение нозологического регистра
            pdDATE_OUT       => :DATE_OUT,           -- Дата исключения из регистра
            pnREMOVE_REASON  => :REMOVE_REASON,      -- Причина прекращения наблюдения
            pnDEATH_REASON   => :DEATH_REASON,       -- Причина смерти
            pnAUTOPSY        => :AUTOPSY,            -- Проводилась ли аутопсия
            pnRESULT_AUTOPSY => :RESULT_AUTOPSY);    -- Результат аутопсии
            elsif :DATE_OUT is not null and :RISK_OUT is not null then  -- Upd
            D_PKG_R_ZNO_RISK_OUT.UPD(pnID             => :RISK_OUT,
            pnLPU            => :LPU,
            pdDATE_OUT       => :DATE_OUT,           -- Дата исключения из регистра
            pnREMOVE_REASON  => :REMOVE_REASON,      -- Причина прекращения наблюдения
            pnDEATH_REASON   => :DEATH_REASON,       -- Причина смерти
            pnAUTOPSY        => :AUTOPSY,            -- Проводилась ли аутопсия
            pnRESULT_AUTOPSY => :RESULT_AUTOPSY);    -- Результат аутопсии
            elsif :RISK_OUT is not null then -- Del
            D_PKG_R_ZNO_RISK_OUT.DEL(:RISK_OUT, :LPU);
            end if;
            end;
            <cmpActionVar name="LPU"              src="LPU"                  srctype="session"/>
            <cmpActionVar name="NR_REQUEST"       src="NR_REQUEST"           srctype="parent"  get="gNR_REQUEST"/>
            <cmpActionVar name="ID"               src="RISK_OUT"             srctype="var"     get="gRISK_OUT"/>
            <cmpActionVar name="RISK_OUT"         src="RISK_OUT"             srctype="var"     put="pRISK_OUT"    len="17"/>
            <cmpActionVar name="DATE_OUT"         src="ctrlDATE_OUT"         srctype="ctrl"    get="gDATE_OUT"/>
            <cmpActionVar name="REMOVE_REASON"    src="ctrlREMOVE_REASON"    srctype="ctrl"    get="gREMOVE_REASON"/>
            <cmpActionVar name="DEATH_REASON"     src="ctrlDEATH_REASON"     srctype="ctrl"    get="gDEATH_REASON"/>
            <cmpActionVar name="AUTOPSY"          src="ctrlAUTOPSY"          srctype="ctrl"    get="gAUTOPSY"/>
            <cmpActionVar name="RESULT_AUTOPSY"   src="ctrlRESULT_AUTOPSY"   srctype="ctrl"    get="gRESULT_AUTOPSY"/>
        </cmpSubAction> <!-- ZnoRiskOutAction -->

        <!-- Данные о родственниках пациента: Удаление -->
        <cmpSubAction name="RptZnoRiskRelatives1DelAction" repeatername="RptZnoRiskRelatives" execon="del"
                      action="D_PKG_R_ZNO_RISK_RELATIVES.DEL">
            <cmpActionVar name="pnLPU"              src="LPU"                  srctype="session"/>
            <cmpActionVar name="pnID"               src="_clonedata_"          srctype="var"      property="ID"  get="gID"/>
        </cmpSubAction> <!-- RptZnoRiskRelatives1DelAction -->

        <!-- Данные о родственниках пациента: Добавление/Редактирование -->
        <cmpSubAction name="RptZnoRiskRelatives2AddUpdAction" repeatername="RptZnoRiskRelatives" execon="each">
            declare
            nIS_ADDED       NUMBER;
            rAGENT_REL      D_V_AGENTS_BASE%rowtype; --Контрагент родственник
            nAGENT_REL      NUMBER;
            begin
            :D_INSERT_ID := :ID; -- out

            -- проверим есть-ли такой родственник у текущего контрагента
            select count(1)
            into nIS_ADDED
            from D_V_AGENT_RELATIVES t
            where t.PID = :AGENT
            and t.AGENT_ID = :RELATIVE;

            -- ели родственник не прикреплен к контрагенту - добавим его
            if nIS_ADDED = 0 then
            select t.*
            into rAGENT_REL
            from D_V_AGENTS_BASE t
            where t.ID = :RELATIVE;

            -- Добавление контрагента родственника
            D_PKG_AGENT_RELATIVES.ADD(pnD_INSERT_ID  => nAGENT_REL,
            pnLPU          => :LPU,
            pnPID          => :AGENT,               -- Контрагент
            pnRELATIONSHIP => :RELATIONSHIP,        -- Степень родства
            pnAGENT        => rAGENT_REL.ID ,       -- Контрагент родственник
            psFIRSTNAME    => rAGENT_REL.FIRSTNAME, -- Имя
            psSURNAME      => rAGENT_REL.SURNAME,   -- Фамилия
            psLASTNAME     => rAGENT_REL.LASTNAME,  -- Отчество
            pdBIRTHDATE    => rAGENT_REL.BIRTHDATE, -- Дата рождения
            psAR_CODE      => null,                 -- Код родственника
            pnREPRESENT    => 0,                    -- Признак представителя
            pnLEGAL_STATUS => null);                -- Юридический статус представителя
            end if;

            -- Добавление/редактирование данных о родственнике пациента
            if :D_INSERT_ID is null then -- Add
            D_PKG_R_ZNO_RISK_RELATIVES.ADD(pnD_INSERT_ID  => :D_INSERT_ID,
            pnLPU          => :LPU,
            pnPID          => :PID,              -- Нозологические регистры: пациенты
            pnRELATIVE     => :RELATIVE,         -- Родственник
            pnINVITED      => :INVITED);         -- Вызывался на обследование: 0 – нет, 1 – да

            else -- Upd
            D_PKG_R_ZNO_RISK_RELATIVES.UPD(pnID           => :D_INSERT_ID,
            pnLPU          => :LPU,
            pnRELATIVE     => :RELATIVE,         -- Родственник
            pnINVITED      => :INVITED);         -- Вызывался на обследование: 0 – нет, 1 – да
            end if;
            end;
            <cmpActionVar name="LPU"                src="LPU"                  srctype="session"/>
            <cmpActionVar name="ID"                 src="_clonedata_"          srctype="var"      property="ID"   get="gID" />
            <cmpActionVar name="D_INSERT_ID"        src="_clonedata_"          srctype="var"      property="ID"   put="pID"       len="17"/>
            <cmpActionVar name="PID"                src="NR_REQUEST"           srctype="parent"   get="gPID"/>
            <cmpActionVar name="AGENT"              src="AGENT"                srctype="parent"   get="gAGENT"/>
            <cmpActionVar name="RELATIVE"           src="ctrlRELATIVE"         srctype="ctrl"     get="gRELATIVE" put="pRELATIVE" len="17"/>
            <cmpActionVar name="INVITED"            src="ctrlINVITED"          srctype="ctrl"     get="gINVITED"/>
            <cmpActionVar name="RELATIONSHIP"       src="ctrlRELATIONSHIP"     srctype="ctrl"     get="gRELATIONSHIP"/>
        </cmpSubAction> <!-- RptZnoRiskRelatives2AddUpdAction -->

        <cmpSubAction name="AfterExecuteAction" execlast="true">
            begin
            if :INC_TO_REGISTR is not null then
            D_PKG_NR_REQUEST.SET_STATUS(:NR_REQUEST, :LPU, 4);
            end if;
            end;
            <cmpActionVar name="LPU"              src="LPU"                  srctype="session"/>
            <cmpActionVar name="NR_REQUEST"         src="NR_REQUEST"           srctype="parent"   get="gNR_REQUEST"/>
            <cmpActionVar name="INC_TO_REGISTR"     src="_INC_TO_REGISTR"      srctype="var"      get="gINC_TO_REGISTR"/>
        </cmpSubAction>
    </cmpAction> <!-- AddUpdAction -->

    <cmpDataSet name="Details.dsEmployers" activateoncreate="false" compile="true">
        <cmpSubSelect name="emp_se">
            <![CDATA[
            select emp.EMP_ID ID,
				   emp.EMP_ID,
                   emp.EMP_NAME,
                   emp.KOD_VRACHA
              from D_V_EMP_CAB_SERV emp
             where emp.CABLAB          = :CAB_ID
               and emp.LPU         = coalesce(:LPU_DS,:LPU)
               and emp.SERVICE  = :SERVICES
               and (emp.IS_DISMISSED = 0
                    or (emp.IS_DISMISSED = 1 and emp.DISMISS_DATE >= trunc(to_date(:DS_REC_DATE,'dd.mm.yyyy hh24:mi'))))
               and (exists(select null
                            from D_V_CLEMPS_BASE cle
                           where cle.PID = emp.CABLAB
                             and cle.EMPLOYER = emp.EMP_ID
                             and cle.WORK_FROM <= trunc(to_date(:DS_REC_DATE, D_PKG_STD.FRM_DT))
                             and (cle.WORK_TO is null or cle.WORK_TO >= trunc(to_date(:DS_REC_DATE, D_PKG_STD.FRM_DT))))
                or not exists (select null
                                 from D_V_CLEMPS_BASE cle
                                where cle.PID = emp.CABLAB
                                  and cle.EMPLOYER = emp.EMP_ID))

            order by EMP_NAME
            ]]>
        </cmpSubSelect>
        <cmpDataSetVar name="LPU"         src="LPU"         srctype="session"/>
        <cmpDataSetVar name="LPU_DS"      src="LPU_DS"      srctype="var"    get="v0"/>
        <cmpDataSetVar name="subselect"   src="emp_sub"     srctype="var"    get="v1"/>
        <cmpDataSetVar name="SERV_ID"     src="SERV_ID"     srctype="var"    get="v2"/>
        <cmpDataSetVar name="SERVICES"    src="SERVICES"    srctype="ctrl"   get="v3"/>
        <cmpDataSetVar name="EMP_ID"      src="EMP_ID"      srctype="var"    get="v4"/>
        <cmpDataSetVar name="CAB_ID"      src="CAB_ID"      srctype="var"    get="v5"/>
        <cmpDataSetVar name="DS_REC_DATE" src="DS_REC_DATE" srctype="var"    get="v6"/>
    </cmpDataSet>
</div>