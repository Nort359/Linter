<div cmptype="Form" onshow="base().onShow()" oncreate="base().onCreate();" style="padding: 2rem;">

    <component cmptype="Script" name="MainScript">
        <![CDATA[
            Form.onCreate = function() {
                if (+getVar('DIRSERV') === 0) {
                    setVar('DIRSERV', getVar('DIR_SERVICE'));
                }

                if (getVar('TALON') != 0) {
                    executeAction('getIsOnkoTALON', function() {
                        refreshDataSet('DS_MAIN_INFO');
                        refreshDataSet('DS_DIRECTIONS');
                    });
                } else {
                    executeAction('getIsOnkoDIRSERV', function() {
                        refreshDataSet('DS_MAIN_INFO');
                        refreshDataSet('DS_DIRECTIONS');
                    });
                }
            }
        ]]>
    </component>

    <span style="display:none;" id="PrintSetup" ps_paperData="9" ps_orientation="portrait" ps_marginLeft="4" ps_marginTop="4" ps_marginRight="4" ps_marginBottom="4"/>

    <component cmptype="Action" name="getIsOnkoTALON">
        <![CDATA[
           begin
                select onk.IS_ONKO
                  into :IS_ONKO
                  from  D_V_AMB_TALONS_BASE at
                        join D_V_AMB_TALON_MKBS diagn on diagn.PID = at.ID
                        join D_V_AT_MKB_ONKO onk on onk.PID = diagn.ID
                 where at.ID = :pnTALON;
             exception when NO_DATA_FOUND then :IS_ONKO := 0;
            end;
        ]]>
        <component cmptype="ActionVar" name="IS_ONKO" src="IS_ONKO" srctype="var" put="pnIS_ONKO"/>
        <component cmptype="ActionVar" name="pnAGENT" src="AGENT" srctype="var" get="pnAGENT"/>
        <component cmptype="ActionVar" name="pnTALON" src="TALON" srctype="var" get="pnTALON"/>
        <component cmptype="ActionVar" name="pnDIRSERV" src="DIRSERV" srctype="var" get="pnDIRSERV"/>
    </component>

    <component cmptype="Action" name="getIsOnkoDIRSERV">
        <![CDATA[
            begin
                select vf.NUM_VALUE
                  into :IS_ONKO
                  from D_V_VISIT_FIELDS vf
                       join D_V_VISITS vs on vs.ID = vf.PID
                 where vf.TEMPLATE_FIELD = 'DS_ONK'
                   and vs.PID = :pnDIRSERV;
             exception when NO_DATA_FOUND then :IS_ONKO := 0;
            end;
        ]]>
        <component cmptype="ActionVar" name="IS_ONKO"      src="IS_ONKO"    srctype="var" put="pnIS_ONKO"   />
        <component cmptype="ActionVar" name="pnAGENT"      src="AGENT"      srctype="var" get="pnAGENT"     />
        <component cmptype="ActionVar" name="pnTALON"      src="TALON"      srctype="var" get="pnTALON"     />
        <component cmptype="ActionVar" name="pnDIRSERV"    src="DIRSERV"    srctype="var" get="pnDIRSERV"   />
    </component>

    <component cmptype="DataSet" name="DS_MAIN_INFO" activateoncreate="false" compile="true">
         <![CDATA[
             @if(:pnTALON != 0){
                  ---------------------------------- ФИО для печати из талона ------------------------------------------
                with fio as (select pmc.SURNAME || ' ' || pmc.FIRSTNAME || ' ' || pmc.LASTNAME FIO -- ФИО пациента
                               from D_V_AMB_TALONS at
                                    join D_V_PERSMEDCARD_FIO pmc on pmc.ID = at.PERSMEDCARD
                                    join D_V_AGENTS_BASE ag on ag.ID = pmc.AGENT
                              where at.ID = :pnTALON),
                     --------------------------------- Диагноз по МКБ для печати из талона ------------------------------
                mkb as (select diagn.MKB,
                               case
                                    when diagn.MKB = 'D70' or diagn.IS_MAIN_ID = 0 then diagn.MKB || ' ' || diagn.MKB_NAME else null
                               end
                               ||
                               case
                                    when diagn.MKB = 'D70' or diagn.IS_MAIN_ID = 0
                                     and (diagn.MKB between 'C00' and 'C80') and diagn.IS_MAIN_ID = 2
                                         then ', ' else null
                               end
                               ||
                               case
                                    when (diagn.MKB between 'C00' and 'C80') and diagn.IS_MAIN_ID = 2
                                         then diagn.MKB || ' ' || diagn.MKB_NAME else null
                               end DIAGNOSIS
                          from D_V_AMB_TALONS_BASE at
                               join D_V_AMB_TALON_MKBS diagn on diagn.PID = at.ID
                         where at.ID = :pnTALON),

                onko as (select onk.STAGE, onk.METASTASES,
                                case
                                     when ovc.CODE = 0 then 0 else 1
                                end NOT_FIRST,
                                onk.STAGE_T,
                                onk.STAGE_N,
                                onk.STAGE_M,
                                ovc.NAME CATEGORY
                           from D_V_AMB_TALONS_BASE at
                                join D_V_AMB_TALON_MKBS diagn on diagn.PID = at.ID
                                join D_V_AT_MKB_ONKO onk on onk.PID = diagn.ID
                                join D_V_R_ONKO_VISIT_CAUSE ovc on ovc.ID = onk.VISIT_CAUSE
                          where ovc.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0, :pnLPU, 'R_ONKO_VISIT_CAUSE')
                            and at.ID = :pnTALON)
             @}
             @if(:pnDIRSERV != 0 ){
               with fio as (select  pmc.SURNAME || ' ' || pmc.FIRSTNAME || ' ' || pmc.LASTNAME FIO -- ФИО пациента
                              from D_V_VISITS vs
                                   join D_V_DIRECTION_SERVICES_BASE ds on ds.ID = vs.PID
                                   join D_V_DIRECTIONS_BASE d on d.ID = ds.PID
                                   join D_V_PERSMEDCARD pmc on pmc.ID = d.PATIENT
                             where vs.PID = :pnDIRSERV),
                          ----------------------------------- Диагноз по МКБ-10-----------------------------------------
                mkb as (select vd.MKB_CODE MKB,
                               case
                                    when vd.MKB_CODE = 'D70' or vd.IS_MAIN = 0 then vd.MKB else null
                               end
                               ||
                               case
                                    when vd.MKB_CODE = 'D70' or vd.IS_MAIN = 0
                                         and (vd.MKB_CODE between 'C00' and 'C80') and vd.IS_MAIN = 2
                                         then ', ' else null
                               end
                               ||
                               case
                                    when (vd.MKB_CODE between 'C00' and 'C80') and vd.IS_MAIN = 2 then vd.MKB else null
                               end DIAGNOSIS
                          from D_V_VIS_DIAGNOSISES vd
                               join D_V_VISITS_BASE vs on vs.ID = vd.PID
                         where vs.PID = :pnDIRSERV),
                              -------------------------------  Стадия заболевания   -----------------------------
                stage as (select s.NAME stage
                            from D_V_VISIT_FIELDS vf
                                 join D_V_VISITS_BASE vs on vs.ID = vf.PID and vf.TEMPLATE_FIELD = 'CR_OPUH_STAGE'
                                 join D_V_R_ONKO_STAGES s on to_char(s.CODE) = vf.STR_VALUE
                           where s.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0, :pnLPU, 'R_ONKO_STAGES')
                             and vs.pid = :pnDIRSERV),
                               ------------------------------- Стадия заболевания по TNM ----------------------------
                tnt as (select t.name CR_T
                          from D_V_VISIT_FIELDS vf
                               join D_V_VISITS_BASE vs on vs.ID = vf.PID and vf.TEMPLATE_FIELD = 'CR_T'
                               join D_V_R_ONKO_TNM_T t on to_char(t.CODE) = vf.STR_VALUE
                         where t.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0, :pnLPU, 'R_ONKO_TNM_T')
                           and vs.PID = :pnDIRSERV),

                tnn as (select n.name CR_N
                          from D_V_VISIT_FIELDS vf
                               join D_V_VISITS_BASE vs on vs.ID = vf.pid and vf.TEMPLATE_FIELD = 'CR_N'
                               join D_V_R_ONKO_TNM_N n on to_char(n.CODE) = vf.STR_VALUE
                         where n.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0,:pnLPU,'R_ONKO_TNM_N')
                           and vs.pid = :pnDIRSERV),

                tnm as (select m.name CR_M
                          from D_V_VISIT_FIELDS vf
                               join D_V_VISITS_BASE vs on vs.ID = vf.PID and vf.TEMPLATE_FIELD = 'CR_M'
                               join D_V_R_ONKO_TNM_M m on to_char(m.CODE) = vf.STR_VALUE
                         where m.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0, :pnLPU, 'R_ONKO_TNM_M')
                           and vs.PID = :pnDIRSERV),
                         ----------------------------- Наличие отдаленных метостазов ----------------------------
                meta as (select vf.num_value metastases
                               from D_V_VISIT_FIELDS vf
                                    join D_V_VISITS_BASE vs on vs.ID = vf.pid and vf.TEMPLATE_FIELD='CR_OTDAL_META'
                               WHERE vs.pid = :pnDIRSERV),
                           ----------------------- Впервые ли выявлено заболевание и категория пациента-----------
                cat as (select case when s.CODE = 0 then s.CODE else 1 end not_first,
                               s.NAME
                          from D_V_VISIT_FIELDS vf
                               join D_V_VISITS_BASE vs on vs.ID = vf.PID and vf.TEMPLATE_FIELD = 'CR_PACIENT_KAT'
                               join D_V_R_ONKO_VISIT_CAUSE s on s.CODE = vf.NUM_VALUE
                         WHERE s.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0, :pnLPU, 'R_ONKO_VISIT_CAUSE')
                           and vs.PID = :pnDIRSERV)
             @}
                select
                       fio.FIO,
                       @if(:IS_ONKO == 1){
                            mkb.DIAGNOSIS DIAGN_P      --Диагноз по МКБ при подозрении на злокачественные новообразования
                       @}else{
                            mkb.DIAGNOSIS DIAGN,
                            case when mkb.DIAGNOSIS is not null then mkb.MKB else null end MKB,
                       @}
                       @if(:pnDIRSERV !=0 and :IS_ONKO == 0){
                               stage.STAGE,
                               tnt.CR_T TNT,
                               tnn.CR_N TNN,
                               tnm.CR_M TNM,
                               meta.METASTASES,
                               cat.NOT_FIRST,
                               cat.NAME CATEGORY
                       @}
                        @if(:pnTALON !=0 and :IS_ONKO ==0){
                               onko.STAGE,
                               onko.METASTASES,
                               onko.NOT_FIRST,
                               onko.STAGE_T TNT,
                               onko.STAGE_N TNN,
                               onko.STAGE_M TNM,
                               onko.CATEGORY
                        @}

                from
                      -- Для каждого подзапроса возвращается одна строка.
                      -- Изменил cross join на left join (1 = 1), чтобы возвращались данные с остальных запросов,
                      -- когда некоторые не возвращают ничего
                      @if(:pnDIRSERV !=0 and :IS_ONKO == 0){
                           fio
                           left join mkb on 1 = 1
                           left join stage on 1 = 1
                           left join tnt on 1 = 1
                           left join tnn on 1 = 1
                           left join tnm on 1 = 1
                           left join meta on 1 = 1
                           left join cat on 1 = 1
                      @}
                      @if(:pnDIRSERV !=0 and :IS_ONKO == 1){
                           fio
                           left join mkb on 1 = 1
                      @}
                      @if(:pnTALON !=0 and :IS_ONKO == 0){
                           fio
                           left join mkb on 1 = 1
                           left join onko on 1 = 1
                      @}
                      @if(:pnTALON !=0 and :IS_ONKO == 1){
                           fio
                           left join mkb on 1 = 1
                      @}

        ]]>
        <component cmptype="Variable" name="IS_ONKO" src="IS_ONKO" srctype="var" get="pnIS_ONKO"/>
        <component cmptype="Variable" name="pnLPU" src="LPU" srctype="session" get="pnLPU"/>
        <component cmptype="Variable" name="pnTALON" src="TALON" srctype="var" get="pnTALON"/>
        <component cmptype="Variable" name="pnDIRSERV" src="DIRSERV" srctype="var" get="pnDIRSERV"/>
    </component>

    <component cmptype="DataSet" name="DS_DIRECTIONS" activateoncreate="false" compile="true">
        <![CDATA[
            @if(:IS_ONKO == 1){
                @if(:pnTALON != 0){
                    select case
                                when rd.CODE in (1, 2) then 'к онкологу'
                                when rd.CODE = 7 then 'на биопсию'
                                when rd.CODE = 3 then 'на дообследование'
                                when rd.CODE = 8 then 'для определения тактики обследования и/или тактики лечения'
                           end DIR_NAME,
                           tmo.DIRECTION_DATE DIR_DATE
                      from D_V_AMB_TALONS_BASE at
                           join D_V_AMB_TALON_MKBS_BASE atm on atm.PID = at.ID
                           join D_V_AT_MKB_ONKO amo on amo.PID = atm.ID
                           join D_V_AMB_TALON_TMO tmo on tmo.PID = at.ID
                           join D_V_RECOM_DIR rd on rd.ID = tmo.RECOMMENDATION_ID
                     where at.ID = :pnTALON
                       and amo.IS_ONKO = 1
                       and rd.CODE in (1, 2, 3, 7, 8)
                       and rd.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0, :pnLPU, 'RECOM_DIR')
                     order by tmo.DIRECTION_DATE
                @}
                @if(:pnDIRSERV != 0) {
                    with container as (
                            select *
                              from (
                                   select max(vfc.STR_VALUE) over (partition by vfc.CONTAINER_COUNT) STR_VALUE,
                                          vcf.F_CODE,
                                          ds.ID,
                                          max(vfc.DAT_VALUE) over (partition by vfc.CONTAINER_COUNT) DAT_VALUE,
                                          max(vfc.NUM_VALUE) over (partition by vfc.CONTAINER_COUNT) NUM_VALUE
                                     from D_V_VISIT_FIELD_CONTS vfc
                                          join D_V_VISIT_CON_FIELDS_BASE vcf on vcf.ID = vfc.TEMP_CON_FIELD_ID
                                          join D_V_VISITS_BASE v on v.ID = vfc.PID
                                          join D_V_DIRECTION_SERVICES_BASE ds on ds.ID = v.PID
                                          join D_V_DIRECTIONS_BASE d on d.ID = ds.PID
                                    where ds.ID = :pnDIRSERV
                                      and vcf.F_CODE in ('NAPR_DATE', 'NAPR_USL', 'NAPR_IS_ONKO')
                              ) t
                             where t.NUM_VALUE != 0
                    )
                    select *
                      from (
                           select cuULS.DAT_VALUE DIR_DATE,
                                  case
                                       when odk.CODE = 1 then 'к онкологу'
                                       when odk.CODE = 2 then 'на биопсию'
                                       when odk.CODE = 3 then 'на дообследование'
                                       when odk.CODE = 4 then 'для определения тактики обследования и/или тактики лечения'
                                  end DIR_NAME
                             from container cuULS
                                  join D_V_SERVICES_BASE s on s.SE_CODE = cuULS.STR_VALUE
                                  join D_V_R_ONKO_METISSL_SERVICE oms on oms.SERVICE_ID = s.ID
                                  join D_V_R_ONKO_DIR_KINDS odk on odk.ID = oms.NAPR_V_ID
                            union
                           select dsc.REG_DATE DIR_DATE,
                                  case
                                        when odk.CODE = 1 then 'к онкологу'
                                        when odk.CODE = 2 then 'на биопсию'
                                        when odk.CODE = 3 then 'на дообследование'
                                        when odk.CODE = 4 then 'для определения тактики обследования и/или тактики лечения'
                                   end DIR_NAME
                             from D_V_DIRECTION_SERVICE_CONTROL dsc
                                  join D_V_DIRECTIONS_BASE d on d.ID = dsc.DIRECTION
                                  join D_V_R_ONKO_METISSL_SERVICE oms on oms.SERVICE_ID = dsc.SERVICE_ID
                                  join D_V_R_ONKO_DIR_KINDS odk on odk.ID = oms.NAPR_V_ID
                            where dsc.DISEASECASE = D_PKG_DIRECTION_SERVICES.GET_PARAMETER(:pnLPU, :pnDIRSERV, 1)
                              and d.IS_ONKO = 1
                              and dsc.REG_TYPE != 3
                              and ((dsc.DIRECTION_SERVICE_HID is null
                                  and dsc.DIRECTION_SERVICE != :pnDIRSERV
                                  and dsc.DIRECTION_SERVICE_IRID is null)
                                   or dsc.DIRECTION_SERVICE_IRID is not null)
                              and dsc.SERV_STATUS != 3
                      ) t
                     order by t.DIR_DATE
                @}
            @} else {
                select null DIR_DATE,
                       null DIR_NAME
                  from dual
                 where rownum = 0
            @}
        ]]>
        <component cmptype="Variable" name="IS_ONKO"   src="IS_ONKO" srctype="var"     get="pnIS_ONKO" />
        <component cmptype="Variable" name="pnTALON"   src="TALON"   srctype="var"     get="pnTALON"   />
        <component cmptype="Variable" name="pnDIRSERV" src="DIRSERV" srctype="var"     get="pnDIRSERV" />
        <component cmptype="Variable" name="pnLPU"     src="LPU"     srctype="session" get="pnLPU"     />
    </component>

    <component cmptype="DataSet" name="DS_GIST" compile="true">
            <![CDATA[
            @if (:pnTALON != 0) {
                select dg.RESEARCH_DATE,
                       to_char(extract (day from dg.RESEARCH_DATE), '09') DAY,
                       to_char(extract (month from dg.RESEARCH_DATE), '09') MONTH,
                       extract(YEAR FROM dg.RESEARCH_DATE) YEAR,
                       gt.name GIST_TYPE,
                       gt.code GIST_TYPE_CODE,
                       gr.name GIST_RESULT,
                       gr.name GIST_RESULT,
                       gr.code GIST_RESULT_CODE
                  from D_V_AT_DIAGN_G dg
                       left join D_V_R_ONKO_GIST_TYPE gt on gt.id = dg.DIAGN_TYPE_ID
                       left join D_V_R_ONKO_GIST_RSLT gr on gr.id = dg.DIAGN_RESULT_ID
                 where dg.PID = :pnTALON
                   and (gt.ID is null or gt.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0, :pnLPU, 'R_ONKO_GIST_TYPE'))
                   and (gr.ID is null or gr.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0, :pnLPU, 'R_ONKO_GIST_RSLT'))
                 order by GIST_TYPE_CODE, RESEARCH_DATE
            @}
            @if (:pnDIRSERV != 0) {
                   with gt as (
                        select dt.dat_value RESEARCH_DATE,
                               dt.CONTAINER_COUNT,
                               to_char(extract (day from dt.dat_VALUE), '09') DAY,
                               to_char(extract (month from dt.dat_VALUE), '09') MONTH,
                               extract(year from dt.dat_VALUE) YEAR,
                               gt.name GIST_TYPE,
                               gt.code GIST_TYPE_CODE
                          FROM D_V_VISIT_FIELD_CONTS vfc
                               join D_V_VISITS vs on vs.ID = vfc.PID
                               join D_V_R_ONKO_GIST_TYPE gt on gt.CODE = vfc.NUM_VALUE and vfc.TEMP_CON_FIELD = 'G_DIAGN_TYPE'
                               left join (select vfc.CONTAINER_COUNT,
                                                 vfc.PID,
                                                 vfc.LPU,
                                                 vs.VISIT_DATE,
                                                 vfc.STR_VALUE,
                                                 vfc.DAT_VALUE
                                            from D_V_VISIT_FIELD_CONTS vfc
                                                 join D_V_VISITS vs on vs.ID = vfc.PID
                                           where vfc.TEMP_CON_FIELD = 'G_RESEARCH_DATE'
                               ) dt on dt.PID = vfc.PID
                                   and dt.LPU = vfc.LPU
                                   and dt.VISIT_DATE = vs.VISIT_DATE
                                   and dt.CONTAINER_COUNT = vfc.CONTAINER_COUNT
                        where vfc.PID = (select ID from D_V_VISITS where PID = :pnDIRSERV)
                          and vfc.LPU = :pnLPU
                          and gt.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0, :pnLPU, 'R_ONKO_GIST_TYPE')
                        order by GIST_TYPE_CODE, RESEARCH_DATE),
                    gr as (select vfc.CONTAINER_COUNT,
                                  vfc.PID,
                                  gr.VERSION,
                                  vfc.LPU,
                                  vs.VISIT_DATE,
                                  vfc.NUM_VALUE,
                                  gr.NAME,
                                  gr.CODE
                             from D_V_VISIT_FIELD_CONTS vfc
                                  join D_V_VISITS vs on vs.ID = vfc.PID
                                  join D_V_R_ONKO_GIST_RSLT gr on gr.CODE = vfc.num_value and vfc.TEMP_CON_FIELD = 'G_DIAGN_RESULT'
                            where vfc.PID = (SELECT id FROM D_V_VISITS WHERE PID = :pnDIRSERV)
                              and vfc.LPU = :pnLPU
                              and gr.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0, :pnLPU, 'R_ONKO_GIST_RSLT'))
                    select gt.RESEARCH_DATE,
                           to_char(extract (day from gt.RESEARCH_DATE), '09') DAY,
                           to_char(extract (month from gt.RESEARCH_DATE), '09') MONTH,
                           extract(year from gt.RESEARCH_DATE) YEAR,
                           gt.GIST_TYPE,
                           gt.GIST_TYPE_CODE,
                           case when gr.NAME = 'Не определена' or gr.NAME is null
                                     then null
                                else '<input type="checkbox" disabled="disabled" checked="checked"/>' || gr.NAME
                           end GIST_RESULT,
                           gr.code GIST_RESULT_CODE
                      from gt
                           left join gr on gt.CONTAINER_COUNT = gr.CONTAINER_COUNT
            @}
        ]]>
        <component cmptype="Variable" name="pnTALON"   src="TALON"   srctype="var"     get="pnTALON"   />
        <component cmptype="Variable" name="pnDIRSERV" src="DIRSERV" srctype="var"     get="pnDIRSERV" />
        <component cmptype="Variable" name="pnLPU"     src="LPU"     srctype="session" get="pnLPU"     />
    </component>

    <component cmptype="DataSet" name="DS_MARK" compile="true">
        <![CDATA[
            -- Иммуногогистохия/маркеры:
            @if(:pnTALON != 0) {
                with mark_data as (select dm.RESEARCH_DATE RESEARCH_DATE,
                                          mt.code MRKR_TYPE_CODE,
                                          mv.code,
                                          mt.name MRKR_NAME
                                     from D_V_AT_DIAGN_M dm
                                          left join D_V_R_ONKO_MRKR_TYPE mt on mt.id=dm.DIAGN_TYPE_ID
                                          left join D_V_R_ONKO_MRKR_VALUE mv on mv.id=dm.DIAGN_VALUE_ID
                                    where dm.PID = :pnTALON
                                      and (mt.ID is null or mt.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0,:pnLPU,'R_ONKO_MRKR_TYPE'))
                                      and (mv.ID is null or mv.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0,:pnLPU,'R_ONKO_MRKR_VALUE'))
                                  )
            @}
            @if(:pnDIRSERV != 0) {
                                with marker as (SELECT
                                    dt.dat_value RESEARCH_DATE,
                                    mt.code MRKR_TYPE_CODE,
                                    mt.name MRKR_NAME,
                                    dt.CONTAINER_COUNT

                                FROM  D_V_VISIT_FIELD_CONTS vfc
                                          join D_V_VISITS vs on vs.id= vfc.pid
                                          join D_V_R_ONKO_MRKR_TYPE mt on mt.code=vfc.num_value and vfc.TEMP_CON_FIELD='M_DIAGN_TYPE'
                                          left join (select
                                                         vfc.CONTAINER_COUNT,
                                                         vfc.pid,vfc.lpu,vs.visit_date,
                                                         vfc.str_value,
                                                         vfc.dat_value
                                                     from D_V_VISIT_FIELD_CONTS vfc
                                                              join D_V_VISITS vs on vs.id= vfc.pid
                                                     WHERE vfc.TEMP_CON_FIELD= 'M_RESEARCH_DATE'
                                )dt  on  dt.pid=vfc.pid
                                    and dt.lpu=vfc.lpu and dt.visit_date=vs.visit_date
                                    and dt.CONTAINER_COUNT=vfc.CONTAINER_COUNT
                                where vfc.pid = (SELECT id FROM D_V_VISITS WHERE PID=:pnDIRSERV)
                                  and vfc.lpu = :pnLPU
                                  and mt.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0,:pnLPU,'R_ONKO_MRKR_TYPE')),
                     mark_result as (select vfc.CONTAINER_COUNT,
                                            vfc.pid,mv.VERSION,vfc.lpu,vs.visit_date,
                                            vfc.num_value,
                                            mv.name,
                                            mv.short_name,
                                            mv.code
                                     from D_V_VISIT_FIELD_CONTS vfc
                                              join D_V_VISITS vs on vs.id= vfc.pid
                                              join D_V_R_ONKO_MRKR_VALUE mv on mv.code=vfc.num_value and vfc.TEMP_CON_FIELD='M_DIAGN_RESULT'
                                     WHERE vs.pid = :pnDIRSERV
                                       and vfc.lpu = :pnLPU)

            @}

                    select
                        DISTINCT RESEARCH_DATE,
                             to_char(extract (day from RESEARCH_DATE),'09') DAY,
                             to_char(extract (month from RESEARCH_DATE),'09') MONTH,
                             extract(YEAR FROM RESEARCH_DATE) YEAR,
                             case
                                 when MRKR_TYPE_CODE = 10
                                     then 'Индекс пролиферативной активности экспрессии Ki-67'  -- так как в базе "Определение индекса проли...", а на форме выводить нужно просто 'Индекс проли...', остальные выводятся как в базе
                                 else MRKR_NAME
                                 end MRKR_NAME, -- Название исследовния
                             case
                                 when code IN (4,6,8,10,12,16,18,22)
                                     then '<input type="checkbox" checked="checked" disabled="disabled"> да <input type="checkbox" disabled="disabled"> нет'
                                 when code IN (5,7,9,11,13,17,19,23)
                                     then '<input type="checkbox" disabled="disabled"> да <input type="checkbox" checked="checked" disabled="disabled"> нет'
                                 when code = 14  -- Уровень экспрессии белка PD-L1
                                     then '<input type="checkbox" checked="checked" disabled="disabled"> повышенная экспрессия <input type="checkbox" disabled="disabled"> отсутствие повышенной экспресии'
                                 when code = 15
                                     then '<input type="checkbox" disabled="disabled"> повышенная экспрессия <input type="checkbox" checked="checked" disabled="disabled"> отсутствие повышенной экспресии'
                                 when code = 20  -- Индекс пролиферативной активности экспрессии Ki-67
                                     then '<input type="checkbox" checked="checked" disabled="disabled"> высокий <input type="checkbox" disabled="disabled"> низкий'
                                 when code = 21
                                     then  '<input type="checkbox" disabled="disabled"> высокий <input type="checkbox" checked="checked" disabled="disabled"> низкий'
                                 when code = 1  -- Уровень экспрессии белка HER2
                                     then  '<input type="checkbox" checked="checked" disabled="disabled"> гиперэкспрессия <input type="checkbox" disabled="disabled"> отсутствие гиперэкспрессии'
                                 when code = 2
                                     then '<input type="checkbox" disabled="disabled"> гиперэкспрессия <input type="checkbox" checked="checked" disabled="disabled"> отсутствие гиперэскпрессии'
                                 when code is null
                                     then null
                                 end MRKR_RESULT -- результат исследования
                    @if(:pnTALON !=0) {
                            from mark_data
                    @}
                    @if(:pnDIRSERV !=0){
                            from marker left join mark_result
                                      on  marker.CONTAINER_COUNT=mark_result.CONTAINER_COUNT
                    @}
        ]]>
        <component cmptype="Variable" name="pnTALON"   src="TALON"   srctype="var"     get="pnTALON"   />
        <component cmptype="Variable" name="pnDIRSERV" src="DIRSERV" srctype="var"     get="pnDIRSERV" />
        <component cmptype="Variable" name="pnLPU"     src="LPU"     srctype="session" get="pnLPU"     />
    </component>

    <component cmptype="DataSet" name="DS_CONCILIUM" compile="true">
        <![CDATA[
            -- Результат и дата проведения консилиума
            @if(:pnTALON !=0) {
                     WITH conc as (SELECT conc.CONCILIUM_RESULT,
                                           conc.CONCILIUM_DATE
                                   FROM D_V_AT_CONCILIUM conc
                                   WHERE conc.PID=:pnTALON)
            @}
            @if(:pnDIRSERV !=0) {
                     WITH conc as (SELECT
                        conc_result.CONCILIUM_RESULT,
                        conc_date.CONCILIUM_DATE
                    FROM
                        (select vs.PID,
                                vs.VISIT_DATE,
                                vf.num_value CONCILIUM_RESULT
                         from D_V_VISIT_FIELDS vf
                                  join D_V_VISITS vs on vs.id= vf.pid
                         WHERE  vf.TEMPLATE_FIELD ='CR_KONSIL_PURP') conc_result
                            LEFT JOIN (select vs.pid,
                                         vs.VISIT_DATE,
                                         vf.dat_value CONCILIUM_DATE
                                  from D_V_VISIT_FIELDS vf
                                           join D_V_VISITS vs on vs.id=vf.pid
                                  WHERE
                                          vf.TEMPLATE_FIELD='DT_CONS') conc_date
                                 ON conc_result.pid = conc_date.pid
                                     and conc_result.VISIT_DATE = conc_date.VISIT_DATE
                    WHERE conc_result.PID=:pnDIRSERV)
            @}
            SELECT
                to_char(extract (day from conc.CONCILIUM_DATE),'09') DAY,
                to_char(extract (month from conc.CONCILIUM_DATE),'09') MONTH,
                extract(YEAR FROM conc.CONCILIUM_DATE) YEAR,
                case
                     when conc.CONCILIUM_RESULT = 0 then 'отсутствует необходимость проведения консилиума'
                     when conc.CONCILIUM_RESULT = 1 then 'определение тактики обследования'
                     when conc.CONCILIUM_RESULT = 2 then 'определение тактики лечения'
                     when conc.CONCILIUM_RESULT = 3 then 'изменение тактики лечения'
                     when conc.CONCILIUM_RESULT = 4 then 'консилиум не проведен при наличии необходимости его проведения'
                end CONCILIUM_RESULT
            FROM conc
        ]]>
        <component cmptype="Variable" name="pnTALON"   src="TALON"   srctype="var" get="pnTALON"   />
        <component cmptype="Variable" name="pnDIRSERV" src="DIRSERV" srctype="var" get="pnDIRSERV" />
    </component>

    <component cmptype="DataSet" name="DS_SURGEON" compile="true">
        <![CDATA[
            -- Хирургическое лечение
            @if(:pnTALON != 0){
                    SELECT oper.name SURGEON_NAME
                        from D_V_AMB_TALON_VISITS_BASE atv
                            join D_V_AT_VISIT_ONKO vo on atv.id = vo.pid
                            join D_V_R_ONKO_THERAPY_TYPE tt
                                  on vo.SERVICE_TYPE_ID = tt.id
                                      and tt.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0,:pnLPU,'R_ONKO_THERAPY_TYPE')
                        join D_V_R_ONKO_OPER_TYPE oper
                                  on vo.OPER_THERAPY_ID = oper.id
                                      and oper.version = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0,:pnLPU,'R_ONKO_OPER_TYPE')
                        WHERE atv.pid = :pnTALON
            @}
            @if(:pnDIRSERV != 0){
                    SELECT oper.name SURGEON_NAME
                    from D_V_VISITS vs
                         join D_V_VISIT_FIELDS vf on vs.id=vf.pid
                         join D_V_R_ONKO_OPER_TYPE oper
                              on oper.code = vf.num_value
                                  and vf.TEMPLATE_FIELD='C_SURGEON_THERAPY'
                                  and oper.version = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0,:pnLPU,'R_ONKO_OPER_TYPE')
                    where vs.pid = :pnDIRSERV
            @}
        ]]>
        <component cmptype="Variable" name="pnTALON"   src="TALON"   srctype="var"     get="pnTALON"   />
        <component cmptype="Variable" name="pnDIRSERV" src="DIRSERV" srctype="var"     get="pnDIRSERV" />
        <component cmptype="Variable" name="pnLPU"     src="LPU"     srctype="session" get="pnLPU"     />
    </component>

    <component cmptype="DataSet" name="DS_DRUG" compile="true">
        <![CDATA[
            -- Лекарственная противоопухолевая терапия
            @if(:pnTALON != 0) {
                select dl.DRUG_LINE,
                       dc.DRUG_CYCLE
                  from (select atv.VISIT VISIT
                          from D_V_AMB_TALON_VISITS_BASE atv
                               left join D_V_AT_VISIT_ONKO vo on atv.ID = vo.PID
                               left join D_V_R_ONKO_THERAPY_TYPE tt
                               on vo.SERVICE_TYPE_ID = tt.ID
                               and tt.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0, :pnLPU, 'R_ONKO_THERAPY_TYPE')
                         where atv.PID = :pnTALON
                           and tt.CODE = 2) drug  -- 2 - код лекарственной противолучевой терапии
                       join (select atv.VISIT VISIT,
                                    dtl.NAME DRUG_LINE
                               from D_V_AMB_TALON_VISITS_BASE atv
                                    left join D_V_AT_VISIT_ONKO vo on atv.ID = vo.PID
                                    left join D_V_R_ONKO_DRUG_THER_LINE dtl on vo.DRUG_THERAPY_LINE = dtl.ID
                                          and dtl.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0, :pnLPU, 'R_ONKO_DRUG_THER_LINE')
                              where atv.PID = :pnTALON) dl on drug.VISIT = dl.VISIT
                       join (select atv.VISIT VISIT,
                                    dtc.NAME DRUG_CYCLE
                               from D_V_AMB_TALON_VISITS_BASE atv
                                    left join D_V_AT_VISIT_ONKO vo on atv.ID = vo.PID
                                    left join D_V_R_ONKO_DRUG_THER_CYCLE dtc on vo.DRUG_THERAPY_CYCLE_ID = dtc.ID
                                     and dtc.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0, :pnLPU, 'R_ONKO_DRUG_THER_CYCLE')
                 where atv.PID = :pnTALON) dc on dl.VISIT = dc.VISIT
            @}
            @if(:pnDIRSERV != 0) {
                    SELECT dl.DRUG_LINE, dc.DRUG_CYCLE
                            FROM (SELECT vs.id VISIT
                                   from D_V_VISITS vs
                                        join D_V_VISIT_FIELDS vf on vs.id=vf.pid
                                        join D_V_R_ONKO_THERAPY_TYPE tt
                                        on tt.code = vf.num_value
                                        and vf.TEMPLATE_FIELD='C_THERAPY_TYPE'
                                        and tt.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0,:pnLPU,'R_ONKO_THERAPY_TYPE')
                                  where vs.pid=:pnDIRSERV
                                        and tt.code=2) drug  --2 - код лекарственной противолучевой терапии
                            JOIN (SELECT vs.id VISIT,
                                     dtl.name DRUG_LINE
                                        from D_V_VISITS vs
                                             join D_V_VISIT_FIELDS vf on vs.id=vf.pid
                                             join D_V_R_ONKO_DRUG_THER_LINE dtl
                                                on  dtl.code = vf.num_value
                                                    and vf.TEMPLATE_FIELD='C_THERAPY_LINE'
                                                    and dtl.version = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0,:pnLPU,'R_ONKO_DRUG_THER_LINE')
                                             left join D_V_R_ONKO_DRUG_THER_CYCLE dtc
                                                    on dtc.code = vf.num_value
                                                    and vf.TEMPLATE_FIELD='C_THERAPY_CYCLE'
                                                    and dtc.version =  D_PKG_VERSIONS.GET_VERSION_BY_LPU(0,:pnLPU,'R_ONKO_DRUG_THER_CYCLE')
                                    WHERE vs.pid = :pnDIRSERV) dl on drug.VISIT=dl.VISIT
                           JOIN (SELECT
                               vs.id VISIT,
                               dtc.name DRUG_CYCLE
                        from D_V_VISITS vs
                                 join D_V_VISIT_FIELDS vf on vs.id=vf.pid
                                 join D_V_R_ONKO_DRUG_THER_CYCLE dtc
                                           on dtc.code = vf.num_value
                                               and vf.TEMPLATE_FIELD='C_THERAPY_CYCLE'
                                               and dtc.version =  D_PKG_VERSIONS.GET_VERSION_BY_LPU(0,:pnLPU,'R_ONKO_DRUG_THER_CYCLE')
                        WHERE vs.pid = :pnDIRSERV) dc ON dl.VISIT = dc.VISIT
            @}
        ]]>
        <component cmptype="Variable" name="pnTALON"   src="TALON"   srctype="var"     get="pnTALON"   />
        <component cmptype="Variable" name="pnDIRSERV" src="DIRSERV" srctype="var"     get="pnDIRSERV" />
        <component cmptype="Variable" name="pnLPU"     src="LPU"     srctype="session" get="pnLPU"     />
    </component>

    <component cmptype="DataSet" name="DS_MED_SCHEMES" compile="true">
        <![CDATA[
            with ms as (
                select vs.ID VISIT,
                       mts.CODE THERAPY_SCHEME,
                       '<div><span class="new_cancer__lpu__underline mnn">' || LISTAGG(ts.code ||
                       '</span><span class="new_cancer__lpu__underline mnn">' ||
                       to_char(dt.DAT_VALUE,'dd.mm.yyyy'),
                       '</span></div><div><span class="new_cancer__lpu__underline mnn">') within group(Order by  ts.code) || '</span></div>' as MNN
                  from D_V_VISIT_FIELD_CONTS vfc
                       join D_V_VISITS vs on vs.ID = vfc.PID
                       join D_V_MED_THERAPY_SCHEMES mts on vfc.STR_VALUE = mts.ID
                                                       and vfc.TEMP_CON_FIELD = 'CODE_SH'
                       join (select vfc.CONTAINER_COUNT,
                                    vfc.PID,
                                    ol.VERSION,
                                    vfc.LPU,
                                    vs.VISIT_DATE,
                                    vfc.NUM_VALUE,
                                    ol.CODE,
                                    ol.MNN
                               from D_V_VISIT_FIELD_CONTS vfc
                                    join D_V_VISITS vs on vs.ID = vfc.PID
                                    join D_V_R_ONKO_LEKP ol on ol.ID = vfc.STR_VALUE and vfc.TEMP_CON_FIELD = 'C_LEKP'
                              where vs.pid = :pnDIRSERV
                       ) ts on ts.PID = vfc.PID
                           and ts.lpu=vfc.lpu and ts.VISIT_DATE = vs.VISIT_DATE
                           and ts.CONTAINER_COUNT = vfc.CONTAINER_COUNT
                       join (select vfc.CONTAINER_COUNT,
                                    vfc.PID,
                                    vfc.LPU,
                                    vs.VISIT_DATE,
                                    vfc.STR_VALUE,
                                    vfc.DAT_VALUE
                               from D_V_VISIT_FIELD_CONTS vfc
                                    join D_V_VISITS vs on vs.ID = vfc.PID
                              where vfc.TEMP_CON_FIELD = 'DATE_INJ'
                       ) dt on dt.PID = vfc.PID
                           and dt.LPU = vfc.LPU
                           and dt.VISIT_DATE = vs.VISIT_DATE
                           and dt.CONTAINER_COUNT = vfc.CONTAINER_COUNT
                 where vfc.PID = (select ID from D_V_VISITS_BASE where PID = :pnDIRSERV)
                   and vfc.LPU = :pnLPU
                   and mts.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0, :pnLPU, 'MED_THERAPY_SCHEMES')
                   and ts.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0, :pnLPU, 'R_ONKO_LEKP')
                 group by vs.ID, mts.CODE
                 order by mts.CODE DESC
            ),
            pptr as (
                select vs.id VISIT,
                       case
                            when vf.TEMPLATE_FIELD='C_PPTR' and vf.num_value !=0
                                 then '<input type="checkbox" checked="checked" disabled="disabled" /> Применение противорвотных средств'
                            else null
                       end PPTR
                  from D_V_VISITS vs
                       join D_V_VISIT_FIELDS vf on vs.ID = vf.PID
                 where vs.PID = :pnDIRSERV
                   and vf.TEMPLATE_FIELD = 'C_PPTR'
            )
            select rownum LINE_NUMBER,
                   THERAPY_SCHEME,
                   MNN,
                   PPTR
              from ms
                   left join pptr on ms.VISIT = pptr.VISIT
             where ms.MNN is not null
                or pptr.PPTR is not null
             order by THERAPY_SCHEME desc
        ]]>
        <component cmptype="Variable" name="pnTALON"   src="TALON"   srctype="var"     get="pnTALON"   />
        <component cmptype="Variable" name="pnDIRSERV" src="DIRSERV" srctype="var"     get="pnDIRSERV" />
        <component cmptype="Variable" name="pnLPU"     src="LPU"     srctype="session" get="pnLPU"     />
    </component>

    <component cmptype="DataSet" name="DS_PPTR" activateoncreate="false" compile="true">
        <![CDATA[
            SELECT
                case
                  when vf.TEMPLATE_FIELD='C_PPTR' and vf.num_value !=0
                    then '<input type="checkbox" checked="checked" disabled="disabled" /> Применение противорвотных средств'
                                 else null end PPTR
                         FROM D_V_VISITS vs
                                  JOIN D_V_VISIT_FIELDS vf on vs.id=vf.pid
                         WHERE vs.pid = :pnDIRSERV
                             and vf.TEMPLATE_FIELD = 'C_PPTR') pptr on ms.VISIT = pptr.VISIT
                        ORDER BY ms.LINE_NUMBER
        ]]>
        <component cmptype="Variable" name="pnTALON"   src="TALON"   srctype="var"     get="pnTALON"   />
        <component cmptype="Variable" name="pnDIRSERV" src="DIRSERV" srctype="var"     get="pnDIRSERV" />
        <component cmptype="Variable" name="pnLPU"     src="LPU"     srctype="session" get="pnLPU"     />
    </component>

    <component cmptype="DataSet" name="DS_RADIO" compile="true">
        <![CDATA[
            -- Лучевая терапия
            @if(:pnTALON != 0 ){
                SELECT radio.name THERAPY_NAME,
                       case when vo.DOSE is not NULL
                            then '<span>СОД:</span><span style="display: inline-block; width: 30px; border-bottom: 1px solid black; text-align: center;">'|| vo.DOSE ||'</span>'
                            else NULL
                       end SOD
                from D_V_AMB_TALON_VISITS_BASE atv
                         join D_V_AT_VISIT_ONKO vo on vo.pid = atv.id
                         join D_V_R_ONKO_THERAPY_TYPE tt
                              on vo.SERVICE_TYPE_ID = tt.id
                                  and tt.code = 3
                                  and tt.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0,:pnLPU,'R_ONKO_THERAPY_TYPE')
                         join D_V_R_ONKO_RADIO_TYPE radio
                              on vo.RADIO_THERAPY_ID = radio.id
                                  and radio.version = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0,:pnLPU,'R_ONKO_RADIO_TYPE')
                WHERE atv.pid = :pnTALON
            @}
            @if(:pnDIRSERV != 0 ){
            SELECT rt.THERAPY_NAME,
                   case when sod.SOD is not NULL
                            then '<span>СОД:</span><span style="display: inline-block; width: 30px; border-bottom: 1px solid black; text-align: center;">'|| sod.SOD ||'</span>'
                        else NULL
                   end SOD
            FROM (SELECT tt.code THERAPY_CODE,
                         vs.id VISIT,
                         1 TEST
                  FROM
                      D_V_VISITS vs
                          join D_V_VISIT_FIELDS vf on vs.id=vf.pid
                          join D_V_R_ONKO_THERAPY_TYPE tt
                               on tt.code = vf.num_value
                                   and vf.TEMPLATE_FIELD='C_THERAPY_TYPE'
                                   and tt.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0,:pnLPU,'R_ONKO_THERAPY_TYPE')
                  WHERE tt.code = 3
                    and vs.pid = :pnDIRSERV) tt
                     JOIN (SELECT rt.name THERAPY_NAME, vs.id VISIT
                           from D_V_VISITS vs
                                    join D_V_VISIT_FIELDS vf on vs.id=vf.pid
                                    join D_V_R_ONKO_RADIO_TYPE rt
                                         on rt.code = vf.num_value
                                             and vf.TEMPLATE_FIELD='C_RADIO_THERAPY'
                                             and rt.version = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0,:pnLPU,'R_ONKO_RADIO_TYPE')
                           where vs.pid = :pnDIRSERV) rt on tt.VISIT=rt.VISIT

                     LEFT JOIN (SELECT vs.id VISIT,
                                       vf.num_value SOD
                                FROM D_V_VISITS vs
                                         join D_V_VISIT_FIELDS vf on vs.id=vf.pid
                                    and vf.TEMPLATE_FIELD='C_SOD'
                                WHERE vs.pid = :pnDIRSERV) sod on tt.VISIT = rt.VISIT
            @}
        ]]>
        <component cmptype="Variable" name="pnTALON"   src="TALON"   srctype="var"     get="pnTALON"   />
        <component cmptype="Variable" name="pnDIRSERV" src="DIRSERV" srctype="var"     get="pnDIRSERV" />
        <component cmptype="Variable" name="pnLPU"     src="LPU"     srctype="session" get="pnLPU"     />
    </component>

    <component cmptype="DataSet" name="DS_CHEMO_RADIO" compile="true">
        <![CDATA[
            -- Химеолучевая терапия
            @if(:pnTALON != 0){
                SELECT case when rt.code = 1 then 'Лучевая терапия первичной опухоли / ложа опухоли'
                            when rt.code = 2 then 'Лучевая терапия метастазов'
                            when rt.code = 3 then 'Симптоматическая лучевая терапия'
                        end THERAPY_NAME,
                       case when vo.DOSE is not NULL
                            then '<span>СОД:</span><span style="display: inline-block; width: 30px; border-bottom: 1px solid black; text-align: center;">'|| vo.DOSE ||'</span>'
                            else NULL
                end SOD
                from D_V_AMB_TALON_VISITS_BASE atv
                         join D_V_AT_VISIT_ONKO vo on vo.pid = atv.id
                         join D_V_R_ONKO_THERAPY_TYPE tt
                              on vo.SERVICE_TYPE_ID = tt.id
                                  and tt.code = 4
                                  and tt.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0,:pnLPU,'R_ONKO_THERAPY_TYPE')
                         join D_V_R_ONKO_RADIO_TYPE rt
                              on vo.RADIO_THERAPY_ID = rt.id
                                  and rt.version = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0,:pnLPU,'R_ONKO_RADIO_TYPE')
                WHERE atv.pid = :pnTALON
            @}
            @if(:pnDIRSERV != 0){
            SELECT case when rt.code = 1 then 'Лучевая терапия первичной опухоли / ложа опухоли'
                        when rt.code = 2 then 'Лучевая терапия метастазов'
                        when rt.code = 3 then 'Симптоматическая лучевая терапия'
                   end THERAPY_NAME,
                   case when sod.SOD is not NULL
                            then '<span>СОД:</span><span style="display: inline-block; width: 30px; border-bottom: 1px solid black; text-align: center;">'|| sod.SOD ||'</span>'
                        else NULL
                   end SOD
            FROM (SELECT 4 IS_CHEMO,
                         tt.code THERAPY_CODE,
                         tt.NAME THERAPY_NAME,
                         vs.id VISIT
                  FROM
                      D_V_VISITS vs
                          join D_V_VISIT_FIELDS vf on vs.id=vf.pid
                          join D_V_R_ONKO_THERAPY_TYPE tt
                               on tt.code = vf.num_value
                                   and vf.TEMPLATE_FIELD='C_THERAPY_TYPE'
                                   and tt.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0,:pnLPU,'R_ONKO_THERAPY_TYPE')
                  WHERE tt.code = 4  -- 4 - Химеолучевая терапия
                    and vs.pid = :pnDIRSERV) tt
                     JOIN (SELECT rt.code, rt.name RADIO_NAME, vs.id VISIT
                           from D_V_VISITS vs
                                    join D_V_VISIT_FIELDS vf on vs.id=vf.pid
                                    join D_V_R_ONKO_RADIO_TYPE rt
                                         on rt.code = vf.num_value
                                             and vf.TEMPLATE_FIELD='C_RADIO_THERAPY'
                                             and rt.version = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0,:pnLPU,'R_ONKO_RADIO_TYPE')
                           where vs.pid = :pnDIRSERV) rt on tt.VISIT=rt.VISIT
                     LEFT JOIN (SELECT vs.id VISIT,
                                       vf.num_value SOD
                                FROM D_V_VISITS vs
                                         join D_V_VISIT_FIELDS vf on vs.id=vf.pid
                                    and vf.TEMPLATE_FIELD='C_SOD'
                                WHERE vs.pid = :pnDIRSERV) sod on tt.VISIT = rt.VISIT
            @}
        ]]>
        <component cmptype="Variable" name="pnTALON"   src="TALON"   srctype="var"     get="pnTALON"   />
        <component cmptype="Variable" name="pnDIRSERV" src="DIRSERV" srctype="var"     get="pnDIRSERV" />
        <component cmptype="Variable" name="pnLPU"     src="LPU"     srctype="session" get="pnLPU"     />
    </component>

    <component cmptype="DataSet" name="DS_NO_SPEC_TREAT" compile="true">
        <![CDATA[
            @if(:pnTALON != 0){
              SELECT tt.name THERAPY_TYPE
                FROM
                    D_V_AMB_TALON_VISITS_BASE atv
                        left join D_V_AT_VISIT_ONKO vo on atv.id = vo.pid
                        left join D_V_R_ONKO_THERAPY_TYPE tt
                                  on vo.SERVICE_TYPE_ID = tt.id
                                      and tt.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0, :pnLPU, 'R_ONKO_THERAPY_TYPE')
                WHERE tt.code in (5, 6)
                  and atv.pid = :pnTALON
            @}
            @if(:pnDIRSERV !=0){
              SELECT tt.name THERAPY_TYPE
                FROM
                    D_V_VISITS vs JOIN D_V_VISIT_FIELDS vf on vs.id=vf.pid
                                  join D_V_R_ONKO_THERAPY_TYPE tt
                                       on tt.code = vf.num_value
                                           and vf.TEMPLATE_FIELD='C_THERAPY_TYPE'
                                           and tt.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0, :pnLPU,'R_ONKO_THERAPY_TYPE')
                WHERE tt.code in (5,6)
                   and vs.pid = :pnDIRSERV
            @}
          ]]>
        <component cmptype="Variable" name="pnTALON"   src="TALON"   srctype="var"     get="pnTALON"   />
        <component cmptype="Variable" name="pnDIRSERV" src="DIRSERV" srctype="var"     get="pnDIRSERV" />
        <component cmptype="Variable" name="pnLPU"     src="LPU"     srctype="session" get="pnLPU"     />
    </component>

    <component cmptype="DataSet" name="DS_PROTS" compile="true">
        <![CDATA[
            --Медицинские противопоказания
            with prots as (
                select vfc.id,
                      orf.code,
                      orf.name,
                      vfc.container_count,
                      vs.VISIT_DATE,
                      vs.pid,
                      orf.VERSION
                 from D_V_VISIT_FIELD_CONTS vfc
                      join D_V_VISITS_BASE vs on vs.id = vfc.pid
                      join D_V_R_ONKO_REFUSALS orf on to_char(orf.code) = vfc.str_value
                       and vfc.TEMP_CON_FIELD = 'CR_PROT'
                 where orf.CODE in (select to_number(column_value) as IDs from xmltable(:pnPROT))
            ),
            prots_date as (
                select vfc.DAT_VALUE,
                       vfc.CONTAINER_COUNT,
                       vs.VISIT_DATE,
                       vs.PID
                  from D_V_VISIT_FIELD_CONTS vfc
                       join D_V_VISITS_BASE vs on vs.ID = vfc.PID
                 where vfc.TEMP_CON_FIELD = 'CR_D_PROT'
            )
            select p.NAME PROT_NAME,
                    to_char(extract (day from pd.DAT_VALUE), '09') DAY,
                    to_char(extract (month from pd.DAT_VALUE), '09') MONTH,
                    extract(YEAR FROM pd.DAT_VALUE) YEAR
              from prots p
                   join prots_date pd on p.CONTAINER_COUNT = pd.CONTAINER_COUNT
                                     and p.VISIT_DATE = pd.VISIT_DATE
                                     and p.PID = pd.PID
             where p.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0, :pnLPU, 'R_ONKO_REFUSALS')
               and p.PID = :pnDIRSERV
        ]]>
        <component cmptype="Variable" name="pnDIRSERV" src="DIRSERV" srctype="var"     get="pnDIRSERV" />
        <component cmptype="Variable" name="pnLPU"     src="LPU"     srctype="session" get="pnLPU"     />
        <component cmptype="Variable" name="pnPROT"    src="PROT"    srctype="var"     get="pnPROT"    />
    </component>

    <component cmptype="DataSet" name="DS_OTS" compile="true">
        <![CDATA[
            -- Отказы от лечения
            with prots as (
                select vfc.ID,
                       orf.CODE,
                       orf.NAME,
                       vfc.CONTAINER_COUNT,
                       vs.VISIT_DATE,
                       vs.PID,
                       orf.VERSION
                  from D_V_VISIT_FIELD_CONTS vfc
                       join D_V_VISITS vs on vs.ID = vfc.PID
                       join D_V_R_ONKO_REFUSALS orf on to_char(orf.CODE) = vfc.STR_VALUE
                                                   and vfc.TEMP_CON_FIELD = 'CR_PROT'
                 where orf.code in (select to_number(COLUMN_VALUE) as IDs from xmltable(:pnOT))
            ),
            prots_date as (
                select vfc.DAT_VALUE,
                       vfc.CONTAINER_COUNT,
                       vs.VISIT_DATE,
                       vs.PID
                  from D_V_VISIT_FIELD_CONTS vfc
                       join D_V_VISITS_BASE vs on vs.id = vfc.pid
                 where vfc.TEMP_CON_FIELD = 'CR_D_PROT'
            )
            select p.name OT_NAME,
                   to_char(extract (day from pd.DAT_VALUE), '09') DAY,
                   to_char(extract (month from pd.DAT_VALUE), '09') MONTH,
                   extract(YEAR FROM pd.DAT_VALUE) YEAR
              from prots p
                   join prots_date pd on p.CONTAINER_COUNT = pd.CONTAINER_COUNT
                                     and p.VISIT_DATE = pd.VISIT_DATE
                                     and p.PID = pd.PID
             where p.VERSION = D_PKG_VERSIONS.GET_VERSION_BY_LPU(0, :pnLPU, 'R_ONKO_REFUSALS')
               and p.PID = :pnDIRSERV
        ]]>
        <component cmptype="Variable" name="pnOT"      src="OT"      srctype="var"     get="pnOT"      />
        <component cmptype="Variable" name="pnDIRSERV" src="DIRSERV" srctype="var"     get="pnDIRSERV" />
        <component cmptype="Variable" name="pnLPU"     src="LPU"     srctype="session" get="pnLPU"     />
    </component>

    <component cmptype="SubForm" path="Reports/HospPlan/SubForms/patient_new_cancer_template"/>
</div>