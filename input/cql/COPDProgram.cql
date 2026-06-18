/*
 * Library : COPD_Program
 * Title   : 慢性阻塞性肺病（COPD）醫療給付改善方案 CQL
 * Version : 0.1.0
 * Date    : 2026-05-24
 *
 * 撈取邏輯（依 CPG-16 v2，PDF 第三版 115/1/1）:
 *   - 主資源: Encounter
 *     + identifier 含 P 碼 ∈ {P6011C, P6012C, P6013C, P6014C, P6015C}
 *       system: https://nhi.gov.tw/fhir/identifier/case-mgmt-code（v1.5 §九-1 第 3 條）
 *     + identifier 含 特定治療項目代號（一）= 'HF'
 *       system: https://nhi.gov.tw/fhir/identifier/nhi-specific-treatment-code
 *       （v1.5 §九-1 第 5 條，CPG-15 EB/EK + CPG-22 E4 共 system）
 *     + identifier 含 健保案件分類 = 'E1'
 *       system: https://nhi.gov.tw/fhir/identifier/nhi-case-type（v1.5 §九-1 第 6 條，新增）
 *     + class.code ∈ {'AMB','IMP'}（d001=1 門診 / 2 住診）
 *     + status = 'finished'
 *     + 主診斷 ICD-10-CM 前三碼 ∈ {J41, J42, J43, J44}
 *
 *   - LookbackDays: 30 天（測試 workaround）；上線前回 CPG 規範
 *     「每月 1-20 申報上月份」（Interval[Date(year, month-1, 1), lastDay]）
 *
 * 關聯資源:
 *   - Patient / Practitioner / Organization / Location
 *   - Condition: COPD 主診斷 J41-J44 + 共病 d007-d018
 *   - MedicationStatement: 目前用藥 d020-d027（ATC 前綴比對）
 *   - Observation: 生命徵象 + 肺功能 FEV1 + CAT/mMRC + 急性惡化 + GOLD ABCD + 實驗室數值
 *   - Procedure: 肺功能檢查 17003C/17004B/17006C + 心電圖 18001C + 肺復原處置
 *   - CarePlan: 收案日期 / 結案日期 / 結案原因 / 肺復原計畫
 *   - QuestionnaireResponse: d002 診療階段 / CAT/mMRC 評估 / 病情變化 / 治療計畫變更
 *   - DiagnosticReport: 胸部 X 光 / CT
 *   - ServiceRequest: 下轉 / 上轉申請
 *   - AllergyIntolerance: 過敏病史 p006
 *
 * 命名規則（依 CPG_Production_Guide §6-3）:
 *   - 跨 CPG 標準: OrganizationCode, PatientIdNumber, PatientName, BirthDate,
 *                  GenderCode, HomePhone, Address, PractitionerIdNumber,
 *                  BodyHeight, BodyWeight
 *   - 本表 d 欄位: EncounterSource, CareStageCode, EnrollmentDate, 共病 Hx*,
 *                  目前用藥 Rx*, 肺功能 Fev1*, CAT/mMRC, 肺復原計畫 Cp*
 *
 * 業務邏輯（CPG-16 §3-2，12 小節 A-L）:
 *   - §3-2-A 診療階段 d002 分流（1/2/3）— 各階段必填欄位不同
 *   - §3-2-B 院所類型分流（一類 d109/d110、二類 d113/d114）
 *     ⚠️ v0.1.0 不分流，d109-d116 全部撈，由業務端後處理（§七 #1.22）
 *   - §3-2-C 共病互斥 d006↔d007-d018；d018=Y→d019 必填
 *   - §3-2-D 藥物互斥 d020↔d021-d027
 *   - §3-2-E 抽菸 d028=3 → d029 必填
 *   - §3-2-F 急性惡化心血管評估（EKG/NT-ProBNP/Troponin I）非 d 欄位
 *   - §3-2-G 肺功能聯動 d037↔d038-d043、d044↔d045-d047
 *   - §3-2-H d107=2 → d108 必填（1-10）
 *   - §3-2-I 肺復原 d080=1→d081-d106；d105=Y→d106 必填
 *   - §3-2-J 病情變化處置 d109/d110/d111/d112/d113/d114/d115/d116 聯動
 *   - §3-2-K close_rsn=9 → close_oth 必填；close_rsn 限 {1,2,3,4,5,9}
 *   - §3-2-L 品質獎勵計算（不在 CQL 範圍）
 *
 * 修正歷程:
 *   - v0.1.0: 初版（依 CPG-16 v2，PDF 第三版）
 *             (1) E1/HF 改放 Encounter.identifier（CPG §七 #1.21）
 *             (2) 院所類型不分流（CPG §七 #1.22，待補 HospitalType）
 *             (3) ATC ValueSet 用 inline placeholder（待業務提供）
 *             (4) HbA1c TWCore parser issue 同 CPG-15 inline workaround
 *             (5) 主資源 Encounter 三段 identifier 過濾（P 碼 + HF + E1）
 *
 * [待替換] URL（暫定，待 NHI 正式發布後 rename）:
 *   - https://nhi.gov.tw/fhir/identifier/case-mgmt-code（P 碼）
 *   - https://nhi.gov.tw/fhir/identifier/nhi-specific-treatment-code（HF）
 *   - https://nhi.gov.tw/fhir/identifier/nhi-case-type（E1）
 *   - http://nhi.gov.tw/fhir/CodeSystem/hospital-type-tw（院所類型 1/2）
 *   - http://nhi.gov.tw/fhir/CodeSystem/copd-care-stage-tw（d002 1/2/3）
 *   - http://nhi.gov.tw/fhir/CodeSystem/copd-exclusion-reason-tw（d108 1-10）
 *   - http://nhi.gov.tw/fhir/CodeSystem/copd-stable-handling-tw（d110 1-5）
 *   - http://nhi.gov.tw/fhir/CodeSystem/copd-exacerbation-handling-tw（d114 1-6）
 *   - http://nhi.gov.tw/fhir/CodeSystem/copd-close-reason-tw（close_rsn {1,2,3,4,5,9}）
 *   - ATC ValueSet placeholders（d021-d027）
 *
 * [待補] FHIR Path 不明確項目:
 *   - HospitalType（院所類型 1/2，CPG §1 + §3-2-B 描述但無 FHIR Path）
 *   - d002 CareStageCode（QR vs CarePlan.status，§4-4-C-1 [待補]）
 *   - d005 FamilyCopdHistory（FormMD 缺）
 *   - d030 LivingArrangement（Patient.extension vs QR，[待確認]）
 *   - d052 AcuteExacerbationFrequencyPastYear（LOINC 不明確）
 *   - 完整 ATC ValueSet（與 CPG-17/19/22 共用，業務未提供）
 *   - d097 肺擴張治療 / d099 節能活動指導 對應醫令
 *
 * [待確認] 業務面待確認項目:
 *   - E1 / HF 從 Encounter.type/extension 改 identifier（§七 #1.21）
 *   - 院所類型不分流（§七 #1.22），上線前須補
 *   - d108 / d110 / d114 / close_rsn 對應自訂 CodeSystem 是否 NHI 正式發布
 *   - 心血管評估 NT-ProBNP / Troponin I LOINC 是否 TWCore 收錄
 *   - 肺復原 d093-d106 採 CarePlan.activity 還是 Procedure
 */

library COPDProgram version '0.1.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers
include TWCoreCodeSystemsNHI version '1.3.0' called CS

// ===============================================================
// Code Systems
// ===============================================================
codesystem "LOINC":    'http://loinc.org'
codesystem "TWNID":    'http://hl7.org/fhir/sid/tw-nid'

// v1.5 §九-1 暫定 URI（v0.1.0 採用）
codesystem "CaseMgmtCode":         'https://nhi.gov.tw/fhir/identifier/case-mgmt-code'
codesystem "NhiSpecificTreatment": 'https://nhi.gov.tw/fhir/identifier/nhi-specific-treatment-code'
codesystem "NhiCaseType":          'https://nhi.gov.tw/fhir/identifier/nhi-case-type'

// [待替換] 6 個 placeholder CodeSystem URL（業務未指定正式 URL）
codesystem "HospitalTypeTw":             'http://nhi.gov.tw/fhir/CodeSystem/hospital-type-tw'
codesystem "CopdCareStageTw":            'http://nhi.gov.tw/fhir/CodeSystem/copd-care-stage-tw'
codesystem "CopdExclusionReasonTw":      'http://nhi.gov.tw/fhir/CodeSystem/copd-exclusion-reason-tw'
codesystem "CopdStableHandlingTw":       'http://nhi.gov.tw/fhir/CodeSystem/copd-stable-handling-tw'
codesystem "CopdExacerbationHandlingTw": 'http://nhi.gov.tw/fhir/CodeSystem/copd-exacerbation-handling-tw'
codesystem "CopdCloseReasonTw":          'http://nhi.gov.tw/fhir/CodeSystem/copd-close-reason-tw'

// ===============================================================
// Parameters
// ===============================================================
parameter "MeasurementPeriod" Interval<DateTime>
  default Interval[
    @2026-01-01T00:00:00.000,
    @2026-12-31T23:59:59.999
  ]

// CPG-16 §1 + §3-1: 每月 1-20 申報上月份；上線前須回 [上月1日, 上月末日]
// 30 days 為測試 workaround（同 CPG-04/15 慣例）
parameter "LookbackDays" Integer default 30

// ===============================================================
// Context
// ===============================================================
context Patient

// ===============================================================
// 代碼集合
// ===============================================================

// CPG-16 §2-1 P 碼
define "COPD_PCodes":
  { 'P6011C', 'P6012C', 'P6013C', 'P6014C', 'P6015C' }

// CPG-16 §2-2 特定治療項目代號（一）/ 案件分類
define "SpecificTreatment_HF": 'HF'
define "CaseType_E1": 'E1'

// CPG-16 §2-3 COPD 主診斷 ICD-10-CM 前三碼
define "COPD_DiagnosisPrefixes":
  { 'J41', 'J42', 'J43', 'J44' }

// CPG-16 §2-9 共病 ICD-10 前綴
define "Asthma_ICDPrefixes":              { 'J45' }
define "Tuberculosis_ICDPrefixes":        { 'A15', 'A16', 'A17', 'A18', 'A19' }
define "OccupationalLung_ICDPrefixes":    { 'J60', 'J61', 'J62', 'J63', 'J64', 'J65', 'J66', 'J67', 'J68', 'J69', 'J70' }
define "Hypertension_ICDPrefixes":        { 'I10', 'I11', 'I12', 'I13', 'I15' }
define "Diabetes_ICDPrefixes":            { 'E10', 'E11', 'E12', 'E13', 'E14' }
define "Cardiovascular_ICDPrefixes":      { 'I20', 'I21', 'I22', 'I23', 'I24', 'I25', 'I50' }
define "Osteoporosis_ICDPrefixes":        { 'M80', 'M81' }
define "Depression_ICDPrefixes":          { 'F32', 'F33' }
define "ChronicLiver_ICDPrefixes":        { 'K70', 'K71', 'K72', 'K73', 'K74', 'K75', 'K76', 'K77' }

// CPG-16 §2-4 肺功能醫令
define "Spirometry_17006C":         '17006C'
define "Spirometry_17003C_17004B":  { '17003C', '17004B' }

// CPG-16 §2-5 心電圖 / 影像醫令
define "EKG_OrderCode":             '18001C'
define "ChestXray_OrderCode":       '32001C'
define "BronchialProvocation_OrderCode": '17019C'
define "CT_OrderCode":              '33072B'

// CPG-16 §2-7 肺復原處置醫令（A 組 + B 組）
define "PulmonaryRehab_OrderCodes":
  { '47045C', '47090B', '57003C', '57010B', '57012B', '57017B', '57021C' }

// CPG-16 §2-10 排除原因 / 處置方式代碼集
define "ExclusionReason_d108_Codes":    { '1','2','3','4','5','6','7','8','9','10' }
define "StableHandling_d110_Codes":     { '1','2','3','4','5' }
define "ExacerbationHandling_d114_Codes": { '1','2','3','4','5','6' }
define "CloseReason_Codes":             { '1','2','3','4','5','9' }

// LOINC inline 宣告（CPG-16 §2-5 + §4-4-C 實驗室）
// [待確認] HbA1c 同 CPG-15 workaround（TWCore CS."HbA1c 糖化血色素 LOINC Codes" IDE 解析失敗）
define "HbA1c_LOINC_Codes":    { '4548-4' }
// 心血管評估 LOINC（CPG-16 §3-2-F，非 d 欄位）
define "NTProBNP_LOINC":       '33762-6'
define "TroponinI_LOINC":      '10839-9'
// 肺功能 LOINC
define "FEV1_LOINC":           '19868-9'
define "FEV1FVC_LOINC":        '19926-5'
// 生命徵象 LOINC（TWCore 無單獨收）
define "SystolicBP_LOINC":     '8480-6'
define "DiastolicBP_LOINC":    '8462-4'
define "HeartRate_LOINC":      '8867-4'
define "RespiratoryRate_LOINC":'9279-1'
// 實驗室 LOINC（CBC 等，TWCore 部分未收）
define "WBC_LOINC":            '6690-2'
define "RBC_LOINC":            '789-8'
define "Hemoglobin_LOINC":     '718-7'
define "Hematocrit_LOINC":     '4544-3'
define "Platelet_LOINC":       '777-3'
define "MCV_LOINC":            '787-2'
define "MCH_LOINC":            '785-6'
define "MCHC_LOINC":           '786-4'
define "WBCSeg_LOINC":         '770-8'
define "WBCEos_LOINC":         '713-8'
define "WBCBaso_LOINC":        '706-2'
define "WBCMono_LOINC":        '5905-5'
define "WBCLym_LOINC":         '736-9'
define "EosinophilCount_LOINC":'26449-9'
define "IgE_LOINC":            '19113-0'
define "Glucose_LOINC":        '2345-7'

// CPG-16 §2-6 ATC 藥物前綴
// [待替換] 完整 ATC ValueSet 由業務提供（與 CPG-17/19/22 共用）
define "ATC_SABA_SAMA_Prefixes":      { 'R03AC', 'R03BB' }
define "ATC_OralBronchodilator_Prefixes": { 'R03DA', 'R03CC' }
define "ATC_OralAntihistamine_Prefixes":  { 'R06A' }
define "ATC_LABA_LAMA_Mono_Prefixes": { 'R03AC', 'R03BB' }
define "ATC_LABA_LAMA_Combi_Prefixes":{ 'R03AL' }
define "ATC_ICS_LABA_Combi_Prefixes": { 'R03AK', 'R03AL' }
define "ATC_ICS_Mono_Prefixes":       { 'R03BA', 'H02AB' }

// ===============================================================
// Helper Functions（returns 型別明確宣告）
// ===============================================================

define function EncPeriodStartDT(E FHIR.Encounter) returns DateTime:
  E.period."start".value

define function ObsValueQuantity(O FHIR.Observation) returns Decimal:
  (O.value as FHIR.Quantity).value.value

define function ObsValueString(O FHIR.Observation) returns String:
  (O.value as FHIR.string).value

define function ObsValueCodeableCode(O FHIR.Observation) returns String:
  ((O.value as FHIR.CodeableConcept).coding[0].code).value

define function ObsValueCodeOrString(O FHIR.Observation) returns String:
  Coalesce(
    ObsValueCodeableCode(O),
    ObsValueString(O)
  )

define function ObsEffectiveDT(O FHIR.Observation) returns DateTime:
  (O.effective as FHIR.dateTime).value

define function ProcPerformedDT(P FHIR.Procedure) returns DateTime:
  Coalesce(
    (P.performed as FHIR.dateTime).value,
    (P.performed as FHIR.Period)."start".value
  )

// 是否含指定 LOINC code 集合
define function HasLoincIn(O FHIR.Observation, codes List<String>) returns Boolean:
  exists (
    O.code.coding C
      where C.system.value = 'http://loinc.org'
        and C.code.value in codes
  )

// 是否為單一 LOINC code
define function HasLoincCode(O FHIR.Observation, code String) returns Boolean:
  exists (
    O.code.coding C
      where C.system.value = 'http://loinc.org'
        and C.code.value = code
  )

// 是否含指定醫令代碼（Procedure 用）
define function HasOrderCode(P FHIR.Procedure, codes List<String>) returns Boolean:
  exists (
    P.code.coding C
      where C.code.value in codes
  )

// QR 取單一答案（多種 value 型別，含一層巢狀）
define function GetQRAnswer(QR FHIR.QuestionnaireResponse, lid String) returns String:
  Coalesce(
    First(
      QR.item I
        where I.linkId.value = lid
        return Coalesce(
          First(I.answer A return (A.value as FHIR.string).value),
          First(I.answer A return ((A.value as FHIR.Coding).code).value),
          First(I.answer A return ToString((A.value as FHIR.date).value)),
          First(I.answer A return ToString((A.value as FHIR.integer).value))
        )
    ),
    First(
      QR.item I
        where exists (I.item Sub where Sub.linkId.value = lid)
        return First(
          I.item Sub
            where Sub.linkId.value = lid
            return Coalesce(
              First(Sub.answer A return (A.value as FHIR.string).value),
              First(Sub.answer A return ((A.value as FHIR.Coding).code).value),
              First(Sub.answer A return ToString((A.value as FHIR.date).value)),
              First(Sub.answer A return ToString((A.value as FHIR.integer).value))
            )
        )
    )
  )

// Condition 主類別前綴比對（取前 3-5 碼）
define function ConditionMatchesPrefix(C FHIR.Condition, prefixes List<String>) returns Boolean:
  exists (
    C.code.coding Co
      where Substring(Coalesce(Co.code.value, ''), 0, 3) in prefixes
         or Substring(Coalesce(Co.code.value, ''), 0, 5) in prefixes
  )

// MedicationStatement ATC 前綴比對 — v0.1.0 暫不實作
// 原因：ATC ValueSet 待業務提供（與 CPG-17/19/22 共用），且 CQL parser 對
//      (M.medication as FHIR.CodeableConcept).coding alias 不穩；
//      d020-d027 改從 QR 讀（[待替換] 上線前須補正式 ATC 邏輯）

// ===============================================================
// Encounter 篩選（CPG-16 §3-1 + §2-0，三段 identifier 過濾）
// ===============================================================
define "RelevantEncountersSorted":
  [Encounter] E
    where E.subject.reference.value = 'Patient/' + Patient.id
      and EncPeriodStartDT(E) between (Now() - 30 days) and Now()
      and (E.class.code.value = 'AMB' or E.class.code.value = 'IMP')
      and E.status.value = 'finished'
      and exists (
        E.identifier I
          where I.system.value = 'https://nhi.gov.tw/fhir/identifier/case-mgmt-code'
            and I.value.value in "COPD_PCodes"
      )
      and exists (
        E.identifier I
          where I.system.value = 'https://nhi.gov.tw/fhir/identifier/nhi-specific-treatment-code'
            and I.value.value = 'HF'
      )
      and exists (
        E.identifier I
          where I.system.value = 'https://nhi.gov.tw/fhir/identifier/nhi-case-type'
            and I.value.value = 'E1'
      )
    return Tuple { sortKey: EncPeriodStartDT(E), item: E }
    sort by sortKey desc

define "LatestEncounter":
  First("RelevantEncountersSorted").item

define "HasEncounter":
  exists "RelevantEncountersSorted"

// ===============================================================
// 機構 chain（依 Guide §6-3-1）
// ===============================================================
define "EncounterLocations":
  [Location] Lo
    where exists (
      "LatestEncounter".location L
        where EndsWith(L.location.reference.value, Lo.id)
    )

define "EncounterOrganizations":
  [Organization] O
    where exists (
      "EncounterLocations" Lo
        where EndsWith(Lo.managingOrganization.reference.value, O.id)
    )

// ===============================================================
// 關聯資源查詢
// ===============================================================
define "PatientConditions":
  [Condition] C
    where C.subject.reference.value = 'Patient/' + Patient.id

define "EncounterConditions":
  [Condition] C
    where C.subject.reference.value = 'Patient/' + Patient.id
      and C.encounter.reference.value = 'Encounter/' + "LatestEncounter".id

define "EncounterObservations":
  [Observation] O
    where O.subject.reference.value = 'Patient/' + Patient.id
      and O.encounter.reference.value = 'Encounter/' + "LatestEncounter".id

define "EncounterProcedures":
  [Procedure] P
    where P.subject.reference.value = 'Patient/' + Patient.id
      and P.encounter.reference.value = 'Encounter/' + "LatestEncounter".id

define "PatientMedicationStatements":
  [MedicationStatement] M
    where M.subject.reference.value = 'Patient/' + Patient.id

define "PatientAllergyIntolerances":
  [AllergyIntolerance] AI
    where AI.patient.reference.value = 'Patient/' + Patient.id

define "EncounterCarePlans":
  [CarePlan] CP
    where CP.subject.reference.value = 'Patient/' + Patient.id
      and CP.encounter.reference.value = 'Encounter/' + "LatestEncounter".id

define "LatestCarePlan":
  First(
    "EncounterCarePlans" CP
      return Tuple { sortKey: CP.period."start".value, item: CP }
      sort by sortKey desc
  ).item

define "EncounterQuestionnaireResponses":
  [QuestionnaireResponse] QR
    where QR.subject.reference.value = 'Patient/' + Patient.id
      and QR.encounter.reference.value = 'Encounter/' + "LatestEncounter".id

define "LatestQuestionnaireResponse":
  First(
    "EncounterQuestionnaireResponses" QR
      return Tuple { sortKey: QR.authored.value, item: QR }
      sort by sortKey desc
  ).item

define "EncounterPractitioners":
  [Practitioner] P
    where exists (
      "LatestEncounter".participant Pa
        where EndsWith(Pa.individual.reference.value, P.id)
    )

define "PatientServiceRequests":
  [ServiceRequest] SR
    where SR.subject.reference.value = 'Patient/' + Patient.id

// ===============================================================
// §6-1-A 識別資料（hospid_2 / id / birthday）
// ===============================================================

// 輸出欄位：醫事機構代碼（linkId：hospid_2）
define "OrganizationCode":
  First(
    "EncounterOrganizations" O
      return First(
        O.identifier I
          where I.value is not null
          return I.value.value
      )
  )

// 輸出欄位：身分證號（linkId：id）
define "PatientIdNumber":
  First(
    Patient.identifier I
      where I.system.value = 'http://hl7.org/fhir/sid/tw-nid'
         or exists (I.type.coding Co where Co.code.value = 'NI')
      return I.value.value
  )

// 輸出欄位：生日（linkId：birthday）
define "BirthDate":
  Patient.birthDate.value

// ===============================================================
// §6-1-B sec01 基本資料（p001-p006）
// ===============================================================

// 輸出欄位：姓名（linkId：section_01_p001）
define "PatientName":
  First(Patient.name N return N.text.value)

// 輸出欄位：性別（linkId：section_01_p002）
define "GenderCode":
  case Patient.gender.value
    when 'male'   then '1'
    when 'female' then '2'
    else null
  end

// 輸出欄位：通訊地址（linkId：section_01_p003）
define "Address":
  First(Patient.address A return A.text.value)

// 輸出欄位：電話（linkId：section_01_p004）
define "HomePhone":
  First(
    Patient.telecom T
      where T.system.value = 'phone'
      return T.value.value
  )

// 輸出欄位：家族病史（linkId：section_01_p005）
// [待補] Observation.valueCodeableConcept（FormMD 缺）；暫從 QR 讀
define "FamilyHistory":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_01_p005')

// 輸出欄位：過敏病史（linkId：section_01_p006）
define "AllergyHistory":
  if exists ("PatientAllergyIntolerances")
    then '1'
    else '2'

// ===============================================================
// §6-1-C sec02 收案資訊（d001-d005）
// ===============================================================

// 輸出欄位：收案來源（linkId：section_02_d001）1 門診 / 2 住診
define "EncounterSource":
  case "LatestEncounter".class.code.value
    when 'AMB' then '1'
    when 'IMP' then '2'
    else null
  end

// 輸出欄位：診療階段（linkId：section_02_d002）1 新收 / 2 追蹤 / 3 年評
// [待補] CPG §6-1-C 寫 QR.item.valueCoding 或 CarePlan.status，v0.1.0 暫從 QR 讀
define "CareStageCode":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d002')

// 輸出欄位：收案日期（linkId：section_02_d003）
define "EnrollmentDate":
  "LatestCarePlan".period."start".value

// 輸出欄位：醫事人員身分證號（linkId：section_02_d004）
define "PractitionerIdNumber":
  First(
    "EncounterPractitioners" Pr
      return First(
        Pr.identifier I
          where I.system.value = 'http://hl7.org/fhir/sid/tw-nid'
             or exists (I.type.coding Co where Co.code.value in { 'NI', 'MD' })
          return I.value.value
      )
  )

// 輸出欄位：家族 COPD 病史（linkId：section_02_d005）
// [待補] FormMD 缺 FHIR Path，暫從 QR 讀
define "FamilyCopdHistory":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d005')

// ===============================================================
// §6-1-D 共病（d006-d019）
// ===============================================================

// 輸出欄位：目前共病_無（linkId：section_02_d006）Y/N flag
define "NoComorbidity":
  if not exists (
    "EncounterConditions" C
      where ConditionMatchesPrefix(C, "Asthma_ICDPrefixes" union "Tuberculosis_ICDPrefixes"
        union "OccupationalLung_ICDPrefixes" union "Hypertension_ICDPrefixes"
        union "Diabetes_ICDPrefixes" union "Cardiovascular_ICDPrefixes"
        union "Osteoporosis_ICDPrefixes" union "Depression_ICDPrefixes"
        union "ChronicLiver_ICDPrefixes")
  )
    then 'Y'
    else 'N'

// 輸出欄位：共病_氣喘（linkId：section_02_d007）
define "HxAsthma":
  if exists ("EncounterConditions" C where ConditionMatchesPrefix(C, "Asthma_ICDPrefixes"))
    then 'Y' else 'N'

// 輸出欄位：共病_肺結核（linkId：section_02_d008）
define "HxTuberculosis":
  if exists ("EncounterConditions" C where ConditionMatchesPrefix(C, "Tuberculosis_ICDPrefixes"))
    then 'Y' else 'N'

// 輸出欄位：共病_職業性肺病（linkId：section_02_d009）
define "HxOccupationalLung":
  if exists ("EncounterConditions" C where ConditionMatchesPrefix(C, "OccupationalLung_ICDPrefixes"))
    then 'Y' else 'N'

// 輸出欄位：共病_胸腔手術（linkId：section_02_d010）
// [待補] 手術病史 ICD-10 不明確，暫從 QR 讀
define "HxThoracicSurgery":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d010')

// 輸出欄位：共病_高血壓（linkId：section_02_d011）
define "HxHypertension":
  if exists ("EncounterConditions" C where ConditionMatchesPrefix(C, "Hypertension_ICDPrefixes"))
    then 'Y' else 'N'

// 輸出欄位：共病_糖尿病（linkId：section_02_d012）
define "HxDiabetes":
  if exists ("EncounterConditions" C where ConditionMatchesPrefix(C, "Diabetes_ICDPrefixes"))
    then 'Y' else 'N'

// 輸出欄位：共病_心臟血管疾病（linkId：section_02_d013）
define "HxCardiovascular":
  if exists ("EncounterConditions" C where ConditionMatchesPrefix(C, "Cardiovascular_ICDPrefixes"))
    then 'Y' else 'N'

// 輸出欄位：共病_骨質疏鬆（linkId：section_02_d014）
define "HxOsteoporosis":
  if exists ("EncounterConditions" C where ConditionMatchesPrefix(C, "Osteoporosis_ICDPrefixes"))
    then 'Y' else 'N'

// 輸出欄位：共病_憂鬱症（linkId：section_02_d015）
define "HxDepression":
  if exists ("EncounterConditions" C where ConditionMatchesPrefix(C, "Depression_ICDPrefixes"))
    then 'Y' else 'N'

// 輸出欄位：共病_慢性肝病（linkId：section_02_d016）
define "HxChronicLiverDisease":
  if exists ("EncounterConditions" C where ConditionMatchesPrefix(C, "ChronicLiver_ICDPrefixes"))
    then 'Y' else 'N'

// 輸出欄位：共病_感染病史（linkId：section_02_d017）
// [待補] 感染病史 ICD-10 不明確，暫從 QR 讀
define "HxInfection":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d017')

// 輸出欄位：共病_其他（linkId：section_02_d018）
// 暫從 QR 讀（其他共病無單一 ICD-10）
define "HxOtherComorbidity":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d018')

// 輸出欄位：其他說明（linkId：section_02_d019）
// 聯動：HxOtherComorbidity='Y' 時必填，其他為 null
define "OtherComorbidityDescription":
  if Coalesce("HxOtherComorbidity", '') = 'Y' then
    GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d019')
  else null

// ===============================================================
// §6-1-E 目前使用藥物（d020-d027）
// [待替換] ATC ValueSet 由業務提供（與 CPG-17/19/22 共用），v0.1.0 全部從 QR 讀
// 上線前須補正式 MedicationStatement.medication.coding ATC 前綴比對
// ===============================================================

// 輸出欄位：目前使用藥物_無（linkId：section_02_d020）
define "NoMedication":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d020')

// 輸出欄位：短效支氣管擴張劑（linkId：section_02_d021）[待替換] ATC
define "RxShortActingBronchodilator":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d021')

// 輸出欄位：口服支氣管擴張劑（linkId：section_02_d022）[待替換] ATC
define "RxOralBronchodilator":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d022')

// 輸出欄位：口服減敏藥物（linkId：section_02_d023）[待替換] ATC
define "RxOralAntihistamine":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d023')

// 輸出欄位：單方長效支氣管擴張劑（linkId：section_02_d024）[待替換] ATC
define "RxLongActingMonoBronchodilator":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d024')

// 輸出欄位：複方長效支氣管擴張劑（linkId：section_02_d025）[待替換] ATC
define "RxLongActingCombiBronchodilator":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d025')

// 輸出欄位：複方含吸入性類固醇支氣管擴張劑（linkId：section_02_d026）[待替換] ATC
define "RxIcsCombiBronchodilator":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d026')

// 輸出欄位：單方類固醇（linkId：section_02_d027）[待替換] ATC
define "RxMonoSteroid":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d027')

// ===============================================================
// §6-1-F 抽菸 / 家庭 / 生命徵象（d028-d036）
// ===============================================================

// 輸出欄位：抽菸史（linkId：section_02_d028）1 從未 / 2 已戒 / 3 未戒
define "SmokingStatus":
  Coalesce(
    First(
      "EncounterObservations" O
        where HasLoincCode(O, CS."吸菸狀態 LOINC")
        return ObsValueCodeOrString(O)
    ),
    GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d028')
  )

// 輸出欄位：抽菸包數（linkId：section_02_d029）d028=3 時必填
define "CigarettePacksPerDay":
  if Coalesce("SmokingStatus", '') = '3' then
    GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d029')
  else null

// 輸出欄位：家庭狀況（linkId：section_02_d030）1 獨居 / 2 有同居者
// [待確認] Patient.extension vs QR
define "LivingArrangement":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d030')

// 輸出欄位：身高（linkId：section_02_d031）
define "BodyHeight":
  First(
    "EncounterObservations" O
      where HasLoincCode(O, CS."身高 LOINC")
      return ObsValueQuantity(O)
  )

// 輸出欄位：體重（linkId：section_02_d032）
define "BodyWeight":
  First(
    "EncounterObservations" O
      where HasLoincCode(O, CS."體重 LOINC")
      return ObsValueQuantity(O)
  )

// 輸出欄位：收縮壓（linkId：section_02_d033）
define "SystolicBloodPressure":
  First(
    "EncounterObservations" O
      where HasLoincCode(O, "SystolicBP_LOINC")
      return ObsValueQuantity(O)
  )

// 輸出欄位：舒張壓（linkId：section_02_d034）
define "DiastolicBloodPressure":
  First(
    "EncounterObservations" O
      where HasLoincCode(O, "DiastolicBP_LOINC")
      return ObsValueQuantity(O)
  )

// 輸出欄位：脈搏（linkId：section_02_d035）
define "HeartRate":
  First(
    "EncounterObservations" O
      where HasLoincCode(O, "HeartRate_LOINC")
      return ObsValueQuantity(O)
  )

// 輸出欄位：呼吸（linkId：section_02_d036）
define "RespiratoryRate":
  First(
    "EncounterObservations" O
      where HasLoincCode(O, "RespiratoryRate_LOINC")
      return ObsValueQuantity(O)
  )

// ===============================================================
// §6-1-G 肺功能 / CAT / mMRC / GOLD（d037-d053）
// ===============================================================

// 輸出欄位：17006C 肺功能檢查日期（linkId：section_02_d037）新收案必填
define "Spirometry17006Date":
  First(
    "EncounterProcedures" P
      where HasOrderCode(P, { '17006C' })
      return ProcPerformedDT(P)
  )

// 輸出欄位：FEV1 使用支氣管擴張劑前（linkId：section_02_d038）
define "Fev1PreBronchodilator":
  First(
    "EncounterObservations" O
      where HasLoincCode(O, "FEV1_LOINC")
      return ObsValueQuantity(O)
  )

// 輸出欄位：FEV1% 使用支氣管擴張劑前（linkId：section_02_d039）
// [待確認] 從 QR 讀（無單獨 LOINC for 百分比評估值）
define "Fev1PercentPreBronchodilator":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d039')

// 輸出欄位：FEV1/FVC% 使用支氣管擴張劑前（linkId：section_02_d040）
define "Fev1FvcRatioPreBronchodilator":
  First(
    "EncounterObservations" O
      where HasLoincCode(O, "FEV1FVC_LOINC")
      return ObsValueQuantity(O)
  )

// 輸出欄位：FEV1 使用支氣管擴張劑後（linkId：section_02_d041）
// [待確認] 同 d038 需 qualifier pre/post-bronchodilator 區分；v0.1.0 暫從 QR 讀
define "Fev1PostBronchodilator":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d041')

// 輸出欄位：FEV1% 使用支氣管擴張劑後（linkId：section_02_d042）
define "Fev1PercentPostBronchodilator":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d042')

// 輸出欄位：FEV1/FVC% 使用支氣管擴張劑後（linkId：section_02_d043）
define "Fev1FvcRatioPostBronchodilator":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d043')

// 輸出欄位：17003C/17004B 肺功能檢查日期（linkId：section_02_d044）年評必填
define "Spirometry17003Or17004Date":
  First(
    "EncounterProcedures" P
      where HasOrderCode(P, "Spirometry_17003C_17004B")
      return ProcPerformedDT(P)
  )

// 輸出欄位：FEV1% 評估值（linkId：section_02_d045）
define "Fev1PercentEstimated":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d045')

// 輸出欄位：FEV1/FVC% 預估值（linkId：section_02_d046）
define "Fev1FvcRatioEstimated":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d046')

// 輸出欄位：FEV1（linkId：section_02_d047）
define "Fev1":
  First(
    "EncounterObservations" O
      where HasLoincCode(O, "FEV1_LOINC")
      return ObsValueQuantity(O)
  )

// 輸出欄位：CAT 評估日期（linkId：section_02_d048）
define "CatAssessmentDate":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d048')

// 輸出欄位：CAT 分數（linkId：section_02_d049）
define "CatScore":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d049')

// 輸出欄位：mMRC 評估日期（linkId：section_02_d050）
define "MmrcAssessmentDate":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d050')

// 輸出欄位：mMRC 分數（linkId：section_02_d051）
define "MmrcScore":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d051')

// 輸出欄位：過去一年急性惡化發作頻率（linkId：section_02_d052）
// [待補] LOINC 不明確
define "AcuteExacerbationFrequencyPastYear":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d052')

// 輸出欄位：COPD GOLD ABCD（linkId：section_02_d053）A/B/C/D 字母
// ⚠️ Observation.valueCodeableConcept（FormMD 寫 valueQuantity 為誤，CPG §6-1-G 已修正）
define "GoldStage":
  Coalesce(
    First(
      "EncounterObservations" O
        where exists (O.code.coding C where C.code.value = 'gold-stage')  // [待替換] placeholder code
        return ObsValueCodeableCode(O)
    ),
    GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d053')
  )

// ===============================================================
// §6-1-H 實驗室（d054-d074）
// ===============================================================

// 輸出欄位：實驗室檢查日期（linkId：section_02_d054）取 WBC 的 effective
define "LabTestDate":
  First(
    "EncounterObservations" O
      where HasLoincCode(O, "WBC_LOINC")
      return ObsEffectiveDT(O)
  )

// 輸出欄位：WBC（linkId：section_02_d055）
define "WBC":
  First("EncounterObservations" O where HasLoincCode(O, "WBC_LOINC") return ObsValueQuantity(O))

// 輸出欄位：RBC（linkId：section_02_d056）
define "RBC":
  First("EncounterObservations" O where HasLoincCode(O, "RBC_LOINC") return ObsValueQuantity(O))

// 輸出欄位：Hemoglobin（linkId：section_02_d057）
define "Hemoglobin":
  First("EncounterObservations" O where HasLoincCode(O, "Hemoglobin_LOINC") return ObsValueQuantity(O))

// 輸出欄位：Hematocrit（linkId：section_02_d058）
define "Hematocrit":
  First("EncounterObservations" O where HasLoincCode(O, "Hematocrit_LOINC") return ObsValueQuantity(O))

// 輸出欄位：Platelet count（linkId：section_02_d059）
define "PlateletCount":
  First("EncounterObservations" O where HasLoincCode(O, "Platelet_LOINC") return ObsValueQuantity(O))

// 輸出欄位：MCV（linkId：section_02_d060）
define "MCV":
  First("EncounterObservations" O where HasLoincCode(O, "MCV_LOINC") return ObsValueQuantity(O))

// 輸出欄位：MCH（linkId：section_02_d061）
define "MCH":
  First("EncounterObservations" O where HasLoincCode(O, "MCH_LOINC") return ObsValueQuantity(O))

// 輸出欄位：MCHC（linkId：section_02_d062）
define "MCHC":
  First("EncounterObservations" O where HasLoincCode(O, "MCHC_LOINC") return ObsValueQuantity(O))

// 輸出欄位：WBC 分類-Seg（linkId：section_02_d063）
define "WBCSegPercent":
  First("EncounterObservations" O where HasLoincCode(O, "WBCSeg_LOINC") return ObsValueQuantity(O))

// 輸出欄位：WBC 分類-Eos（linkId：section_02_d064）
define "WBCEosPercent":
  First("EncounterObservations" O where HasLoincCode(O, "WBCEos_LOINC") return ObsValueQuantity(O))

// 輸出欄位：WBC 分類-Baso（linkId：section_02_d065）
define "WBCBasoPercent":
  First("EncounterObservations" O where HasLoincCode(O, "WBCBaso_LOINC") return ObsValueQuantity(O))

// 輸出欄位：WBC 分類-Mono（linkId：section_02_d066）
define "WBCMonoPercent":
  First("EncounterObservations" O where HasLoincCode(O, "WBCMono_LOINC") return ObsValueQuantity(O))

// 輸出欄位：WBC 分類-Lym（linkId：section_02_d067）
define "WBCLymPercent":
  First("EncounterObservations" O where HasLoincCode(O, "WBCLym_LOINC") return ObsValueQuantity(O))

// 輸出欄位：嗜酸性白血球計算（linkId：section_02_d068）⚠ 不是 EKG
define "EosinophilCount":
  First("EncounterObservations" O where HasLoincCode(O, "EosinophilCount_LOINC") return ObsValueQuantity(O))

// 輸出欄位:免疫球蛋白 E（linkId：section_02_d069）⚠ 不是 NT-ProBNP
define "ImmunoglobulinE":
  First("EncounterObservations" O where HasLoincCode(O, "IgE_LOINC") return ObsValueQuantity(O))

// 輸出欄位：免疫球蛋白 E 檢驗日期（linkId：section_02_d070）
define "ImmunoglobulinEDate":
  First("EncounterObservations" O where HasLoincCode(O, "IgE_LOINC") return ObsEffectiveDT(O))

// 輸出欄位：血液葡萄糖（linkId：section_02_d071）
define "BloodGlucose":
  First("EncounterObservations" O where HasLoincCode(O, "Glucose_LOINC") return ObsValueQuantity(O))

// 輸出欄位：血液葡萄糖檢驗日期（linkId：section_02_d072）
define "BloodGlucoseDate":
  First("EncounterObservations" O where HasLoincCode(O, "Glucose_LOINC") return ObsEffectiveDT(O))

// 輸出欄位：糖化血色素（linkId：section_02_d073）
// inline workaround：TWCore CS."HbA1c 糖化血色素 LOINC Codes" IDE 解析失敗
define "HbA1c":
  First("EncounterObservations" O where HasLoincIn(O, "HbA1c_LOINC_Codes") return ObsValueQuantity(O))

// 輸出欄位：糖化血色素檢驗日期（linkId：section_02_d074）
define "HbA1cDate":
  First("EncounterObservations" O where HasLoincIn(O, "HbA1c_LOINC_Codes") return ObsEffectiveDT(O))

// ===============================================================
// §6-1-I 影像（d076 / d078 / d079）
// ===============================================================

// 輸出欄位：胸部 X 光檢驗日期（linkId：section_02_d076）
define "ChestXrayDate":
  First(
    "EncounterProcedures" P
      where HasOrderCode(P, { '32001C' })
      return ProcPerformedDT(P)
  )

// 輸出欄位：支氣管激發試驗檢驗日期（linkId：section_02_d078）
define "BronchialProvocationTestDate":
  First(
    "EncounterProcedures" P
      where HasOrderCode(P, { '17019C' })
      return ProcPerformedDT(P)
  )

// 輸出欄位：電腦斷層檢驗日期（linkId：section_02_d079）
define "ComputedTomographyDate":
  First(
    "EncounterProcedures" P
      where HasOrderCode(P, { '33072B' })
      return ProcPerformedDT(P)
  )

// ===============================================================
// §6-1-J 肺部復原管理評估（d080-d092）
// ===============================================================

// 輸出欄位：肺部復原管理評估（linkId：section_02_d080）1 有 / 2 無
define "PulmonaryRehabAssessment":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d080')

// 輸出欄位：肺部復原管理評估日期（linkId：section_02_d081）d080=1 必填
define "PulmonaryRehabAssessmentDate":
  if Coalesce("PulmonaryRehabAssessment", '') = '1' then
    GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d081')
  else null

// 輸出欄位：呼吸問題_痰液清除功能不足（linkId：section_02_d082）
define "RespIssueSputumClearance":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d082')

// 輸出欄位：呼吸問題_低血氧（linkId：section_02_d083）
define "RespIssueHypoxemia":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d083')

// 輸出欄位：呼吸問題_高二氧化碳血症（linkId：section_02_d084）
define "RespIssueHypercapnia":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d084')

// 輸出欄位：呼吸問題_肺容積不足（linkId：section_02_d085）
define "RespIssueLowLungVolume":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d085')

// 輸出欄位：呼吸問題_活動時喘（linkId：section_02_d086）
define "RespIssueDyspneaOnActivity":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d086')

// 輸出欄位：呼吸問題_肢體肌力不足（linkId：section_02_d087）
define "RespIssueLowMuscleStrength":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d087')

// 輸出欄位：呼吸問題_睡眠呼吸障礙（linkId：section_02_d088）
define "RespIssueSleepDisorder":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d088')

// 輸出欄位：異常呼吸型態/肩頸肌肥大（linkId：section_02_d089）
define "RespIssueAbnormalBreathingPattern":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d089')

// 輸出欄位：呼吸問題_胸廓畸形/桶狀胸（linkId：section_02_d090）
define "RespIssueChestDeformity":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d090')

// 輸出欄位：呼吸問題_其他（linkId：section_02_d091）
define "RespIssueOther":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d091')

// 輸出欄位：其他說明（linkId：section_02_d092）d091=Y 時必填
define "RespIssueOtherDescription":
  if Coalesce("RespIssueOther", '') = 'Y' then
    GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d092')
  else null

// ===============================================================
// §6-1-K 肺復原照護計畫（d093-d106）→ Procedure 雙路徑
// ===============================================================

define function HasRehabProcedure(codes List<String>) returns String:
  if exists ("EncounterProcedures" P where HasOrderCode(P, codes))
    then 'Y' else 'N'

// 輸出欄位：氣道清潔治療（linkId：section_02_d093）47045C(A) / 47090B(B)
define "CpAirwayClearance": HasRehabProcedure({ '47045C', '47090B' })

// 輸出欄位：濕氣/噴霧治療（linkId：section_02_d094）57021C
define "CpHumidificationNebulization": HasRehabProcedure({ '57021C' })

// 輸出欄位：氧氣治療休息時用（linkId：section_02_d095）57003C
define "CpOxygenAtRest": HasRehabProcedure({ '57003C' })

// 輸出欄位：氧氣治療活動/運動時用（linkId：section_02_d096）57003C
define "CpOxygenWithActivity": HasRehabProcedure({ '57003C' })

// 輸出欄位：肺擴張治療（linkId：section_02_d097）[待釐清] 無直接對應醫令
define "CpLungExpansion":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d097')

// 輸出欄位：呼吸訓練（linkId：section_02_d098）57010B
define "CpBreathingTraining": HasRehabProcedure({ '57010B' })

// 輸出欄位：節能活動指導（linkId：section_02_d099）[待釐清] 衛教類無單一醫令
define "CpEnergyConservationGuidance":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d099')

// 輸出欄位：走路運動（linkId：section_02_d100）57012B
define "CpWalkingExercise": HasRehabProcedure({ '57012B' })

// 輸出欄位：阻力腳踏車（linkId：section_02_d101）57012B
define "CpResistanceCycling": HasRehabProcedure({ '57012B' })

// 輸出欄位：肢體運動_上肢（linkId：section_02_d102）57012B
define "CpUpperLimbExercise": HasRehabProcedure({ '57012B' })

// 輸出欄位：肢體運動_下肢（linkId：section_02_d103）57012B
define "CpLowerLimbExercise": HasRehabProcedure({ '57012B' })

// 輸出欄位：呼吸肌力訓練（linkId：section_02_d104）57010B
define "CpRespiratoryMuscleTraining": HasRehabProcedure({ '57010B' })

// 輸出欄位：其他（linkId：section_02_d105）
define "CpOther":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d105')

// 輸出欄位：其他說明（linkId：section_02_d106）d105=Y 必填
define "CpOtherDescription":
  if Coalesce("CpOther", '') = 'Y' then
    GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d106')
  else null

// ===============================================================
// §6-1-L 排除個案 / 病情變化 / 結案（d107-close_oth）
// ===============================================================

// 輸出欄位：列入獎勵指標之個案（linkId：section_02_d107）1 是 / 2 否
define "IncludedInRewardIndicator":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d107')

// 輸出欄位：排除原因（linkId：section_02_d108）1-10，d107=2 必填
define "ExclusionReason":
  if Coalesce("IncludedInRewardIndicator", '') = '2' then
    GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d108')
  else null

// 輸出欄位：第一類病情穩定（linkId：section_02_d109）一類醫院追蹤/年評必填
// ⚠️ v0.1.0 院所類型不分流，全部撈，業務端後處理（§七 #1.22）
define "Type1StableCondition":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d109')

// 輸出欄位：穩定處理方式（linkId：section_02_d110）1-5，d109=1 必填
define "StableHandlingMethod":
  if Coalesce("Type1StableCondition", '') = '1' then
    GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d110')
  else null

// 輸出欄位：下轉醫事機構代號（linkId：section_02_d111）d110=1,2 必填
// [待確認] ServiceRequest.performer → Organization chain
define "DownReferralOrganizationCode":
  if Coalesce("StableHandlingMethod", '') in { '1', '2' } then
    GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d111')
  else null

// 輸出欄位：下轉日期（linkId：section_02_d112）d110=1,2 必填
define "DownReferralDate":
  if Coalesce("StableHandlingMethod", '') in { '1', '2' } then
    GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d112')
  else null

// 輸出欄位：第二類病情變化_急性惡化（linkId：section_02_d113）
define "Type2AcuteExacerbation":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d113')

// 輸出欄位：惡化處理方式（linkId：section_02_d114）1-6，d113=1 必填
define "ExacerbationHandlingMethod":
  if Coalesce("Type2AcuteExacerbation", '') = '1' then
    GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d114')
  else null

// 輸出欄位：上轉醫事機構代號（linkId：section_02_d115）d114=1,2,3 必填
define "UpReferralOrganizationCode":
  if Coalesce("ExacerbationHandlingMethod", '') in { '1', '2', '3' } then
    GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d115')
  else null

// 輸出欄位：上轉日期（linkId：section_02_d116）d114=1,2,3 必填
define "UpReferralDate":
  if Coalesce("ExacerbationHandlingMethod", '') in { '1', '2', '3' } then
    GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d116')
  else null

// 輸出欄位：喘鳴聲（linkId：section_02_d117）1 有 / 2 無
define "Wheezing":
  Coalesce(
    First(
      "EncounterObservations" O
        where exists (O.code.coding C where C.code.value = 'wheezing')  // [待替換] placeholder
        return ObsValueCodeOrString(O)
    ),
    GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d117')
  )

// 輸出欄位：治療計劃變更_調整藥物品項（linkId：section_02_d118）1 是 / 2 否
define "TreatmentChangeMedicationItem":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d118')

// 輸出欄位：治療計劃變更_調整藥物劑量（linkId：section_02_d119）1 有 / 2 無
define "TreatmentChangeMedicationDose":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_d119')

// 輸出欄位：結案日期（linkId：section_02_close_date）
define "CloseDate":
  "LatestCarePlan".period."end".value

// 輸出欄位：結案原因（linkId：section_02_close_rsn）{1,2,3,4,5,9}
// [待補] FHIR R4 CarePlan 無 statusReason 欄位（該欄位屬 ServiceRequest/Task）
// v0.1.0 暫從 QR 讀；上線前須建 Taiwan 自訂 extension（close-reason-tw）或 CarePlan.note
define "CloseReason":
  GetQRAnswer("LatestQuestionnaireResponse", 'section_02_close_rsn')

// 輸出欄位：結案原因（其他）（linkId：section_02_close_oth）close_rsn=9 必填
define "CloseReasonOther":
  if Coalesce("CloseReason", '') = '9' then
    GetQRAnswer("LatestQuestionnaireResponse", 'section_02_close_oth')
  else null

// ===============================================================
// Summary Tuple（SDC $populate 使用，key = Questionnaire linkId）
// ===============================================================
define "Summary":
  Tuple {
    // --- §6-1-A 識別 ---
    hospid_2                : "OrganizationCode",
    id                      : "PatientIdNumber",
    birthday                : "BirthDate",

    // --- §6-1-B sec01 基本 ---
    section_01_p001         : "PatientName",
    section_01_p002         : "GenderCode",
    section_01_p003         : "Address",
    section_01_p004         : "HomePhone",
    section_01_p005         : "FamilyHistory",
    section_01_p006         : "AllergyHistory",

    // --- §6-1-C sec02 收案 ---
    section_02_d001         : "EncounterSource",
    section_02_d002         : "CareStageCode",
    section_02_d003         : "EnrollmentDate",
    section_02_d004         : "PractitionerIdNumber",
    section_02_d005         : "FamilyCopdHistory",

    // --- §6-1-D 共病 ---
    section_02_d006         : "NoComorbidity",
    section_02_d007         : "HxAsthma",
    section_02_d008         : "HxTuberculosis",
    section_02_d009         : "HxOccupationalLung",
    section_02_d010         : "HxThoracicSurgery",
    section_02_d011         : "HxHypertension",
    section_02_d012         : "HxDiabetes",
    section_02_d013         : "HxCardiovascular",
    section_02_d014         : "HxOsteoporosis",
    section_02_d015         : "HxDepression",
    section_02_d016         : "HxChronicLiverDisease",
    section_02_d017         : "HxInfection",
    section_02_d018         : "HxOtherComorbidity",
    section_02_d019         : "OtherComorbidityDescription",

    // --- §6-1-E 目前藥物 ---
    section_02_d020         : "NoMedication",
    section_02_d021         : "RxShortActingBronchodilator",
    section_02_d022         : "RxOralBronchodilator",
    section_02_d023         : "RxOralAntihistamine",
    section_02_d024         : "RxLongActingMonoBronchodilator",
    section_02_d025         : "RxLongActingCombiBronchodilator",
    section_02_d026         : "RxIcsCombiBronchodilator",
    section_02_d027         : "RxMonoSteroid",

    // --- §6-1-F 抽菸/家庭/生命徵象 ---
    section_02_d028         : "SmokingStatus",
    section_02_d029         : "CigarettePacksPerDay",
    section_02_d030         : "LivingArrangement",
    section_02_d031         : "BodyHeight",
    section_02_d032         : "BodyWeight",
    section_02_d033         : "SystolicBloodPressure",
    section_02_d034         : "DiastolicBloodPressure",
    section_02_d035         : "HeartRate",
    section_02_d036         : "RespiratoryRate",

    // --- §6-1-G 肺功能/CAT/mMRC/GOLD ---
    section_02_d037         : "Spirometry17006Date",
    section_02_d038         : "Fev1PreBronchodilator",
    section_02_d039         : "Fev1PercentPreBronchodilator",
    section_02_d040         : "Fev1FvcRatioPreBronchodilator",
    section_02_d041         : "Fev1PostBronchodilator",
    section_02_d042         : "Fev1PercentPostBronchodilator",
    section_02_d043         : "Fev1FvcRatioPostBronchodilator",
    section_02_d044         : "Spirometry17003Or17004Date",
    section_02_d045         : "Fev1PercentEstimated",
    section_02_d046         : "Fev1FvcRatioEstimated",
    section_02_d047         : "Fev1",
    section_02_d048         : "CatAssessmentDate",
    section_02_d049         : "CatScore",
    section_02_d050         : "MmrcAssessmentDate",
    section_02_d051         : "MmrcScore",
    section_02_d052         : "AcuteExacerbationFrequencyPastYear",
    section_02_d053         : "GoldStage",

    // --- §6-1-H 實驗室 ---
    section_02_d054         : "LabTestDate",
    section_02_d055         : "WBC",
    section_02_d056         : "RBC",
    section_02_d057         : "Hemoglobin",
    section_02_d058         : "Hematocrit",
    section_02_d059         : "PlateletCount",
    section_02_d060         : "MCV",
    section_02_d061         : "MCH",
    section_02_d062         : "MCHC",
    section_02_d063         : "WBCSegPercent",
    section_02_d064         : "WBCEosPercent",
    section_02_d065         : "WBCBasoPercent",
    section_02_d066         : "WBCMonoPercent",
    section_02_d067         : "WBCLymPercent",
    section_02_d068         : "EosinophilCount",
    section_02_d069         : "ImmunoglobulinE",
    section_02_d070         : "ImmunoglobulinEDate",
    section_02_d071         : "BloodGlucose",
    section_02_d072         : "BloodGlucoseDate",
    section_02_d073         : "HbA1c",
    section_02_d074         : "HbA1cDate",

    // --- §6-1-I 影像 ---
    section_02_d076         : "ChestXrayDate",
    section_02_d078         : "BronchialProvocationTestDate",
    section_02_d079         : "ComputedTomographyDate",

    // --- §6-1-J 肺復原評估 ---
    section_02_d080         : "PulmonaryRehabAssessment",
    section_02_d081         : "PulmonaryRehabAssessmentDate",
    section_02_d082         : "RespIssueSputumClearance",
    section_02_d083         : "RespIssueHypoxemia",
    section_02_d084         : "RespIssueHypercapnia",
    section_02_d085         : "RespIssueLowLungVolume",
    section_02_d086         : "RespIssueDyspneaOnActivity",
    section_02_d087         : "RespIssueLowMuscleStrength",
    section_02_d088         : "RespIssueSleepDisorder",
    section_02_d089         : "RespIssueAbnormalBreathingPattern",
    section_02_d090         : "RespIssueChestDeformity",
    section_02_d091         : "RespIssueOther",
    section_02_d092         : "RespIssueOtherDescription",

    // --- §6-1-K 肺復原計畫 ---
    section_02_d093         : "CpAirwayClearance",
    section_02_d094         : "CpHumidificationNebulization",
    section_02_d095         : "CpOxygenAtRest",
    section_02_d096         : "CpOxygenWithActivity",
    section_02_d097         : "CpLungExpansion",
    section_02_d098         : "CpBreathingTraining",
    section_02_d099         : "CpEnergyConservationGuidance",
    section_02_d100         : "CpWalkingExercise",
    section_02_d101         : "CpResistanceCycling",
    section_02_d102         : "CpUpperLimbExercise",
    section_02_d103         : "CpLowerLimbExercise",
    section_02_d104         : "CpRespiratoryMuscleTraining",
    section_02_d105         : "CpOther",
    section_02_d106         : "CpOtherDescription",

    // --- §6-1-L 排除/病情變化/結案 ---
    section_02_d107         : "IncludedInRewardIndicator",
    section_02_d108         : "ExclusionReason",
    section_02_d109         : "Type1StableCondition",
    section_02_d110         : "StableHandlingMethod",
    section_02_d111         : "DownReferralOrganizationCode",
    section_02_d112         : "DownReferralDate",
    section_02_d113         : "Type2AcuteExacerbation",
    section_02_d114         : "ExacerbationHandlingMethod",
    section_02_d115         : "UpReferralOrganizationCode",
    section_02_d116         : "UpReferralDate",
    section_02_d117         : "Wheezing",
    section_02_d118         : "TreatmentChangeMedicationItem",
    section_02_d119         : "TreatmentChangeMedicationDose",
    section_02_close_date   : "CloseDate",
    section_02_close_rsn    : "CloseReason",
    section_02_close_oth    : "CloseReasonOther"
  }
