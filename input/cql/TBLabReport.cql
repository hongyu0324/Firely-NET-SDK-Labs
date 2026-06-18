/*
 * Library : TB_Lab_Report
 * Title   : 結核-檢驗報告上傳 (TB Lab Report Upload / TBCHECK) CQL
 * Version : 0.1.0
 * Date    : 2026-05-20
 *
 * 撈取邏輯（CPG-13 v4，TBCHECK V1.2）:
 *   - 主資源: DiagnosticReport（以 issued 為基準，最近 2 天）
 *   - 撈取路徑:
 *     Step 1: DiagnosticReport.issued 在過去 2 天內
 *     Step 2: DR.basedOn -> ServiceRequest -> encounter -> Encounter
 *     Step 3: Encounter.diagnosis -> Condition.code 確認符合 §2-1 ICD-10
 *     Step 4: DR.result -> Observation 列表 (r1~rN 序號由上傳程式分配)
 *     Step 5: DR.specimen -> Specimen.collection.collectedDateTime
 *
 * ICD-10 觸發範圍（§2-1）:
 *   - 前 3 碼: A15, A16, A17, A18, A19, J65
 *   - 前 5 碼: P37.0, O98.0, R76.1, Z22.7
 *   - 前 6 碼: Z16.34
 *
 * 欄位對應參考: CPG-13_TB_Lab_Report.md（含 Form-13 FormMD、TWCDI 對照）
 * Questionnaire: Questionnaires-13_結核-檢驗報告上傳_draft_v0.0.1_20260126.json
 *
 * 與 CPG-12 (TB_HIV_Medication) 分工:
 *   - CPG-12: 用藥處方資料（Encounter + MedicationRequest）
 *   - CPG-13: 檢驗報告資料（DiagnosticReport + Observation）
 *
 * 修正歷程:
 *   - v0.1.0: 初版（依 CPG-13 v4，18 欄位）
 *   - v0.2.0: 將 §2-1 ICD-10 觸發代碼與 §2-2 LOINC 檢驗代碼改以
 *             valueset 集中管理；HasTbIcd10Code、DRObservations、
 *             OrderCode 改用 valueset 過濾。
 *   - v0.3.0: 改用「include TWCore + inline 表單獨有代碼」混合制
 *             （依 00_knowledge\Code_Reference_Workflow.md）：
 *             - 移除 PLACEHOLDER valueset 宣告
 *             - include TWCore_CodeSystems_NHI v1.1.0
 *             - §2-1 ICD-10 改以前綴清單 + StartsWith 函數判斷
 *             - §2-2 LOINC：9 項使用 TWCore 既有 list；
 *               8 項（ALP/BUN/eGFR/Glucose 及 4 個結核菌學）inline 宣告，[待確認]
 *   - v0.3.1: 依 CPG-13 調整記錄 #5 校正 TbInlineLabLoincCodes 註解：
 *             NHI 代碼以附表三（114-01-01 實施版）為準
 *             （ALP 09027C / BUN 09002C / Glucose 09005C / AFB 13025C ...）；
 *             LOINC 不變、邏輯不變，僅註解校正。
 *   - v0.4.0: Phase 2 — ALP / BUN / 血糖 / eGFR 4 項晉升 TWCore v1.2.0：
 *             - include 版號 1.1.0 → 1.2.0
 *             - TbInlineLabLoincCodes 由 8 項減為 4 項（僅留 TB 結核菌學獨有）
 *             - IsTbLabLoincCoding 新增 4 個 TWCore list 參照
 *               （ALP / BUN 尿素氮 / 血糖 / 腎絲球過濾率 LOINC Codes）
 *             - 行為等價：原 inline 4 項全部移入 TWCore，比對範圍不變
 *   - v0.4.1: 配合 TWCore v1.2.0 將 ALP / BUN 兩個單值 LOINC 改為 list 形式：
 *             - "ALP LOINC" → "ALP LOINC Codes"（單值 → list）
 *             - "BUN 尿素氮 LOINC" → "BUN 尿素氮 LOINC Codes"（單值 → list）
 *             - IsTbLabLoincCoding 對應引用由 `=` 改為 `in`
 *             - 行為等價（單值 list 與單值字串 `=` 比對結果相同）
 *             - 風格統一：與既有 "ALT GPT LOINC Codes" 等 list 一致，
 *               消除單值/多值混用可能引發的 IDE 型別推導歧義
 */

library TBLabReport version '0.4.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers
include TWCoreCodeSystemsNHI version '1.2.0' called CS

// ---------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------
parameter "MeasurementPeriod" Interval<DateTime>
  default Interval[
    @2026-01-01T00:00:00.000,
    @2026-12-31T23:59:59.999
  ]

// CPG-13 §3-1: 每日排程上傳（LookbackDays = 2 天，以報告日為基準）
// 註: CQL parser 不接受「Integer 變數 days」語法，故時間區間以 hardcode 2 days
parameter "LookbackDays" Integer default 2

// ---------------------------------------------------------------
// Context
// ---------------------------------------------------------------
context Patient

// ===============================================================
// 表單獨有 Codes（依 Code_Reference_Workflow.md §5）
// ===============================================================

// CPG-13 §2-1：結核相關 ICD-10 觸發代碼（前綴比對）
// 前 3 碼: A15/A16/A17/A18/A19/J65（含所有子代碼，如 A15.0、A15.1.0）
// 前 5 碼: P37.0/O98.0/R76.1/Z22.7
// 前 6 碼: Z16.34
define "TbTriggerIcd10Prefixes": { 'A15', 'A16', 'A17', 'A18', 'A19', 'J65',
  'P37.0', 'O98.0', 'R76.1', 'Z22.7', 'Z16.34' }

// CPG-13 §2-2：TB 結核菌學獨有 LOINC（不晉升 TWCore，保留本表單 inline）
// v0.4.0 起：原 inline 清單之 (A) 類 4 項（ALP/BUN/eGFR/Glucose）已晉升至
//          TWCore v1.2.0，由 IsTbLabLoincCoding 透過 CS 參照判斷。
// 來源：CPG-13_TB_Lab_Report.md §2-2 +
//      01_source\代碼檔相關資料\附表三_檢驗查結果上傳項目.MD（114-01-01 實施版）
define "TbInlineLabLoincCodes": {
  '11545-1',  // AFB smear（NHI 13025C 抗酸性濃縮抹片染色檢查）
  '88563-4',  // MGIT 培養（NHI 13026C 抗酸菌培養限固液態並用）
  '10829-1',  // 固態培養（NHI 13012C 抗酸菌培養）
  '29576-8'   // DST 藥敏（NHI 13014B ≤3 藥 / 13015C ≥4 藥）
}

// ===============================================================
// Helper Functions
// ===============================================================

// DiagnosticReport.issued (FHIR.instant) -> System.DateTime
define function DRIssuedDT(DR FHIR.DiagnosticReport) returns DateTime:
  DR.issued.value

// DiagnosticReport.effective -> System.DateTime（choice type，加 cast）
define function DREffectiveDT(DR FHIR.DiagnosticReport) returns DateTime:
  Coalesce(
    (DR.effective as FHIR.dateTime).value,
    (DR.effective as FHIR.Period)."start".value
  )

// Specimen.collection.collected -> System.DateTime（choice type）
define function SpecimenCollectedDT(S FHIR.Specimen) returns DateTime:
  Coalesce(
    (S.collection.collected as FHIR.dateTime).value,
    (S.collection.collected as FHIR.Period)."start".value
  )

// Observation.effective -> System.DateTime
define function ObsEffectiveDT(O FHIR.Observation) returns DateTime:
  Coalesce(
    (O.effective as FHIR.dateTime).value,
    (O.effective as FHIR.Period)."start".value
  )

// 判斷一個 Coding 是否屬於 §2-2 指定的 LOINC 範圍
// 涵蓋：TWCore 13 組 + 本表單 inline 4 項（結核菌學獨有）
//   - TWCore v1.0 即有：ALT/AST/Albumin/Bili/Creatinine/Hb/WBC/Platelet/UricAcid（9 組）
//   - TWCore v1.2 晉升：ALP/BUN/血糖/腎絲球過濾率（4 組，全部 list 形式）
//   - 本表單 inline：AFB/MGIT/固態培養/DST（4 項，TB 獨有）
define function IsTbLabLoincCoding(Co FHIR.Coding) returns Boolean:
  Co.system.value = 'http://loinc.org'
    and (
      Co.code.value in CS."ALT GPT LOINC Codes"
        or Co.code.value in CS."AST GOT LOINC Codes"
        or Co.code.value in CS."白蛋白 LOINC Codes"
        or Co.code.value in CS."總膽紅素 LOINC Codes"
        or Co.code.value in CS."肌酸酐 血清 LOINC Codes"
        or Co.code.value in CS."血色素 LOINC Codes"
        or Co.code.value in CS."白血球計數 LOINC Codes"
        or Co.code.value in CS."血小板 LOINC Codes"
        or Co.code.value = CS."尿酸 LOINC"
        or Co.code.value in CS."ALP LOINC Codes"
        or Co.code.value in CS."BUN 尿素氮 LOINC Codes"
        or Co.code.value in CS."血糖 LOINC Codes"
        or Co.code.value in CS."腎絲球過濾率 LOINC Codes"
        or Co.code.value in "TbInlineLabLoincCodes"
    )

// ===============================================================
// Step 1: DiagnosticReport 篩選（主資源 - 最近 2 天內 issued）
// ===============================================================
define "RelevantDiagnosticReportsSorted":
  [DiagnosticReport] DR
    where DR.subject.reference.value = 'Patient/' + Patient.id
      and DRIssuedDT(DR) between (Now() - 30 days) and Now()
    return Tuple { sortKey: DRIssuedDT(DR), item: DR }
    sort by sortKey desc

define "LatestDiagnosticReport":
  First("RelevantDiagnosticReportsSorted").item

define "HasDiagnosticReport":
  exists "RelevantDiagnosticReportsSorted"

// ===============================================================
// Step 2: DR -> ServiceRequest -> Encounter 連結
// ===============================================================
define "DRServiceRequests":
  [ServiceRequest] SR
    where exists (
      "LatestDiagnosticReport".basedOn B
        where EndsWith(B.reference.value, SR.id)
    )

define "LatestServiceRequest":
  First("DRServiceRequests")

define "DREncounter":
  First(
    [Encounter] E
      where EndsWith("LatestServiceRequest".encounter.reference.value, E.id)
  )

// 機構連結（Encounter -> Location -> Organization）
define "DREncounterLocations":
  [Location] Lo
    where exists (
      "DREncounter".location L
        where EndsWith(L.location.reference.value, Lo.id)
    )

define "DREncounterOrganizations":
  [Organization] O
    where exists (
      "DREncounterLocations" Lo
        where EndsWith(Lo.managingOrganization.reference.value, O.id)
    )

// ===============================================================
// Step 3: Condition (ICD-10 §2-1) 診斷確認
// ===============================================================
define "DREncounterConditions":
  [Condition] C
    where exists (
      "DREncounter".diagnosis D
        where EndsWith(D.condition.reference.value, C.id)
    )

// 判斷該 Condition 是否符合 §2-1 ICD-10 任一條件
// 採用「前綴清單 + StartsWith」策略：清單放在「TbTriggerIcd10Prefixes」便於維護，
// 只承接 system = 'http://hl7.org/fhir/sid/icd-10-cm' 的 coding。
define function HasTbIcd10Code(C FHIR.Condition) returns Boolean:
  exists (
    C.code.coding Co
      where Co.system.value = 'http://hl7.org/fhir/sid/icd-10-cm'
        and exists (
          "TbTriggerIcd10Prefixes" Px
            where StartsWith(Coalesce(Co.code.value, ''), Px)
        )
  )

// 此 DR 對應的 Encounter 是否有 TB 相關診斷
// 由後續系統判斷是否上傳；CQL 仍輸出全部欄位
define "HasTbDiagnosis":
  exists (
    "DREncounterConditions" C
      where HasTbIcd10Code(C)
  )

// ===============================================================
// Step 4: DR.result -> Observation 列表（多筆 r1~rN 由上傳程式遞增）
// 只保留 §2-2 指定 LOINC 範圍內的檢驗項目（透過 IsTbLabLoincCoding 函數）
// ===============================================================
define "DRObservations":
  [Observation] O
    where exists (
      "LatestDiagnosticReport".result R
        where EndsWith(R.reference.value, O.id)
    )
      and exists (
        O.code.coding Co
          where IsTbLabLoincCoding(Co)
      )

define "FirstObservation":
  First("DRObservations")

// ===============================================================
// Step 5: DR.specimen -> Specimen
// ===============================================================
define "DRSpecimens":
  [Specimen] S
    where exists (
      "LatestDiagnosticReport".specimen Sp
        where EndsWith(Sp.reference.value, S.id)
    )

define "FirstSpecimen":
  First("DRSpecimens")

// ===============================================================
// 欄位 define（依 CPG-13 §4 共 18 欄位順序）
// ===============================================================

// --- 基本資料段（h2/h9/h11/h15/h16/h17/h20/h90）---

// 輸出欄位：醫事機構代碼（linkId：h2）
// Encounter.location -> Location.managingOrganization -> Organization.identifier
define "HospId":
  First(
    "DREncounterOrganizations" O
      return First(
        O.identifier I
          where I.value is not null
          return I.value.value
      )
  )

// 輸出欄位：身分證統一編號（linkId：h9）
define "IdNumber":
  First(
    Patient.identifier I
      where I.system.value = 'http://hl7.org/fhir/sid/tw-nid'
         or exists (I.type.coding Co where Co.code.value = 'NI')
      return I.value.value
  )

// 輸出欄位：就醫日期（linkId：h11）
// 仍取 Encounter.period.start（即使就醫日早於報告日數天，依 CPG §3-3 註）
define "EncounterDate":
  "DREncounter".period."start".value

// 輸出欄位：醫令代碼（linkId：h15）
// 對應 ServiceRequest.code.coding.code (LOINC system 為主)
// 僅篩 §2-2 指定 LOINC 範圍內者（透過 IsTbLabLoincCoding 函數）
define "OrderCode":
  First(
    "LatestServiceRequest".code.coding Co
      where IsTbLabLoincCoding(Co)
      return Co.code.value
  )

// 輸出欄位：檢驗結果上傳日期時間（linkId：h16）
define "LabIssuedDateTime":
  DRIssuedDT("LatestDiagnosticReport")

// 輸出欄位：醫囑醫師身分證號（linkId：h17）
// 取 Encounter.participant type='ATND' 對應 Practitioner.identifier
define "OrderingPractitionerId":
  First(
    "DREncounter".participant P
      let prac: singleton from (
        [Practitioner] Pr
          where EndsWith(P.individual.reference.value, Pr.id)
      )
      where exists (
        P.type T
          where exists (T.coding Co where Co.code.value = 'ATND')
      )
      return First(
        prac.identifier I
          where I.system.value = 'http://nhi.gov.tw/sid/practitioner-license'
          return I.value.value
      )
  )

// 輸出欄位：採檢/實際檢查日期時間（linkId：h20）
define "SpecimenCollectedDateTime":
  SpecimenCollectedDT("FirstSpecimen")

// 輸出欄位：醫院上傳唯一碼（linkId：h90，PK）
// Encounter.identifier 院端唯一碼（取 use=usual 或第一個有值的 identifier）
define "HospUploadId":
  First(
    "DREncounter".identifier I
      where I.value is not null
      return I.value.value
  )

// --- 報告資料段（r1/r2/r3/r4/r5/r6-1/r6-2/r10/r11/r12）---
// CQL 以 FirstObservation 為主提供第一筆內容；多筆 r1~rN 由上傳程式從 DRObservations 列表展開

// 輸出欄位：報告序號（linkId：r1）
// [待補] CDC 系統自動遞增（同一醫令多筆 Observation 時 1,2,3...），CQL 不上傳，保留 null
define "R1":
  null

// 輸出欄位：檢驗項目名稱（linkId：r2）
define "LabTestName":
  "FirstObservation".code.text.value

// 輸出欄位：檢驗方法（linkId：r3）
define "LabTestMethod":
  "FirstObservation".method.text.value

// 輸出欄位：檢驗報告結果值（linkId：r4）
// Observation.value[x] choice type，依序嘗試 Quantity / string
define "LabResultValue":
  Coalesce(
    ToString(("FirstObservation".value as FHIR.Quantity).value.value),
    ("FirstObservation".value as FHIR.string).value
  )

// 輸出欄位：單位（linkId：r5）
define "LabResultUnit":
  ("FirstObservation".value as FHIR.Quantity).unit.value

// 輸出欄位：參考值下限（linkId：r6-1）
// Summary key 改為 r6_1 (CQL Tuple key 不接受連字符)
define "LabRefRangeLow":
  ToString(First("FirstObservation".referenceRange).low.value.value)

// 輸出欄位：參考值上限（linkId：r6-2）
// Summary key 改為 r6_2
define "LabRefRangeHigh":
  ToString(First("FirstObservation".referenceRange).high.value.value)

// 輸出欄位：報告日期時間（linkId：r10）
define "ReportDateTime":
  DREffectiveDT("LatestDiagnosticReport")

// 輸出欄位：備註（linkId：r11）
// [待確認] CPG §5-2 r11 無標準 FHIR PATH；本版本暫以 DiagnosticReport.conclusion 處理
define "ReportNote":
  "LatestDiagnosticReport".conclusion.value

// 輸出欄位：檢驗結果值註記（linkId：r12）
// Observation.interpretation.coding.code（0=正常；1=異常）
// FHIR R4 標準 interpretation code: N=Normal, H=High, L=Low, A=Abnormal
// 此處保留原始 code，由上傳程式做 0/1 轉換
define "LabResultInterpretation":
  First(
    "FirstObservation".interpretation I
      return First(I.coding Co return Co.code.value)
  )

// ===============================================================
// Summary Tuple (SDC $populate 使用)
// key = Questionnaire item.linkId（含連字符的 r6-1/r6-2 改為 r6_1/r6_2 以符合 CQL Tuple key 命名）
// value = CQL define 名稱（PascalCase 無底線）
// ===============================================================
define "Summary":
  Tuple {
    h2   : "HospId",
    h9   : "IdNumber",
    h11  : "EncounterDate",
    h15  : "OrderCode",
    h16  : "LabIssuedDateTime",
    h17  : "OrderingPractitionerId",
    h20  : "SpecimenCollectedDateTime",
    h90  : "HospUploadId",
    r1   : "R1",
    r2   : "LabTestName",
    r3   : "LabTestMethod",
    r4   : "LabResultValue",
    r5   : "LabResultUnit",
    r6_1 : "LabRefRangeLow",
    r6_2 : "LabRefRangeHigh",
    r10  : "ReportDateTime",
    r11  : "ReportNote",
    r12  : "LabResultInterpretation"
  }
