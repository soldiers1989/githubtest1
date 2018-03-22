CREATE PROCEDURE ETL.PRO_TM_FINANC_MO (IN vYearMonth INTEGER,IN vReRunIndex INTEGER,OUT vRetCode INTEGER )
    LANGUAGE SQL
-------------------------------------------------------------------------------
--  SQL �洢����
-------------------------------------------------------------------------------
--  Purpose :  DM_MIS�±����ܱ�
--  Auther: ����
--  Date : 2012-7-9
--  Modified History:
--  ---------------------------------------------------------------------------
--  DATE         AUTHOR   VERSION         DESCRIPTION
--  2012-07-09   ����     V01.00.000      ����DSS-Pac-1207-023�½��洢����
--  2012-09-07   ����     V01.00.001      ����DSS-Def-1209-024����Step 0��ɾ��Ŀ��������ų��ӳ�����
--  2014-06-18   �ּ�ҫ   V01.00.002      ����DSS-ReqChange-1406-034��MIS�����Ż�����ڶ��ڣ��������ӻ���Դ��DM.TM_FINANC_CNSM_M
--  2015-03-16   �ּ�ҫ   V01.00.003      ����2015�궨�������ӻ���Դ��DM.TM_FINANC_MO_ZGPRS
--  2015-05-18   ������   V01.00.004      ���ݸĽ�_SR201412300005011_5���ϱ��Ľ�,�޸�ָ��DA4105�ĳ����߼�
--  2016-01-26   �ſ�     V01.00.005      ����SR201512290009001 ���ӻ���Դ��DM.TM_FINANC_MO_VOLTE
--  2016-11-16   �ƴ���   V01.00.006      �������� SR201610310013001 �����������������
--  2017-03-01   ��  ��   V01.00.006      �������� BR201702270010 ���ӵ����ֶ�
--  2017-07-28   �ƴ���   V01.00.007      ���Ӵ洢����PRO_TM_FINANC_MO_JFQD
--  ---------------------------------------------------------------------------
--  Current Version : V01.00.007
--  �������
--  vYearMonth ͳ���·�  ��ʽ YYYYMM
--  vReRunIndex :0����������.������������.
-------------------------------------------------------------------------------
P1: BEGIN
  -- ��־����
  DECLARE SQLCODE integer default 0;
  DECLARE vSqlCode varchar(20);
  DECLARE vProcStep VARCHAR(32);  -- �����㣨д������־ʱ�ã�
  DECLARE vMsgText  VARCHAR(256); -- ����������д������־ʱ�ã�
  DECLARE vCount    INTEGER;      -- ��д������־ʱ�ã�
  DECLARE vJobName  VARCHAR(200);  -- ��ҵ���ƣ�д������־ʱ�ã�
  DECLARE vEventDesc VARCHAR(512); -- ��д������־ʱ�ã�
  DECLARE vRowCount INTEGER;
  -- �������
  DECLARE vSqlText VARCHAR(32600);
  DECLARE target_table_name varchar(50);
  DECLARE procname varchar(64);      --�洢������
  DECLARE target_line varchar(128);  --����
  --������������
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS EXCEPTION 1 vMsgText = MESSAGE_TEXT;
    SET vSqlCode='SQLCODE'||char(SQLCODE);
    ROLLBACK;
    SET vRetCode=1;
    SET vEventDesc = vJobName ||  '���д���' || vMsgText;
    CALL ETL.INSERT_EVENT_LOG(vReRunIndex,vSqlCode, vEventDesc,0,0,0,vProcStep,0) ;
  END;

  -- ������ʼ��
  SET vRetCode = 0;
  SET vJobName = ' DM_MIS�±����ܱ�';
  SET vJobName = vJobName || '('||CHAR(vYearMonth)||',?)';
  SET vEventDesc = '';
  SET target_table_name = 'DM.TM_FINANC_MO ';
  SET procname = 'PRO_TM_FINANC_MO';
  SET target_line = 'current timestamp,'||procname||'';

   -- ����ʼ
  CALL ETL.INSERT_EVENT_LOG(vReRunIndex,'��ʼ����',vJobName || '��ʼ����',0,0,0,vProcStep,0) ;

  -- Step 0
  SET vProcStep = 'Step 0';

  IF vReRunIndex = 0
  THEN
    SET vProcStep = 'Step 0';
    SET vSqlText = 'DELETE FROM '||target_table_name||' WHERE TM_INTRVL_CD = '||CHAR(vYearMonth)||' AND PROCNAME <> ''PRO_TM_FINANC_MO_SP_DELAY'' ';
    PREPARE s1 FROM vSqlText;
         EXECUTE s1;
  END IF;

  -- Step  1: ���ݻ���
  -- �޸�˵��: 2012/7/9  ����   DSS-Def-1207-027 ����
  -- �޸�˵��: 2017/3/1  �ſ�   �����ֵ����ֶ�
  --           2017/7/26 �ƴ��� TM_FINANC_MO_BASI ������������
  SET vProcStep = 'Step 1';
  SET vEventDesc = vEventDesc ||vProcStep||':'||CHAR(current time)||';';
  SET vSqlText = ''
  ||'INSERT INTO '||target_table_name||'(TM_INTRVL_CD, CMCC_BRANCH_CD,TARGET_CD, VALUE, CREATE_TIM, PROCNAME) '
  ||'SELECT TM_INTRVL_CD ,CMCC_BRANCH_CD, TARGET_CD ,VALUE ,CREATE_TIM ,PROCNAME '
  ||'FROM DM.TM_FINANC_MO_BUSI '
  ||'WHERE TM_INTRVL_CD='||CHAR(vYearMonth)||' AND PROCNAME NOT IN(''PRO_TM_FINANC_MO_BUSI_SED'')   ' 
  ||'UNION ALL '
  ||'SELECT TM_INTRVL_CD ,CMCC_BRANCH_CD, TARGET_CD ,VALUE ,CREATE_TIM ,PROCNAME '
  ||'FROM DM.TM_FINANC_MO_SP '
  ||'WHERE TM_INTRVL_CD='||CHAR(vYearMonth)||' AND PROCNAME IN(''PRO_TM_FINANC_MO_SP'') '
  ||'UNION ALL '
  ||'SELECT TM_INTRVL_CD ,CMCC_BRANCH_CD, TARGET_CD ,VALUE ,CREATE_TIM ,PROCNAME '
  ||'FROM DM.TM_FINANC_MO_FUNC '
  ||'WHERE TM_INTRVL_CD='||CHAR(vYearMonth)||'  '
  ||'UNION ALL '
  ||'SELECT TM_INTRVL_CD ,CMCC_BRANCH_CD, TARGET_CD ,VALUE ,CREATE_TIM ,PROCNAME '
  ||'FROM DM.TM_FINANC_MO_BASI '
  ||'WHERE TM_INTRVL_CD='||CHAR(vYearMonth)||' AND (PROCNAME=''PRO_TM_FINANC_MO_BASI'' OR (PROCNAME=''PRO_TM_FINANC_MO_JFQD'' AND TARGET_CD=''DS3101'')) '
  ||'UNION ALL '
  ||'SELECT TM_INTRVL_CD ,CMCC_BRANCH_CD, TARGET_CD ,VALUE ,CREATE_TIM ,PROCNAME '
  ||'FROM DM.TM_FINANC_MO_TD '
  ||'WHERE TM_INTRVL_CD='||CHAR(vYearMonth)||'  '
  --20140618 linjiayao ���ӻ���Դ��DM.TM_FINANC_CNSM_M
  ||'UNION ALL '
  ||'SELECT STAT_MO ,CMCC_BRANCH_CD, TARGET_CD ,VALUE ,CREATE_TIM ,PROCNAME '
  ||'FROM DM.TM_FINANC_CNSM_M '
  ||'WHERE STAT_MO='||CHAR(vYearMonth)||' '
  --20150316 linjiayao ���Ӷ���Ǩ�Ƶ�һ�εĴ洢ָ��
  ||'UNION ALL '
  ||'SELECT TM_INTRVL_CD ,CMCC_BRANCH_CD, TARGET_CD ,VALUE ,CREATE_TIM ,PROCNAME '
  ||'FROM DM.TM_FINANC_MO_ZGPRS '
  ||'WHERE TM_INTRVL_CD='||CHAR(vYearMonth)||' '
  --20160126 zhngjun ����Volteָ��Ĵ洢
  --20170301 ����RPO_TM_FINANC_MO_VOLTE
  ||'UNION ALL '
  ||'SELECT TM_INTRVL_CD ,CMCC_BRANCH_CD, TARGET_CD ,VALUE ,CREATE_TIM ,PROCNAME '
  ||'FROM DM.TM_FINANC_MO_VOLTE '
  ||'WHERE TM_INTRVL_CD='||CHAR(vYearMonth)||' AND PROCNAME=''PRO_TM_FINANC_MO_IOT''  '    
  ||' ';
 PREPARE S1 FROM vSqlText;
 EXECUTE S1;

SET vEventDesc=vJobName || vEventDesc;

END P1