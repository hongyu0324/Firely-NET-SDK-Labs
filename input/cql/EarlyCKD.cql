/*
 * Library : Early_CKD
 * Title   : 初期慢性腎臟病（Early CKD）醫療給付改善方案 CQL
 * Version : 0.2.1
 * Date    : 2026-05-24
 *
 * 撈取邏輯（依 CPG-15 v2，2026-05-23 加修正 #1.22/1.23/1.24）:
 *   - 主資源: Encounter
 *     + identifier 含 P 碼 ∈ {P4301C, P4302C, P4303C, P7001C, P7002C, P7003C}
 *       system: http://nhi.gov.tw/fhir/CodeSystem/nhi-order-code（TWCore 已收）
 *     + identifier 含 特定治療項目代號 ∈ {EB, EK}
 *       system: http://nhi.gov.tw/fhir/CodeSystem/nhi-specific-treatment-code [待替換]
 *       （TWCore 尚未收，原 CPG 寫 Encounter.type.coding.code 為誤）
 *     + class.code = 'AMB'（門診，TWCore v3-ActEncounterCode 標準）
 *     + status = 'finished'
 *     + 主診斷 ICD-10-CM 前三碼 ∈ {N18.1, N18.2, N18.3}
 *
 *   - LookbackDays: 30 天（測試 workaround）；上線前回 CPG 規範
 *     「每月 1-20 申報上月份」（Interval[Date(year, month-1, 1), lastDay]）
 *
 * 關聯資源:
 *   - Patient / Practitioner / Condition / Observation / EpisodeOfCare /
 *     ServiceRequest / Location / Organization / QuestionnaireResponse
 *
 * 命名規則（依 CPG_Production_Guide Part 2 §6-3）:
 *   - 跨 CPG 標準: OrganizationCode、ReferralTargetOrganizationCode、
 *                  PatientIdNumber、PatientName、BirthDate、GenderCode、
 *                  HomePhone、Address、PractitionerIdNumber、EncounterDate
 *   - 表 B/C: BodyHeight、BodyWeight、SystolicBP、DiastolicBP、
 *             EGFR、UPCR、UACR、HbA1c、LDL、SerumCreatinine
 *   - 共病 exists 判斷: HasDiabetes、HasHypertension、HasKidneyDisease 等
 *
 * 業務邏輯（CPG v2 §3-2）:
 *   - §3-2-A 資料段分流（A/B/C/D/E）— 各段必填欄位不同
 *   - §3-2-B DM 共病聯動 → P7001C 系列取代 P4302C 系列
 *   - §3-2-C UPCR/UACR 擇一必填：非 DM 任一即可、DM UACR 必填
 *   - §3-2-D eGFR 範圍檢核：< 1000；新收案 ≤ 500（6 歲以下 ≤ 999）
 *   - §3-2-E 申報間隔：P4302C 3 月、P7001C 7 週、P7002C 10 週 等（v0.2.0 未實作歷史比對）
 *   - §3-2-F 結案聯動：結案原因=5 → 轉診院所/原因必填；=7 → 其他說明必填
 *   - §3-2-G 伴隨疾病互斥：序 14（無）=Y → 15-22 全為 N
 *
 * 修正歷程:
 *   - v0.1.0: 初版 (v1 CPG-15，命名 EarlyCKDCareProgram)
 *   - v0.1.1: HbA1c/UPCR/UACR LOINC 晉升 TWCore v1.3.0
 *   - v0.2.0: 依 CPG-15 v2 + v2.1 重產
 *             (1) linkId 100% 對齊甲方 Questionnaire JSON（含中文 linkId）
 *             (2) define 命名統一（OrganizationCode 等跨 CPG 標準）
 *             (3) Encounter 篩選: P 碼+EB/EK 雙 identifier、class=AMB、status=finished
 *             (4) EB/EK FHIR Path 修正: type → identifier with 不同 system
 *             (5) 收縮/舒張壓 LOINC 8480-6/8462-4 inline（TWCore 無單獨 define）
 *             (6) 共病改用 ICD-10 前綴 exists 判斷（v0.1.x 是 QR 旗標）
 *             (7) 聯動規則 4 大類用「條件不成立輸出 null」實作
 *   - v0.2.1: Encounter.identifier 兩個 system 統一為 v1.4 §九-1 暫定 URI
 *             (1) P 碼 system: 'http://nhi.gov.tw/fhir/CodeSystem/nhi-order-code'
 *                 → 'https://nhi.gov.tw/fhir/identifier/case-mgmt-code'
 *                 依 CPG-15 §2-0 + Naming_Convention v1.4 §九-1
 *                 + CQL_Guidelines v1.5.1 規則 12 暫定 URI 對照表
 *             (2) EB/EK system: 'http://nhi.gov.tw/fhir/CodeSystem/nhi-specific-treatment-code'
 *                 → 'https://nhi.gov.tw/fhir/identifier/nhi-specific-treatment-code'
 *                 依 Naming_Convention v1.4 §九-1 新增第 5 條暫定 URI
 *             (3) codesystem 宣告同步改名: NhiOrder→CaseMgmtCode
 *             (4) 4 個測試 Encounter JSON 的兩個 identifier.system 同步替換
 *
 * [待替換] URL:
 *   - https://nhi.gov.tw/fhir/identifier/case-mgmt-code（P 碼 system，v1.4 §九-1 暫定）
 *   - https://nhi.gov.tw/fhir/identifier/nhi-specific-treatment-code（EB/EK system，v1.4 §九-1 暫定）
 *     兩者待 NHI 正式發布 CodeSystem 後一次性 rename（全專案搜尋 nhi.gov.tw/fhir/identifier/）
 *
 * [待補] FHIR Path 不明確項目:
 *   - BusinessGroupCode（業務組別 1-6，CPG §6-1-A 標待補）
 *
 * [待確認] 業務面待確認項目:
 *   - VisitStage（診療階段 0/1）FHIR Path（暫從 QR 讀）
 *   - CKDStageCode（00/10/20/3a/3b/40/50）FHIR Path（暫用 Condition.stage.summary）
 *   - CloseReasonCode（1-7）FHIR Path（暫用 EpisodeOfCare.statusHistory）
 *   - ReferralReasonCode（10/3b/40/50）FHIR Path（暫用 ServiceRequest.reasonCode）
 *   - 申報間隔 §3-2-E 五條規則需排序歷年 Encounter 計算（v0.2.0 未實作）
 *
 * (Re-save to trigger IDE re-analysis 2026-05-24)
 */

library EarlyCKD version '0.2.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers
include TWCoreCodeSystemsNHI version '1.3.0' called CS

// ===============================================================
// Code Systems
// ===============================================================
codesystem "LOINC":    'http://loinc.org'
codesystem "TWNID":    'http://hl7.org/fhir/sid/tw-nid'

// v1.4 §九-1 暫定 URI（v0.2.1 採用，全專案統一）
// 個案管理 P 碼（CPG-15/16/17/18/19/20/21/22）— Early CKD 用 P4301C-P4303C + P7001C-P7003C
codesystem "CaseMgmtCode": 'https://nhi.gov.tw/fhir/identifier/case-mgmt-code'

// [待替換] 以下 6 個 system URL 為佔位，正式上線前須換為 NHI/MOHW/TWCore 公告版本
// NHI 申報格式特定治療項目代號（一）EB/EK（CPG-15 / 22，v1.4 §九-1 暫定）
codesystem "NhiSpecificTreatment": 'https://nhi.gov.tw/fhir/identifier/nhi-specific-treatment-code'
// CKD 階段（00/10/20/3a/3b/40/50）
codesystem "CkdStage":             'http://nhi.gov.tw/fhir/CodeSystem/ckd-stage-tw'
// Early CKD 結案原因（1-7）
codesystem "EarlyCkdCloseReason":  'http://nhi.gov.tw/fhir/CodeSystem/early-ckd-close-reason-tw'
// Early CKD 轉診原因（10/3b/40/50）
codesystem "EarlyCkdReferralReason": 'http://nhi.gov.tw/fhir/CodeSystem/early-ckd-referral-reason-tw'
// 診療階段（0 初診 / 1 複診）
codesystem "VisitStageTw":         'http://nhi.gov.tw/fhir/CodeSystem/visit-stage-tw'
// 業務組別（1-6 健保署分區）
codesystem "BusinessGroupTw":      'http://nhi.gov.tw/fhir/CodeSystem/business-group-tw'

// ===============================================================
// Parameters
// ===============================================================
parameter "MeasurementPeriod" Interval<DateTime>
  default Interval[
    @2026-01-01T00:00:00.000,
    @2026-12-31T23:59:59.999
  ]

// CPG-15 v2 §1-3: 每月 1-20 申報上月份；上線前須回 [上月1日, 上月末日]
// 30 days 為測試 workaround
parameter "LookbackDays" Integer default 30

// ===============================================================
// Context
// ===============================================================
context Patient

// ===============================================================
// 代碼集合
// ===============================================================

// CPG-15 §2-1-A Early CKD 專屬 P 碼
define "EarlyCKD_PCodes":
  { 'P4301C', 'P4302C', 'P4303C' }

// CPG-15 §2-1-B DM 合併 P 碼（與 CPG-17 共用）
define "DMCKD_PCodes":
  { 'P7001C', 'P7002C', 'P7003C' }

// 全部觸發 P 碼
define "All_Trigger_PCodes":
  "EarlyCKD_PCodes" union "DMCKD_PCodes"

// CPG-15 §2-2 特定治療項目代號（一）
define "SpecificTreatmentCodes":
  { 'EB', 'EK' }

// CPG-15 §2-3 CKD 主診斷 ICD-10-CM 前三碼
define "CKD_DiagnosisPrefixes":
  { 'N18.1', 'N18.2', 'N18.3' }

// [待確認] 以下 3 個 LOINC 集合原應走 TWCore CS."HbA1c/UPCR/UACR ... LOINC Codes"
// 但 IDE/CQL 解析器對 TWCore 中文 + Codes 後綴的 list identifier 解析失敗
// 暫 inline 宣告；TWCore 端解析問題排除後可切回 `Co.code.value in CS."..."`
// 影響評估：值完全相同，僅 include 引用方式差異
define "HbA1c_LOINC_Codes": { '4548-4' }
define "UPCR_LOINC_Codes":  { '2888-6' }
define "UACR_LOINC_Codes":  { '9318-7' }

// 伴隨疾病 ICD-10 前綴（CPG §6-1-B exists 判斷用）
define "Diabetes_ICDPrefixes":
  { 'E08', 'E09', 'E10', 'E11', 'E13' }
define "Hypertension_ICDPrefixes":
  { 'I10', 'I11', 'I12', 'I13', 'I15' }
define "Cardiovascular_ICDPrefixes":
  { 'I20', 'I21', 'I22', 'I23', 'I24', 'I25' }
define "Hyperlipidemia_ICDPrefixes":
  { 'E78' }
define "ChronicLiver_ICDPrefixes":
  { 'K70', 'K71', 'K72', 'K73', 'K74', 'K75', 'K76', 'K77' }
define "Cancer_ICDPrefixes":
  { 'C00', 'C01', 'C02', 'C03', 'C04', 'C05', 'C06', 'C07', 'C08', 'C09',
    'C10', 'C11', 'C12', 'C13', 'C14', 'C15', 'C16', 'C17', 'C18', 'C19',
    'C20', 'C21', 'C22', 'C23', 'C24', 'C25', 'C26',
    'D00', 'D01', 'D02', 'D03', 'D04', 'D05', 'D06', 'D07', 'D08', 'D09' }

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

// QR 取單一答案（valueString 或 valueCoding.code 雙路徑，含一層巢狀）
define function GetQRAnswer(QR FHIR.QuestionnaireResponse, lid String) returns String:
  Coalesce(
    First(
      QR.item I
        where I.linkId.value = lid
        return Coalesce(
          First(I.answer A return (A.value as FHIR.string).value),
          First(I.answer A return ((A.value as FHIR.Coding).code).value)
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
              First(Sub.answer A return ((A.value as FHIR.Coding).code).value)
            )
        )
    )
  )

// Condition 主類別前綴比對（取前 3-5 碼）
define function ConditionMatchesPrefix(C FHIR.Condition, prefixes List<String>) returns Boolean:
  exists (
    C.code.coding Co
      where Substring(Co.code.value, 0, 3) in prefixes
         or Substring(Co.code.value, 0, 5) in prefixes
  )

// ===============================================================
// Encounter 篩選（CPG-15 v2 §3-1 + v2.1 補正）
// ===============================================================
define "RelevantEncountersSorted":
  [Encounter] E
    where E.subject.reference.value = 'Patient/' + Patient.id
      and EncPeriodStartDT(E) between (Now() - 30 days) and Now()
      and E.class.code.value = 'AMB'
      and E.status.value = 'finished'
      and exists (
        E.identifier I
          where I.system.value = 'https://nhi.gov.tw/fhir/identifier/case-mgmt-code'
            and I.value.value in "All_Trigger_PCodes"
      )
      and exists (
        E.identifier I
          where I.system.value = 'https://nhi.gov.tw/fhir/identifier/nhi-specific-treatment-code'
            and I.value.value in "SpecificTreatmentCodes"
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
// Condition / Observation / QR / Practitioner / EpisodeOfCare / ServiceRequest
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

define "PatientEpisodes":
  [EpisodeOfCare] EOC
    where EOC.patient.reference.value = 'Patient/' + Patient.id

define "LatestEpisode":
  First(
    "PatientEpisodes" EOC
      return Tuple { sortKey: EOC.period."start".value, item: EOC }
      sort by sortKey desc
  ).item

define "PatientServiceRequests":
  [ServiceRequest] SR
    where SR.subject.reference.value = 'Patient/' + Patient.id

define "LatestServiceRequest":
  First(
    "PatientServiceRequests" SR
      return Tuple { sortKey: SR.authoredOn.value, item: SR }
      sort by sortKey desc
  ).item

// ===============================================================
// §6-1-A 基本資料段（序 1-9）
// ===============================================================

// 輸出欄位: 資料段（linkId: segment）A/B/C/D/E
define "DataSegment":
  GetQRAnswer("LatestQuestionnaireResponse", 'segment')

// 輸出欄位: 業務組別（linkId: business_group）1-6
// [待補] FHIR Path 不明確，暫用 QR
// [待替換] 若改 Observation 路徑，system 用 BusinessGroupTw 佔位 URL
define "BusinessGroupCode":
  GetQRAnswer("LatestQuestionnaireResponse", 'business_group')

// 輸出欄位: 醫事機構代碼（linkId: facility_3）依 Guide §6-3-1
define "OrganizationCode":
  First(
    "EncounterOrganizations" O
      return First(
        O.identifier I
          where I.value is not null
          return I.value.value
      )
  )

// 輸出欄位: 身分證號（linkId: national_id_2）依 Guide §6-3-2
define "PatientIdNumber":
  First(
    Patient.identifier I
      where I.system.value = 'http://hl7.org/fhir/sid/tw-nid'
         or exists (I.type.coding Co where Co.code.value = 'NI')
      return I.value.value
  )

// 輸出欄位: 出生日期（linkId: birth_date_2）
define "BirthDate":
  Patient.birthDate.value

// 輸出欄位: 姓名（linkId: name_4）
define "PatientName":
  First(Patient.name N return N.text.value)

// 輸出欄位: 性別（linkId: sex_2）健保署 1=男 / 2=女
define "GenderCode":
  case Patient.gender.value
    when 'male'   then '1'
    when 'female' then '2'
    else null
  end

// 輸出欄位: 聯絡地址（linkId: address）
define "Address":
  First(Patient.address A return A.text.value)

// 輸出欄位: 電話（linkId: phone_4）
define "HomePhone":
  First(
    Patient.telecom T
      where T.system.value = 'phone'
      return T.value.value
  )

// ===============================================================
// §6-1-B 收案/追蹤段（序 10-35）
// ===============================================================

// 輸出欄位: 醫事人員身分證號（linkId: practitioner_national_id）
define "PractitionerIdNumber":
  First(
    "EncounterPractitioners" P
      return First(
        P.identifier I
          where I.system.value = 'http://hl7.org/fhir/sid/tw-nid'
             or exists (I.type.coding Co where Co.code.value in { 'NI', 'MD' })
          return I.value.value
      )
  )

// 輸出欄位: 診療階段（linkId: 診療階段）0 初診 / 1 複診
// [待確認] CPG §6-1-B 標 Encounter.type 或 Encounter.class；暫從 QR 讀
// [待替換] 若改 Encounter.extension 路徑，url 用 VisitStageTw 佔位
define "VisitStage":
  GetQRAnswer("LatestQuestionnaireResponse", '診療階段')

// 輸出欄位: 收案（就醫）日期（linkId: encounter_date）
define "EncounterDate":
  "LatestEncounter".period."start".value

// 輸出欄位: CKD 階段（linkId: 階段）00/10/20/3a/3b/40/50
// [待確認] CPG §6-1-B 標 Condition.stage.summary
// [待替換] system: http://nhi.gov.tw/fhir/CodeSystem/ckd-stage-tw（CkdStage 佔位 URL）
define "CKDStageCode":
  Coalesce(
    First(
      "EncounterConditions" C
        where ConditionMatchesPrefix(C, "CKD_DiagnosisPrefixes")
        return First(
          C.stage S
            return First(
              S.summary.coding Co
                where Co.system.value = 'http://nhi.gov.tw/fhir/CodeSystem/ckd-stage-tw'
                return Co.code.value
            )
        )
    ),
    GetQRAnswer("LatestQuestionnaireResponse", '階段')
  )

// 輸出欄位: 伴隨疾病_無（linkId: comorbidity）Y/N 旗標
define "ComorbidityNone":
  GetQRAnswer("LatestQuestionnaireResponse", 'comorbidity')

// 共病 exists 判斷（CPG §6-1-B 直接用 Condition.code 存在判斷）
define "HasKidneyDisease":
  if exists (
    "PatientConditions" C
      where ConditionMatchesPrefix(C, "CKD_DiagnosisPrefixes")
  ) then 'Y' else 'N'

define "HasDiabetes":
  if exists (
    "PatientConditions" C
      where ConditionMatchesPrefix(C, "Diabetes_ICDPrefixes")
  ) then 'Y' else 'N'

define "HasHypertension":
  if exists (
    "PatientConditions" C
      where ConditionMatchesPrefix(C, "Hypertension_ICDPrefixes")
  ) then 'Y' else 'N'

define "HasCardiovascularDisease":
  if exists (
    "PatientConditions" C
      where ConditionMatchesPrefix(C, "Cardiovascular_ICDPrefixes")
  ) then 'Y' else 'N'

define "HasHyperlipidemia":
  if exists (
    "PatientConditions" C
      where ConditionMatchesPrefix(C, "Hyperlipidemia_ICDPrefixes")
  ) then 'Y' else 'N'

define "HasChronicLiverDisease":
  if exists (
    "PatientConditions" C
      where ConditionMatchesPrefix(C, "ChronicLiver_ICDPrefixes")
  ) then 'Y' else 'N'

define "HasCancer":
  if exists (
    "PatientConditions" C
      where ConditionMatchesPrefix(C, "Cancer_ICDPrefixes")
  ) then 'Y' else 'N'

// 輸出欄位: 伴隨疾病_其他（linkId: comorbidity_other）Y/N
define "HasOtherComorbidity":
  GetQRAnswer("LatestQuestionnaireResponse", 'comorbidity_other')

// 輸出欄位: 伴隨疾病_其他說明（linkId: comorbidity_other_2）
// 聯動: comorbidity_other = Y 時填寫
define "OtherComorbidityDescription":
  if Coalesce("HasOtherComorbidity", '') = 'Y'
    then GetQRAnswer("LatestQuestionnaireResponse", 'comorbidity_other_2')
  else null

// 輸出欄位: 抽菸（linkId: 抽菸）1 無 / 2 有
define "SmokingStatus":
  Coalesce(
    First(
      "EncounterObservations" O
        where HasLoincCode(O, CS."吸菸狀態 LOINC")
        return ObsValueCodeOrString(O)
    ),
    GetQRAnswer("LatestQuestionnaireResponse", '抽菸')
  )

// 輸出欄位: 檢查日期（linkId: date_4）
define "LabExamDate":
  First(
    "EncounterObservations" O
      where HasLoincIn(O, { CS."身高 LOINC", CS."體重 LOINC", CS."腎絲球過濾率 LOINC" })
      return ObsEffectiveDT(O)
  )

// 輸出欄位: 身高（linkId: 身高）LOINC 8302-2 from TWCore
define "BodyHeight":
  First(
    "EncounterObservations" O
      where HasLoincCode(O, CS."身高 LOINC")
      return ObsValueQuantity(O)
  )

// 輸出欄位: 體重（linkId: 體重）LOINC 29463-7 from TWCore
define "BodyWeight":
  First(
    "EncounterObservations" O
      where HasLoincCode(O, CS."體重 LOINC")
      return ObsValueQuantity(O)
  )

// 輸出欄位: 收縮壓（linkId: mmhg）LOINC 8480-6 inline
// TWCore 只有 panel "血壓 LOINC" 85354-9，無單獨收縮 define
define "SystolicBP":
  First(
    "EncounterObservations" O
      where HasLoincCode(O, '8480-6')
      return ObsValueQuantity(O)
  )

// 輸出欄位: 舒張壓（linkId: mmhg_2）LOINC 8462-4 inline
define "DiastolicBP":
  First(
    "EncounterObservations" O
      where HasLoincCode(O, '8462-4')
      return ObsValueQuantity(O)
  )

// 輸出欄位: eGFR（linkId: 腎絲球濾過率值）LOINC 33914-3 from TWCore
define "EGFR":
  First(
    "EncounterObservations" O
      where HasLoincCode(O, CS."腎絲球過濾率 LOINC")
      return ObsValueQuantity(O)
  )

// 輸出欄位: UPCR（linkId: 尿蛋白及尿液肌酸酐比值）LOINC 2888-6
// [待確認] inline 暫代 TWCore CS."UPCR 尿蛋白肌酸酐比 LOINC Codes"（解析問題）
define "UPCR":
  First(
    "EncounterObservations" O
      where exists (
        O.code.coding C
          where C.system.value = 'http://loinc.org'
            and C.code.value in "UPCR_LOINC_Codes"
      )
      return ObsValueQuantity(O)
  )

// 輸出欄位: 血清肌酸酐（linkId: 血清肌酸酐）LOINC 2160-0 from TWCore
define "SerumCreatinine":
  First(
    "EncounterObservations" O
      where HasLoincCode(O, CS."肌酸酐 血清 主要 LOINC")
      return ObsValueQuantity(O)
  )

// 輸出欄位: LDL（linkId: 低密度脂蛋白）LOINC 2089-1 from TWCore
define "LDL":
  First(
    "EncounterObservations" O
      where HasLoincCode(O, CS."LDL膽固醇 LOINC")
      return ObsValueQuantity(O)
  )

// 輸出欄位: HbA1c（linkId: 糖化血色素）LOINC 4548-4
// 聯動: DM 共病 Y 時必填（CPG §3-2-B）
// [待確認] inline 暫代 TWCore CS."HbA1c 糖化血色素 LOINC Codes"（解析問題）
define "HbA1c":
  First(
    "EncounterObservations" O
      where exists (
        O.code.coding C
          where C.system.value = 'http://loinc.org'
            and C.code.value in "HbA1c_LOINC_Codes"
      )
      return ObsValueQuantity(O)
  )

// 輸出欄位: UACR（linkId: 尿白蛋白...）LOINC 9318-7
// 聯動: DM 共病 Y 時必填；非 DM 與 UPCR 擇一（CPG §3-2-C）
// [待確認] inline 暫代 TWCore CS."UACR 尿白蛋白肌酸酐比 LOINC Codes"（解析問題）
define "UACR":
  First(
    "EncounterObservations" O
      where exists (
        O.code.coding C
          where C.system.value = 'http://loinc.org'
            and C.code.value in "UACR_LOINC_Codes"
      )
      return ObsValueQuantity(O)
  )

// ===============================================================
// §6-1-C 結案段（序 36-40）
// ===============================================================

// 輸出欄位: 結案日期（linkId: close_date）
define "EpisodeEndDate":
  "LatestEpisode".period."end".value

// 輸出欄位: 結案原因（linkId: close_reason）1-7
// [待確認] CPG §6-1-C 標 EpisodeOfCare.statusHistory.status 或自訂 extension
// [待替換] system: http://nhi.gov.tw/fhir/CodeSystem/early-ckd-close-reason-tw（EarlyCkdCloseReason 佔位）
// 註：statusHistory.status 不適合存業務原因 1-7，建議改自訂 extension（待業務確認）
define "CloseReasonCode":
  Coalesce(
    First(
      "LatestEpisode".statusHistory SH
        return SH.status.value
    ),
    GetQRAnswer("LatestQuestionnaireResponse", 'close_reason')
  )

// 輸出欄位: 結案原因_其他（linkId: close_reason_other）
// 聯動: close_reason=7 時必填
// 註：EpisodeOfCare 標準無 note 元素，僅從 QR 讀
define "CloseReasonOther":
  if Coalesce("CloseReasonCode", '') = '7'
    then GetQRAnswer("LatestQuestionnaireResponse", 'close_reason_other')
  else null

// 輔助: 轉診目的機構（依 ServiceRequest.performer chain 到 Organization）
define "ReferralTargetOrganizations":
  [Organization] O
    where exists (
      "LatestServiceRequest".performer P
        where EndsWith(P.reference.value, O.id)
    )

// 輸出欄位: 轉診院所代號（linkId: facility_4）
// 聯動: close_reason=5 時必填
define "ReferralTargetOrganizationCode":
  if Coalesce("CloseReasonCode", '') = '5'
    then First(
      "ReferralTargetOrganizations" O
        return First(
          O.identifier I
            where I.value is not null
            return I.value.value
        )
    )
  else null

// 輸出欄位: 轉診原因（linkId: reason）10/3b/40/50
// 聯動: close_reason=5 時必填
// [待確認] CPG §6-1-C 標 ServiceRequest.reasonCode
// [待替換] system: http://nhi.gov.tw/fhir/CodeSystem/early-ckd-referral-reason-tw（EarlyCkdReferralReason 佔位）
define "ReferralReasonCode":
  if Coalesce("CloseReasonCode", '') = '5'
    then First(
      "LatestServiceRequest".reasonCode R
        return First(
          R.coding C
            where C.system.value = 'http://nhi.gov.tw/fhir/CodeSystem/early-ckd-referral-reason-tw'
            return C.code.value
        )
    )
  else null

// ===============================================================
// 衍生布林（資料段判斷，供 SDC 端使用）
// ===============================================================
define "IsSegmentA": Coalesce("DataSegment" = 'A', false)
define "IsSegmentB": Coalesce("DataSegment" = 'B', false)
define "IsSegmentC": Coalesce("DataSegment" = 'C', false)
define "IsSegmentD": Coalesce("DataSegment" = 'D', false)
define "IsSegmentE": Coalesce("DataSegment" = 'E', false)

// DM 共病旗標（CPG §3-2-B）— 影響 P 碼選擇與 HbA1c/UACR 必填
define "IsDMComorbid": "HasDiabetes" = 'Y'

// 是否新收案（VisitStage=0 初診）— eGFR 上限影響
define "IsNewlyAdmitted": Coalesce("VisitStage" = '0', false)

// ===============================================================
// Summary Tuple（SDC populate 使用）
// key = Questionnaire item.linkId（甲方原樣，不變）
// value = CQL define 名稱
// ===============================================================
define "Summary":
  Tuple {
    // --- §6-1-A 基本資料段 ---
    segment              : "DataSegment",
    business_group       : "BusinessGroupCode",
    facility_3           : "OrganizationCode",
    national_id_2        : "PatientIdNumber",
    birth_date_2         : "BirthDate",
    name_4               : "PatientName",
    sex_2                : "GenderCode",
    address              : "Address",
    phone_4              : "HomePhone",

    // --- §6-1-B 收案/追蹤段 ---
    practitioner_national_id : "PractitionerIdNumber",
    "診療階段"           : "VisitStage",
    encounter_date       : "EncounterDate",
    "階段"               : "CKDStageCode",
    comorbidity          : "ComorbidityNone",
    comorbidity_2        : "HasKidneyDisease",
    comorbidity_3        : "HasDiabetes",
    comorbidity_4        : "HasHypertension",
    comorbidity_5        : "HasCardiovascularDisease",
    comorbidity_6        : "HasHyperlipidemia",
    comorbidity_7        : "HasChronicLiverDisease",
    comorbidity_8        : "HasCancer",
    comorbidity_other    : "HasOtherComorbidity",
    comorbidity_other_2  : "OtherComorbidityDescription",
    "抽菸"               : "SmokingStatus",
    date_4               : "LabExamDate",
    "身高"               : "BodyHeight",
    "體重"               : "BodyWeight",
    mmhg                 : "SystolicBP",
    mmhg_2               : "DiastolicBP",
    "腎絲球濾過率值"     : "EGFR",
    "尿蛋白及尿液肌酸酐比值" : "UPCR",
    "血清肌酸酐"         : "SerumCreatinine",
    "低密度脂蛋白"       : "LDL",
    "糖化血色素"         : "HbA1c",
    "尿白蛋白及尿液肌酸酐比值_微量白蛋白_尿液中白蛋白_肌酸酐比值" : "UACR",

    // --- §6-1-C 結案段 ---
    close_date           : "EpisodeEndDate",
    close_reason         : "CloseReasonCode",
    close_reason_other   : "CloseReasonOther",
    facility_4           : "ReferralTargetOrganizationCode",
    reason               : "ReferralReasonCode"
  }
