procedure ADD_FULL
  (
    pnD_INSERT_ID  out NUMBER,
    pnLPU          in NUMBER, --���
    pnCID          in NUMBER,
    pnAGENT        in NUMBER, --ID ����������� (���� ����)
    psP_NAME       in VARCHAR2, --��� ��������
    psP_SURNAME    in VARCHAR2, --������� ��������
    psP_PATRNAME   in VARCHAR2, --�������� ��������
    pdBIRTHDATE    in DATE, --���� �������� ��������
    pdDEATHDATE    in DATE, --���� � ����� ������ ��������
    pnDEATHDOCTYPE in NUMBER, --��� ��������� � ������
    pdDEATHDOCDATE in DATE, --���� ��������� � ������
    psDEATHDOCNUM  in VARCHAR2, --����� ��������� � ������
    psBIRTHPLACE   in VARCHAR2, --����� ��������
    pnPMC_TYPE     in NUMBER := null, --��� �����
    pnIS_EMPLOYER  in NUMBER default 0, --���������: 1 - ��, 0 - ���
    pnIA_PRINTED   in NUMBER := 0, --���������� � ������ ���������������� �������� �� ��������� ������������ ������
    pnSMS_AGREE    in NUMBER := 0, --�������� �� ��������� ���
    pnEMAIL_AGREE  in NUMBER default 0, --�������� �� �������� ����������� �� ��. �����: 0- ���, 1 - ��
    --��������������
    --pnHEIGHT                             in NUMBER,          --���� � ��
    --pnWEIGHT                             in NUMBER,          --��� � ��
    pnCONSTITUTION              in NUMBER, --�����������
    pdCONSTITUTION_BEGIN        in DATE, --���� ������ ��������
    psAGENT_CONSTITUTION_PARAMS in VARCHAR2, --������ � ������� d_anthrop.id:��������;d_anthrop.id:��������
    pnBLOODGROUPE               in NUMBER, --������ ����� (������ �� ����������)
    pnRHESUS                    in NUMBER, --����� ������ : 0 - �������������, 1 - �������������
    pnSEX                       in NUMBER, --��� : 0 - �������, 1 - �������
    psECOLOR                    in VARCHAR2, --���� ����
    pnMARITAL_STATE             in NUMBER, --�������� ��������� (������ �� ����������)
    pdMARITAL_STATE_BEGIN       in DATE, --���� ������ �������� ���. ���������
    --�������
    pnPASSPORT_TYPE    in NUMBER, --��� ���������, ��������������� �������� (������ �� ����������)
    psPASSPORT_SER     in VARCHAR2, --����� ���������, ��������������� ��������
    psPASSPORT_NUMB    in VARCHAR2, --����� ���������, ��������������� ��������
    psPASSPORT_WHO     in VARCHAR2, --��� ����� ��������, ��������������� ��������
    pdPASSPORT_WHEN    in DATE, --���� ������ ���������, ��������������� ��������
    pnCITIZENSHIP      in NUMBER, --�����������
    psPASSPORT_WHO_DIV in VARCHAR2, --��� �����: ��� �������������
    --������
    psPOLIS_SER      in VARCHAR2, --����� ���������� ������ ���
    psPOLIS_NUMB     in VARCHAR2, --����� ���������� ������ ���
    pdPOLIS_WHEN     in DATE, --���� ������ ���������� ������ ���
    pnPOLIS_KIND     in NUMBER, --��� ������ ���
    pnPOLIS_WHO      in NUMBER, --��� ����� ��������� ����� ���
    pdPOLIS_BEGIN    in DATE, --���� ������ �������� ������ ���
    pdPOLIS_END      in DATE, --���� ����� �������� ������ ���
    psPOLIS_DMS_SER  in VARCHAR2, --����� ���������� ������ ���
    psPOLIS_DMS_NUMB in VARCHAR2, --����� ���������� ������ ���
    pnPOLIS_DMS_WHO  in NUMBER, --��� ����� ��������� ����� ���
    pdPOLIS_DMS_WHEN in DATE, --���� ������ ���������� ������ ���
    pdPOLIS_DMS_END  in DATE, --���� ����� �������� ������ ���
    psSNILS          in VARCHAR2, --�����
    psENP            in VARCHAR2, --���
    --������������
    pnINABILITY_TYPE          in NUMBER, --��� ������������  (������ �� ����������)
    pnINABILITY_GRADE         in NUMBER, --������� ������������
    pnINABILITY_GROUP         in NUMBER, --������ ������������
    psINABILITY_DOC_NUMB      in VARCHAR2, --����� �������������
    pdINABILITY_DATE          in DATE, --���� ������������ ������������
    pnINABILITY_MKB           in NUMBER, --��� ��� ������� ������������
    pnDISABILITY_GRADE        in NUMBER, --������� ������ ����������������(%)
    pnINABILITY_STATUS        in NUMBER, --������ ������������
    pdINABILITY_DATE_END      in DATE, --���� ��������� ����� ������������
    pdINABILITY_LASTINSP_DATE in DATE default null, --���� ���������� �������������������
    pnINABILITY_MKB_MAIN      in NUMBER default 0, --�������� �������: 0 - ���, 1 - ��
    --���������
    pnSOCIAL_STATE       in NUMBER, --���������� ��������� (������ �� ����������)
    pnSOCIAL_CATEGORY    in NUMBER, --���������� ���������  0 ����������/ 1 �����������
    pdSOCIAL_STATE_BEGIN in DATE, --���� ������ ��������
    pnEDUCATION          in NUMBER, --����������� (������ �� ����������)
    --������
    pnWORK_PLACE       in NUMBER, --����� ������ (�����) - ID �����������
    pnWORK_POST        in NUMBER, --���������
    psWORK_PLACE_HAND  in VARCHAR2, --����� ������ (�����) (������ ����)
    pnWORK_PLACE_DEP   in NUMBER, --����� ������ (�����) �������������
    pnWORK_OKVED       in NUMBER, --��� ����� ����� ������
    pnWORK_RCODE       in NUMBER, --��� ������ ������
    pdWORK_PLACE_BEGIN in DATE, --���� ������ ��������
    pnIS_WORK          in NUMBER, --�������: 0- ����� ������, 1 - ����� �����
    --������� �������
    pnBAD_FACTOR       in NUMBER, --��� ���������������� ��������� (������ �� ����������)
    pdBAD_FACTOR_BEGIN in DATE,
    --��������: �.�.��������� ��������� ����������,� ���� �� ���������, �������� ��������
    psPHONE1 in VARCHAR2 default null, --���������� ������� 1
    psPHONE2 in VARCHAR2 default null, --���������� ������� 2
    psEMAIL  in VARCHAR2 default null, --
    --������
    pnADDRREG_STREET     in NUMBER, --����� ������ �������� (������ �� ����������)
    psADDRREG_HOUSE      in VARCHAR2, --��� ������ ��������
    psADDRREG_BLOCK      in VARCHAR2, --������ ������ ��������
    psADDRREG_FLAT       in VARCHAR2, --�������� ������ ��������
    psADDRREG_HAND       in VARCHAR2, --���������� ������ ��������
    pnADDRREAL_STREET    in NUMBER, --����� ������ ���������� (������ �� ����������)
    psADDRREAL_HOUSE     in VARCHAR2, --��� ������ ����������
    psADDRREAL_BLOCK     in VARCHAR2, --������ ������ ����������
    psADDRREAL_FLAT      in VARCHAR2, --�������� ������ ����������
    psADDRREAL_HAND      in VARCHAR2, --���������� ������ ����������
    pnADDRREAL_BEGIN     in DATE, --���� ������ �������� ������ ����������
    pnADDRREAL_END       in DATE default null, --���� ����� �������� ������ ����������
    psADDRREG_HOUSE_LIT  in VARCHAR2, --������ ���� ������ ��������
    psADDRREAL_HOUSE_LIT in VARCHAR2, --������ ���� ������ ����������
    psADDRREG_FLAT_LIT   in VARCHAR2, --������ �������� ������ ��������
    psADDRREAL_FLAT_LIT  in VARCHAR2, --������ �������� ������ ����������
    psADDRREG_INDEX      in VARCHAR2, --������ ������ ��������
    pnADDRREG_RAION      in NUMBER, --����� ������ ��������
    pnADDRREG_BEGIN      in DATE, --���� ������ �������� ������ ��������
    pnADDRREG_END        in DATE default null, --���� ����� �������� ������ ��������
    psADDRREAL_INDEX     in VARCHAR2, --������ ������ ����������
    pnADDRREAL_RAION     in NUMBER, --����� ������ ����������
    pnADDR_REAL_EQ_REG   in NUMBER, --����� �������� ��������� � ����������� �����������
    pnREG_IS_CITIZEN     in NUMBER, --������� ���������� �� ��������
    pnREAL_IS_CITIZEN    in NUMBER, --������� ���������� �� ������ ����������
    pnADDRREG_IS_BIRTH   in NUMBER, --������� �������� �� ������ ��������
    pnADDRREAL_IS_BIRTH  in NUMBER, --������� �������� �� ������ ����������
    psCARD_NUMB          in VARCHAR2, --��� �����
    --�����������
    pnREG_LPU          in NUMBER, --��� ����������� ��������
    pnLPU_SITE         in NUMBER, --������� ��� (������ �� D_LPU_SITES)
    pdLPU_REG_DATE     in DATE, --���� ����������� � ���
    pnDIVISION         in NUMBER, --�������������
    pnREG_TYPE         in NUMBER, --��� ������������
    psREG_DOC_NUMB     in VARCHAR2, --����� ���������
    pnREGISTER_PURPOSE in NUMBER, --���������� ���
    psREG_NOTE         in VARCHAR2, --����������
    pnREG_CATEGORY     in NUMBER, --��������� ������������
    --������
    psP_NAME_TO      in VARCHAR2, --��� ��������, ��������� ����� (����?)
    psP_SURNAME_TO   in VARCHAR2, --������� ��������, ��������� ����� (����?)
    psP_PATRNAME_TO  in VARCHAR2, --�������� ��������, ��������� ����� (����?)
    psP_NAME_FR      in VARCHAR2, --��� ��������, ����������� ����� (�� ����?)
    psP_SURNAME_FR   in VARCHAR2, --������� ��������, ����������� ����� (�� ����?)
    psP_PATRNAME_FR  in VARCHAR2, --�������� ��������, ����������� ����� (�� ����?)
    psP_NAME_AC      in VARCHAR2, --��� ��������, ����������� ����� (������ ����?)
    psP_SURNAME_AC   in VARCHAR2, --������� ��������, ����������� ����� (������ ����?)
    psP_PATRNAME_AC  in VARCHAR2, --�������� ��������, ����������� ����� (������ ����?)
    psP_NAME_ABL     in VARCHAR2, --��� ��������, ������������ (���?)
    psP_SURNAME_ABL  in VARCHAR2, --������� ��������, ������������ (���?)
    psP_PATRNAME_ABL in VARCHAR2, --�������� ��������, ������������ (���?)
    pnDECLINE_FIO    in NUMBER default 0, --����������� �������������
    psNOTE           in VARCHAR2, --����������
    --�����������
    pnRELATIONSHIP in NUMBER, --������� �������
    pnREL_AGENT    in NUMBER, --���������� �����������
    pnREPRESENT    in NUMBER, --������� �������������
    pnREL_LSTATUS  in NUMBER default null, --����������� ������ �������������
    pnREPRESENT_ER in NUMBER default null, -- ������������� � ������������
    --������
    pnCATEGORY              in NUMBER, --������ �� ���������
    pdAC_DATE               in DATE, --���� ������ �� ����
    pdDATE_B                in DATE, --���� ������ �������� ����� (��� �������� ��������)
    psDOC_SER               in VARCHAR2, --����� ���������, ��������������� ������
    psDOC_NUMB              in VARCHAR2, --����� ���������, ��������������� ������
    pnDECRETIV_GROUP        in NUMBER, --����������� ������
    pdDECRETIV_GROUP_BEGIN  in DATE, --���� ������ ��������
    pnGR_VACCINATIONES      in NUMBER, --������ ����� : ��������
    pdGR_VACCINATIONS_BEGIN in DATE, --���� ������ ��������
    pnGR_RENTGENOGRAPH      in NUMBER, --������������
    pdGR_RENTGENOGR_BEGIN   in DATE, --���� ������ ��������
    --������������ ������
    pnREGPR_CONTINGENT  in NUMBER, --�������� ����������
    pnREGPR_DISEASE_MKB in NUMBER, --�������� �����������
    pdREGPR_DATE_B      in DATE, --���� ���������� �� ������
    pnREGPR_DOC_KIND    in NUMBER, --��� ��������� �� ������
    pnREGPR_DOC_SER     in VARCHAR2, --����� ��������� �� ������
    pnREGPR_DOC_NUMB    in VARCHAR2, --�����  ��������� �� ������
    pnREGPR_DOC_DATE    in DATE, --���� ��������� �� ������
    pnREGPR_LPU_GIVER   in NUMBER, --���, ����������� ������
    pnREGPR_TYPE        in NUMBER, --��� ������
    --������
    pnSPECIAL_CASE    in NUMBER, --������ ������
    psCARD_LOCATION   in VARCHAR2, --��������������� �����
    pdISSUE_DATE      in DATE, --���� ������ �����
    pnREG_DIVISION    in NUMBER, --����� ����������� �����
    pnNATION          in NUMBER default null, --��������������
    pnIS_HOME         in NUMBER default 0, --������� �������
    pnGEST_AGE_MOTHER in NUMBER default null, --���� �������� ������(� �������) ��� �����
    --  pnBODYAREA                           in NUMBER           --������� ����������� ���� � �2
    -- ��������� ����� ������� ������\ ������������  �  �������  ��������� ��������
    pnAG_ORP_CATEGORY   in NUMBER default null, --���������
    pdAG_ORP_BEGIN_DATE in DATE default null, --���� ������ ��������
    -- ����� ���������� ������� ������\ ������������  �  �������  ��������� ��������
    pnAG_ORPP_PLACE       in NUMBER default null, --�����
    pnAG_ORPP_MOVE_REASON in NUMBER default null, --������� �������
    pnAG_ORPP_HOSP_PLACE  in NUMBER default null, --������������ ����������
    pdAG_ORPP_BEGIN_DATE  in DATE default null, --���� ������ ��������
    psBLANK_NUM           in VARCHAR2 default null, --����� ������ ������ ���
    psBLANK_NUM_DMS       in VARCHAR2 default null, --����� ������ ������ ���
    --�������������� ��������
    psDETAIL_FAMILY_INCOME in VARCHAR2 default null, --����� �����
    pdDETAIL_DATE_BEGIN    in DATE default null, -- ���� ������ ��������
    pdDETAIL_DATE_END      in DATE default null, -- ���� ��������� ��������
    psDEATHPLACE           in VARCHAR2 default null, -- ����� ������
    psMOVE_REASON_HANDLE   in VARCHAR2 default null,-- ��������� ������� �������
    pnFULL_CLASSES         in NUMBER default null, --���������� ������ �������/������
    pnACCURACY_DATE_DEATH  in NUMBER default null, --�������� ���� ������: 0 - ���������� �����; 1 - ���������� �����; 2 - ���������� ����� � �����; 3 - ���������� ���� ���������
    pnACCURACY_DATE_BIRTH  in NUMBER default null, --�������� ���� ��������: 1 - ���������� �����; 2 - ���������� ����� � �����; 3 - ���������� ���� ���������
    psADDRREG_BUILDING     in VARCHAR2 default null, --�������� ������ ��������
    psADDRREAL_BUILDING    in VARCHAR2 default null --�������� ������ ����������
  ) is ...;