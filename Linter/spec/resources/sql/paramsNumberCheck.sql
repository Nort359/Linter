procedure ADD_FULL
  (
    pnD_INSERT_ID  out NUMBER,
    pnLPU          in NUMBER, --ЛПУ
    pnCID          in NUMBER,
    pnAGENT        in NUMBER, --ID контрагента (если есть)
    psP_NAME       in VARCHAR2, --Имя пациента
    psP_SURNAME    in VARCHAR2, --Фамилия пациента
    psP_PATRNAME   in VARCHAR2, --Отчество пациента
    pdBIRTHDATE    in DATE, --Дата рождения пациента
    pdDEATHDATE    in DATE, --Дата и время смерти пациента
    pnDEATHDOCTYPE in NUMBER, --Тип документа о смерти
    pdDEATHDOCDATE in DATE, --Дата документа о смерти
    psDEATHDOCNUM  in VARCHAR2, --Номер документа о смерти
    psBIRTHPLACE   in VARCHAR2, --Место рождения
    pnPMC_TYPE     in NUMBER := null, --Тип карты
    pnIS_EMPLOYER  in NUMBER default 0, --Сотрудник: 1 - да, 0 - нет
    pnIA_PRINTED   in NUMBER := 0, --Информация о печати информированного согласия на обработку персональных данных
    pnSMS_AGREE    in NUMBER := 0, --Согласие на получение СМС
    pnEMAIL_AGREE  in NUMBER default 0, --Согласие на отправку результатов по эл. почте: 0- нет, 1 - да
    --Антропометрика
    --pnHEIGHT                             in NUMBER,          --Рост в см
    --pnWEIGHT                             in NUMBER,          --Вес в кг
    pnCONSTITUTION              in NUMBER, --Конституция
    pdCONSTITUTION_BEGIN        in DATE, --Дата начала действия
    psAGENT_CONSTITUTION_PARAMS in VARCHAR2, --Строка в формате d_anthrop.id:значение;d_anthrop.id:значение
    pnBLOODGROUPE               in NUMBER, --Группа крови (ссылка на справочник)
    pnRHESUS                    in NUMBER, --Резус фактор : 0 - отрицательный, 1 - положительный
    pnSEX                       in NUMBER, --Пол : 0 - женский, 1 - мужской
    psECOLOR                    in VARCHAR2, --Цвет глаз
    pnMARITAL_STATE             in NUMBER, --Семейное положение (ссылка на справочник)
    pdMARITAL_STATE_BEGIN       in DATE, --Дата начала действия сем. положения
    --Паспорт
    pnPASSPORT_TYPE    in NUMBER, --Тип документа, удостоверяющего личность (ссылка на справочник)
    psPASSPORT_SER     in VARCHAR2, --Серия документа, удостоверяющего личность
    psPASSPORT_NUMB    in VARCHAR2, --Номер документа, удостоверяющего личность
    psPASSPORT_WHO     in VARCHAR2, --Кем выдан документ, удостоверяющего личность
    pdPASSPORT_WHEN    in DATE, --Дата выдачи документа, удостоверяющего личность
    pnCITIZENSHIP      in NUMBER, --Гражданство
    psPASSPORT_WHO_DIV in VARCHAR2, --Кем выдан: код подразделения
    --Полисы
    psPOLIS_SER      in VARCHAR2, --Серия страхового полиса ОМС
    psPOLIS_NUMB     in VARCHAR2, --Номер страхового полиса ОМС
    pdPOLIS_WHEN     in DATE, --Дата выдачи страхового полиса ОМС
    pnPOLIS_KIND     in NUMBER, --Вид полиса ОМС
    pnPOLIS_WHO      in NUMBER, --Кем выдан страховой полис ОМС
    pdPOLIS_BEGIN    in DATE, --Дата начала действия полиса ОМС
    pdPOLIS_END      in DATE, --Дата конца действия полиса ОМС
    psPOLIS_DMS_SER  in VARCHAR2, --Серия страхового полиса ДМС
    psPOLIS_DMS_NUMB in VARCHAR2, --Номер страхового полиса ДМС
    pnPOLIS_DMS_WHO  in NUMBER, --Кем выдан страховой полис ДМС
    pdPOLIS_DMS_WHEN in DATE, --Дата выдачи страхового полиса ДМС
    pdPOLIS_DMS_END  in DATE, --Дата конца действия полиса ДМС
    psSNILS          in VARCHAR2, --СНИЛС
    psENP            in VARCHAR2, --ЕНП
    --инвалидность
    pnINABILITY_TYPE          in NUMBER, --Вид инвалидности  (ссылка на справочник)
    pnINABILITY_GRADE         in NUMBER, --Степень инвалидности
    pnINABILITY_GROUP         in NUMBER, --Группа инвалидности
    psINABILITY_DOC_NUMB      in VARCHAR2, --Номер удостоверения
    pdINABILITY_DATE          in DATE, --Дата установления инвалидности
    pnINABILITY_MKB           in NUMBER, --Код МКБ причины инвалидности
    pnDISABILITY_GRADE        in NUMBER, --Степень утраты трудоспособности(%)
    pnINABILITY_STATUS        in NUMBER, --Статус инвалидности
    pdINABILITY_DATE_END      in DATE, --Дата окончания срока инвалидности
    pdINABILITY_LASTINSP_DATE in DATE default null, --Дата последнего освидетельствования
    pnINABILITY_MKB_MAIN      in NUMBER default 0, --Основной диагноз: 0 - нет, 1 - да
    --Социально
    pnSOCIAL_STATE       in NUMBER, --Социальное положение (ссылка на справочник)
    pnSOCIAL_CATEGORY    in NUMBER, --социальная категория  0 работающий/ 1 безработный
    pdSOCIAL_STATE_BEGIN in DATE, --Дата начала действия
    pnEDUCATION          in NUMBER, --Образование (ссылка на справочник)
    --Работа
    pnWORK_PLACE       in NUMBER, --Место работы (учёбы) - ID контрагента
    pnWORK_POST        in NUMBER, --Должность
    psWORK_PLACE_HAND  in VARCHAR2, --место работы (учёбы) (ручной ввод)
    pnWORK_PLACE_DEP   in NUMBER, --место работы (учёбы) подразделение
    pnWORK_OKVED       in NUMBER, --Код ОКВЭД места работы
    pnWORK_RCODE       in NUMBER, --Код района работы
    pdWORK_PLACE_BEGIN in DATE, --Дата начала действия
    pnIS_WORK          in NUMBER, --Признак: 0- место работы, 1 - место учебы
    --Вредные факторы
    pnBAD_FACTOR       in NUMBER, --Код профессиональной вредности (ссылка на справочник)
    pdBAD_FACTOR_BEGIN in DATE,
    --Контакты: т.к.структура контактов изменилась,с веба не заполнять, вызывать отдельно
    psPHONE1 in VARCHAR2 default null, --Контактный телефон 1
    psPHONE2 in VARCHAR2 default null, --Контактный телефон 2
    psEMAIL  in VARCHAR2 default null, --
    --Адреса
    pnADDRREG_STREET     in NUMBER, --Улица адреса прописки (ссылка на справочник)
    psADDRREG_HOUSE      in VARCHAR2, --Дом адреса прописки
    psADDRREG_BLOCK      in VARCHAR2, --Корпус адреса прописки
    psADDRREG_FLAT       in VARCHAR2, --Квартира адреса прописки
    psADDRREG_HAND       in VARCHAR2, --Примечание адреса прописки
    pnADDRREAL_STREET    in NUMBER, --Улица адреса проживания (ссылка на справочник)
    psADDRREAL_HOUSE     in VARCHAR2, --Дом адреса проживания
    psADDRREAL_BLOCK     in VARCHAR2, --Корпус адреса проживания
    psADDRREAL_FLAT      in VARCHAR2, --Квартира адреса проживания
    psADDRREAL_HAND      in VARCHAR2, --Примечание адреса проживания
    pnADDRREAL_BEGIN     in DATE, --Дата начала действия адреса проживания
    pnADDRREAL_END       in DATE default null, --Дата конца действия адреса проживания
    psADDRREG_HOUSE_LIT  in VARCHAR2, --литера дома адреса прописки
    psADDRREAL_HOUSE_LIT in VARCHAR2, --литера дома адреса проживания
    psADDRREG_FLAT_LIT   in VARCHAR2, --литера квартиры адреса прописки
    psADDRREAL_FLAT_LIT  in VARCHAR2, --литера квартиры адреса проживания
    psADDRREG_INDEX      in VARCHAR2, --Индекс адреса прописки
    pnADDRREG_RAION      in NUMBER, --Район адреса прописки
    pnADDRREG_BEGIN      in DATE, --Дата начала действия адреса прописки
    pnADDRREG_END        in DATE default null, --Дата конца действия адреса прописки
    psADDRREAL_INDEX     in VARCHAR2, --Индекс адреса проживания
    pnADDRREAL_RAION     in NUMBER, --Район адреса проживания
    pnADDR_REAL_EQ_REG   in NUMBER, --Адрес прописки совпадает с фактическим проживанием
    pnREG_IS_CITIZEN     in NUMBER, --Признак горожанина по прописке
    pnREAL_IS_CITIZEN    in NUMBER, --Признак горожанина по адресу проживания
    pnADDRREG_IS_BIRTH   in NUMBER, --Признак рождения по адресу прописки
    pnADDRREAL_IS_BIRTH  in NUMBER, --Признак рождения по адресу проживания
    psCARD_NUMB          in VARCHAR2, --Код карты
    --Регистрация
    pnREG_LPU          in NUMBER, --ЛПУ регистрации пациента
    pnLPU_SITE         in NUMBER, --Участок ЛПУ (ссылка на D_LPU_SITES)
    pdLPU_REG_DATE     in DATE, --дата регистрации в апу
    pnDIVISION         in NUMBER, --Подразделение
    pnREG_TYPE         in NUMBER, --Тип прикрепления
    psREG_DOC_NUMB     in VARCHAR2, --Номер заявления
    pnREGISTER_PURPOSE in NUMBER, --Прикреплен для
    psREG_NOTE         in VARCHAR2, --Примечание
    pnREG_CATEGORY     in NUMBER, --Категория прикрепления
    --Падежи
    psP_NAME_TO      in VARCHAR2, --имя пациента, дательный падеж (кому?)
    psP_SURNAME_TO   in VARCHAR2, --фамилия пациента, дательный падеж (кому?)
    psP_PATRNAME_TO  in VARCHAR2, --отчество пациента, дательный падеж (кому?)
    psP_NAME_FR      in VARCHAR2, --имя пациента, родительный падеж (от кого?)
    psP_SURNAME_FR   in VARCHAR2, --фамилия пациента, родительный падеж (от кого?)
    psP_PATRNAME_FR  in VARCHAR2, --отчество пациента, родительный падеж (от кого?)
    psP_NAME_AC      in VARCHAR2, --имя пациента, винительный падеж (видеть кого?)
    psP_SURNAME_AC   in VARCHAR2, --фамилия пациента, винительный падеж (видеть кого?)
    psP_PATRNAME_AC  in VARCHAR2, --отчество пациента, винительный падеж (видеть кого?)
    psP_NAME_ABL     in VARCHAR2, --имя пациента, творительный (кем?)
    psP_SURNAME_ABL  in VARCHAR2, --фамилия пациента, творительный (кем?)
    psP_PATRNAME_ABL in VARCHAR2, --отчество пациента, творительный (кем?)
    pnDECLINE_FIO    in NUMBER default 0, --Просклонять принудительно
    psNOTE           in VARCHAR2, --Примечание
    --Родственник
    pnRELATIONSHIP in NUMBER, --Степень родства
    pnREL_AGENT    in NUMBER, --Контрагент родственник
    pnREPRESENT    in NUMBER, --Признак представителя
    pnREL_LSTATUS  in NUMBER default null, --Юридический статус представителя
    pnREPRESENT_ER in NUMBER default null, -- Представитель в регистратуре
    --Льготы
    pnCATEGORY              in NUMBER, --Ссылка на категории
    pdAC_DATE               in DATE, --Дата взятия на учет
    pdDATE_B                in DATE, --Дата начала действия льгот (для текущего регистра)
    psDOC_SER               in VARCHAR2, --Серия документа, подтверждающего льготу
    psDOC_NUMB              in VARCHAR2, --Номер документа, подтверждающего льготу
    pnDECRETIV_GROUP        in NUMBER, --Декретивная группа
    pdDECRETIV_GROUP_BEGIN  in DATE, --Дата начала действия
    pnGR_VACCINATIONES      in NUMBER, --Группа риска : прививки
    pdGR_VACCINATIONS_BEGIN in DATE, --Дата начала действия
    pnGR_RENTGENOGRAPH      in NUMBER, --Флюорография
    pdGR_RENTGENOGR_BEGIN   in DATE, --Дата начала действия
    --Региональная льгота
    pnREGPR_CONTINGENT  in NUMBER, --Льготный контингент
    pnREGPR_DISEASE_MKB in NUMBER, --Льготное заболевание
    pdREGPR_DATE_B      in DATE, --Дата постановки на льготу
    pnREGPR_DOC_KIND    in NUMBER, --Вид документа на льготу
    pnREGPR_DOC_SER     in VARCHAR2, --Серия документа на льготу
    pnREGPR_DOC_NUMB    in VARCHAR2, --Номер  документа на льготу
    pnREGPR_DOC_DATE    in DATE, --Дата документа на льготу
    pnREGPR_LPU_GIVER   in NUMBER, --ЛПУ, присвоившее льготу
    pnREGPR_TYPE        in NUMBER, --Тип льготы
    --Прочее
    pnSPECIAL_CASE    in NUMBER, --Особый случай
    psCARD_LOCATION   in VARCHAR2, --Местонахождение карты
    pdISSUE_DATE      in DATE, --Дата выдачи карты
    pnREG_DIVISION    in NUMBER, --Место регистрации карты
    pnNATION          in NUMBER default null, --Национальность
    pnIS_HOME         in NUMBER default 0, --Лежачий пациент
    pnGEST_AGE_MOTHER in NUMBER default null, --Срок гестации матери(в неделях) при родах
    --  pnBODYAREA                           in NUMBER           --Площадь поверхности тела в м2
    -- Категории учета ребенка сироты\ находящегося  в  тяжелой  жизненной ситуации
    pnAG_ORP_CATEGORY   in NUMBER default null, --Категория
    pdAG_ORP_BEGIN_DATE in DATE default null, --Дата начала действия
    -- Места нахождения ребенка сироты\ находящегося  в  тяжелой  жизненной ситуации
    pnAG_ORPP_PLACE       in NUMBER default null, --Место
    pnAG_ORPP_MOVE_REASON in NUMBER default null, --Причина выбытия
    pnAG_ORPP_HOSP_PLACE  in NUMBER default null, --Стационарное учреждение
    pdAG_ORPP_BEGIN_DATE  in DATE default null, --Дата начала действия
    psBLANK_NUM           in VARCHAR2 default null, --Номер бланка полиса ОМС
    psBLANK_NUM_DMS       in VARCHAR2 default null, --Номер бланка полиса ДМС
    --Дополнительные сведения
    psDETAIL_FAMILY_INCOME in VARCHAR2 default null, --Доход семьи
    pdDETAIL_DATE_BEGIN    in DATE default null, -- дата начала действия
    pdDETAIL_DATE_END      in DATE default null, -- дата окончания действия
    psDEATHPLACE           in VARCHAR2 default null, -- Место смерти
    psMOVE_REASON_HANDLE   in VARCHAR2 default null,-- Уточнение причины выбытия
    pnFULL_CLASSES         in NUMBER default null, --Количество полных классов/курсов
    pnACCURACY_DATE_DEATH  in NUMBER default null, --Точность даты смерти: 0 - неизвестно время; 1 - неизвестно число; 2 - неизвестно число и месяц; 3 - неизвестна дата полностью
    pnACCURACY_DATE_BIRTH  in NUMBER default null, --Точность даты рождения: 1 - неизвестно число; 2 - неизвестно число и месяц; 3 - неизвестна дата полностью
    psADDRREG_BUILDING     in VARCHAR2 default null, --строение адреса прописки
    psADDRREAL_BUILDING    in VARCHAR2 default null --строение адреса проживания
  ) is ...;