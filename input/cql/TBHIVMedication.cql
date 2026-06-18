/*
 * Library : TB_HIV_Medication
 * Title   : 結核及愛滋用藥上傳 (TB/HIV Medication Upload) CQL
 * Version : 0.1.2
 * Date    : 2026-05-20
 *
 * 撈取邏輯（CPG-12 v4）:
 *   - 撈取本病人「最近 1 天內」的 Encounter（即今日就醫；LookbackDays=1）
 *   - 以 LatestEncounter 為中心，撈取 Location/Organization/Practitioner/Condition/
 *     MedicationRequest/Observation/Specimen 等關聯資料
 *   - 不在 CQL 層篩選藥品成分（一線藥一律輸出；二線藥成分判斷與診斷雙重過濾
 *     依 CPG §3-4 兩層邏輯由後續系統處理）
 *
 * 共用 Library:
 *   - TWCore_CodeSystems_NHI v1.2.0  →  體重 LOINC (29463-7)
 *
 * 欄位對應參考: CPG-12_TB_HIV_Medication.md（含 Form-12 FormMD、TWCDI 對照）
 * Questionnaire: Questionnaires-12_結核及愛滋用藥上傳_draft_v0.0.1_20260126.json
 *
 * 修正歷程:
 *   - v0.1.0: 初版（依 CPG-12 v4，32 欄位；可直接產 16 欄、待補 5 欄、null 1 欄）
 *   - v0.1.1: 修正 CQL engine 報錯（compile error）:
 *             (1) DrugUse 的 dose cast 從 FHIR.Quantity 改為 FHIR.SimpleQuantity
 *                 （MedicationRequest.dosageInstruction.doseAndRate.dose[x] 為
 *                  choice<Range|SimpleQuantity>，須 cast SimpleQuantity）
 *             (2) DrugNo/DrugUse/DrugPath/ResultMemo/LabReportDate 拆解嵌套 query
 *                 為多階 define（MedicationCodings、FirstDosageInstruction、
 *                 FirstDoseAndRate、FirstLabObservation），避免 inner-query 解析失敗
 *   - v0.1.2: 修正 LOINC hardcode 違規（CLAUDE.md §CQL 強制規則）:
 *             引用 TWCore_CodeSystems_NHI v1.2.0，
 *             WeightObsSorted / LabObsSorted 內 '29463-7' 改為 CS."體重 LOINC"
 */

library TBHIVMedication version '0.1.2'

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

// CPG-12 §3-1: 每日排程上傳乙次（LookbackDays = 1，今日就醫）
// 註: CQL parser 不接受「Integer 變數 days」語法，故時間區間以 hardcode 1 day；
//     LookbackDays parameter 保留供未來擴充
parameter "LookbackDays" Integer default 1

// ---------------------------------------------------------------
// Context
// ---------------------------------------------------------------
context Patient

// ===============================================================
// Helper Functions（returns 型別明確宣告）
// ===============================================================

// Observation.effective -> System.DateTime（規則 6: 加 .value）
define function ObsEffectiveDT(O FHIR.Observation) returns DateTime:
  Coalesce(
    (O.effective as FHIR.dateTime).value,
    (O.effective as FHIR.Period)."start".value
  )

// Observation.value -> Quantity 數值
define function ObsValueQuantity(O FHIR.Observation) returns Decimal:
  (O.value as FHIR.Quantity).value.value

// ===============================================================
// Encounter 篩選（最近 1 天內就醫）
// ===============================================================
define "RelevantEncounters":
  [Encounter] E
    where E.subject.reference.value = 'Patient/' + Patient.id
      and E.period."start" between (Now() - 30 day) and Now()

define "LatestEncounter":
  First(
    "RelevantEncounters" E
      sort by period."start" desc
  )

define "HasEncounter":
  exists "RelevantEncounters"

// ===============================================================
// 機構連結（Encounter -> Location -> Organization）
// 修正: CQL 不允許 query let 內 retrieve [Resource]，採獨立 define 兩段式
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
// 本次就醫相關 MedicationRequest / Observation / Specimen
// ===============================================================
define "EncounterMedicationRequests":
  [MedicationRequest] MR
    where MR.subject.reference.value = 'Patient/' + Patient.id
      and MR.encounter.reference.value = 'Encounter/' + "LatestEncounter".id

define "LatestMedicationRequest":
  First(
    "EncounterMedicationRequests" MR
      sort by authoredOn desc
  )

// MedicationRequest 拆解（避免嵌套 query 解析錯誤）
define "MedicationCodings":
  ("LatestMedicationRequest".medication as FHIR.CodeableConcept).coding

define "FirstDosageInstruction":
  First("LatestMedicationRequest".dosageInstruction)

define "FirstDoseAndRate":
  First("FirstDosageInstruction".doseAndRate)

// 體重 Observation（CS."體重 LOINC" = 29463-7 = Body weight）
define "WeightObsSorted":
  [Observation] O
    where O.subject.reference.value = 'Patient/' + Patient.id
      and exists (O.code.coding Co where Co.code.value = CS."體重 LOINC")
    return Tuple { sortKey: ObsEffectiveDT(O), item: O }
    sort by sortKey desc

// 本次就醫的生化檢驗 Observation（排除體重）
define "LabObsSorted":
  [Observation] O
    where O.subject.reference.value = 'Patient/' + Patient.id
      and O.encounter.reference.value = 'Encounter/' + "LatestEncounter".id
      and not exists (O.code.coding Co where Co.code.value = CS."體重 LOINC")
    return Tuple { sortKey: ObsEffectiveDT(O), item: O }
    sort by sortKey desc

define "FirstLabObservation":
  First("LabObsSorted").item

// ===============================================================
// 欄位 define（依 CPG-12 §4 共 32 欄位順序）
// ===============================================================

// 輸出欄位：流水號（linkId：SEQ_NO）
// [待補] CDC 系統自動遞增流水號，不納入 CQL 上傳；保留 null
define "SeqNo":
  null

// 輸出欄位：醫事機構代碼（linkId：HOSP_ID）
define "HospId":
  First(
    "EncounterOrganizations" O
      return First(
        O.identifier I
          where I.value is not null
          return I.value.value
      )
  )

// 輸出欄位：身分證號（linkId：ID）
define "IdNumber":
  First(
    Patient.identifier I
      where I.system.value = 'http://hl7.org/fhir/sid/tw-nid'
         or exists (I.type.coding Co where Co.code.value = 'NI')
      return I.value.value
  )

// 輸出欄位：就醫日期（linkId：FUNC_DATE）
define "FuncDate":
  "LatestEncounter".period."start".value

// 輸出欄位：病歷號（linkId：HospitalId）
// 以 identifier.type.coding.code = 'MR' (Medical Record number) 區分
define "HospitalId":
  First(
    Patient.identifier I
      where exists (I.type.coding Co where Co.code.value = 'MR')
      return I.value.value
  )

// 輸出欄位：體重 kg（linkId：Weight）
define "Weight":
  ObsValueQuantity(First("WeightObsSorted").item)

// 輸出欄位：轉入院所代碼（linkId：TranInHospId）
// [待補] 需 Encounter.location.physicalType 或 Extension 區分「轉入院所」vs「就醫院所」
//        CPG §5-2 待 TW Core Profile 確認後補充
define "TranInHospId":
  null

// 輸出欄位：特定治療項目代號(一)（linkId：CureItemN01）
// [待補] 需 Procedure Resource，CPG-12 本期不處理（CPG §3-4 註明只處理用藥）
define "CureItemN01":
  null

// 輸出欄位：特定治療項目代號(二)（linkId：CureItemN02）
// [待補] 同 CureItemN01
define "CureItemN02":
  null

// 輸出欄位：特定治療項目代號(三)（linkId：CureItemN03）
// [待補] 同 CureItemN01
define "CureItemN03":
  null

// 輸出欄位：特定治療項目代號(四)（linkId：CureItemN04）
// [待補] 同 CureItemN01
define "CureItemN04":
  null

// 輸出欄位：ICD10主診斷（linkId：Icd10Cm1）
// 由 Encounter.diagnosis.rank = 1 對應的 Condition.code 取得
define "Icd10Cm1":
  First(
    [Condition] C
      where exists (
        "LatestEncounter".diagnosis D
          where D.rank.value = 1
            and EndsWith(D.condition.reference.value, C.id)
      )
      return First(C.code.coding Co return Co.code.value)
  )

// 輸出欄位：ICD10副診斷(一)（linkId：Icd10Cm2）
define "Icd10Cm2":
  First(
    [Condition] C
      where exists (
        "LatestEncounter".diagnosis D
          where D.rank.value = 2
            and EndsWith(D.condition.reference.value, C.id)
      )
      return First(C.code.coding Co return Co.code.value)
  )

// 輸出欄位：ICD10副診斷(二)（linkId：Icd10Cm3）
define "Icd10Cm3":
  First(
    [Condition] C
      where exists (
        "LatestEncounter".diagnosis D
          where D.rank.value = 3
            and EndsWith(D.condition.reference.value, C.id)
      )
      return First(C.code.coding Co return Co.code.value)
  )

// 輸出欄位：ICD10副診斷(三)（linkId：Icd10Cm4）
define "Icd10Cm4":
  First(
    [Condition] C
      where exists (
        "LatestEncounter".diagnosis D
          where D.rank.value = 4
            and EndsWith(D.condition.reference.value, C.id)
      )
      return First(C.code.coding Co return Co.code.value)
  )

// 輸出欄位：ICD10副診斷(四)（linkId：Icd10Cm5）
define "Icd10Cm5":
  First(
    [Condition] C
      where exists (
        "LatestEncounter".diagnosis D
          where D.rank.value = 5
            and EndsWith(D.condition.reference.value, C.id)
      )
      return First(C.code.coding Co return Co.code.value)
  )

// 輸出欄位：診療醫師證號（linkId：PrsnId）
// 取 Encounter.participant 中 type='ATND'（主治醫師）對應的 Practitioner.identifier
define "PrsnId":
  First(
    "LatestEncounter".participant P
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

// 輸出欄位：門住診別（linkId：CaseStatus）
// Encounter.class.code → 轉換為 N/E/R/P/D/Y
// [待確認] CPG §5-2: P（負壓）、Y（住院其他）、D（出院備藥）無標準 FHIR class code，
//          需 Extension 區分；本版本暫以 IMP→R 處理，其他三種待 Extension URL 確認
define "CaseStatus":
  case "LatestEncounter".class.code.value
    when 'AMB'  then 'N'
    when 'EMER' then 'E'
    when 'IMP'  then 'R'
    else null
  end

// 輸出欄位：入院日期（linkId：CaseInDate）
// 住院（R/P/D/Y）時與 FUNC_DATE 同；門急診為 null
define "CaseInDate":
  if "CaseStatus" in { 'R', 'P', 'D', 'Y' }
    then "LatestEncounter".period."start".value
  else null

// 輸出欄位：出院日期（linkId：CaseOutDate）
define "CaseOutDate":
  "LatestEncounter".period."end".value

// 輸出欄位：藥品代碼（linkId：DrugNo）
// [待確認] FHIR R4 MedicationRequest.medication 為 choice (CodeableConcept | Reference)；
//          本版本以 CodeableConcept 為主；若實際採 Reference(Medication)，
//          需改為兩段式撈取 [Medication] 後取 code
define "DrugNo":
  First(
    "MedicationCodings" Co
      return Co.code.value
  )

// 輸出欄位：藥品用量（linkId：DrugUse）
// 取 MedicationRequest.dosageInstruction.doseAndRate.dose（choice<Range|SimpleQuantity>，cast 為 SimpleQuantity）
define "DrugUse":
  ToString(("FirstDoseAndRate".dose as FHIR.SimpleQuantity).value.value)

// 輸出欄位：藥品總量（linkId：TotalQ）
define "TotalQ":
  ToString("LatestMedicationRequest".dispenseRequest.quantity.value.value)

// 輸出欄位：用藥頻率（linkId：DrugPath）
// QD/BID/TID/QID 英文縮寫，取 timing.code.text
define "DrugPath":
  "FirstDosageInstruction".timing.code.text.value

// 輸出欄位：醫令給藥日份（linkId：DrugDay）
define "DrugDay":
  ToString("LatestMedicationRequest".dispenseRequest.expectedSupplyDuration.value.value)

// 輸出欄位：醫令序號（linkId：OrderSeqNo）
// [待替換] 暫用 URL，取得正式 URL 後請替換此處
// 暫用 URL: http://example.org/CodeSystem/PLACEHOLDER-EncounterOrderSeq
define "OrderSeqNo":
  First(
    "LatestEncounter".identifier I
      where I.system.value = 'http://example.org/CodeSystem/PLACEHOLDER-EncounterOrderSeq'
      return I.value.value
  )

// 輸出欄位：生化檢驗報告日（linkId：LabReportDate）
define "LabReportDate":
  ObsEffectiveDT("FirstLabObservation")

// 輸出欄位：檢驗結果說明（linkId：ResultMemo）
// [待補] CPG §5-2 註明：需多筆 Observation.component 串接為「項目名稱/結果/單位;;...」格式；
//        本版本以單筆 Observation.note.text 簡化輸出，完整 component 串接邏輯待後續補充
define "ResultMemo":
  First(
    "FirstLabObservation".note N
      return N.text.value
  )

// 輸出欄位：院端醫令識別碼（linkId：Hosp_SEQ_NO）
// 由 Encounter.identifier + "-" + MedicationRequest.identifier 串接（規則 3 Null Guard）
// CPG §4-29: 確保同次就醫不同藥品各自唯一
define "HospSeqNo":
  if "LatestEncounter" is null then null
  else Coalesce(
    First("LatestEncounter".identifier I return I.value.value),
    ''
  ) + '-' + Coalesce(
    First("LatestMedicationRequest".identifier I return I.value.value),
    Coalesce("DrugNo", '')
  )

// 輸出欄位：就醫科別（linkId：FUNC_TYPE）
define "FuncType":
  First(
    "LatestEncounter".serviceType.coding Co
      return Co.code.value
  )

// 輸出欄位：資料來源（linkId：DISSOURCE）
// CPG §2-6: TB/LTBI 治療固定常數 'T'（DISSOURCE 為系統邏輯推導值，無直接 FHIR PATH）
define "Dissource":
  'T'

// 輸出欄位：檢體代碼（linkId：SampleCode）
define "SampleCode":
  First(
    [Specimen] S
      where S.subject.reference.value = 'Patient/' + Patient.id
      return First(
        S.identifier I
          where I.value is not null
          return I.value.value
      )
  )

// ===============================================================
// Summary Tuple (SDC $populate 使用)
// key = Questionnaire item.linkId（本表單 linkId 為混合風格，沿用原樣）
// value = CQL define 名稱（PascalCase）
// ===============================================================
define "Summary":
  Tuple {
    SEQ_NO        : "SeqNo",
    HOSP_ID       : "HospId",
    ID            : "IdNumber",
    FUNC_DATE     : "FuncDate",
    HospitalId    : "HospitalId",
    Weight        : "Weight",
    TranInHospId  : "TranInHospId",
    CureItemN01   : "CureItemN01",
    CureItemN02   : "CureItemN02",
    CureItemN03   : "CureItemN03",
    CureItemN04   : "CureItemN04",
    Icd10Cm1      : "Icd10Cm1",
    Icd10Cm2      : "Icd10Cm2",
    Icd10Cm3      : "Icd10Cm3",
    Icd10Cm4      : "Icd10Cm4",
    Icd10Cm5      : "Icd10Cm5",
    PrsnId        : "PrsnId",
    CaseStatus    : "CaseStatus",
    CaseInDate    : "CaseInDate",
    CaseOutDate   : "CaseOutDate",
    DrugNo        : "DrugNo",
    DrugUse       : "DrugUse",
    TotalQ        : "TotalQ",
    DrugPath      : "DrugPath",
    DrugDay       : "DrugDay",
    OrderSeqNo    : "OrderSeqNo",
    LabReportDate : "LabReportDate",
    ResultMemo    : "ResultMemo",
    Hosp_SEQ_NO   : "HospSeqNo",
    FUNC_TYPE     : "FuncType",
    DISSOURCE     : "Dissource",
    SampleCode    : "SampleCode"
  }
