/*
 * Library : Child_Preventive_Health
 * Title   : 兒童預防保健 (Child Preventive Health) CQL
 * Version : 0.3.1
 * Date    : 2026-05-24
 *
 * 撈取邏輯（依 CPG-04 v2，2026-05-22 重整）:
 *   - 主資源: Encounter（以 ICCode 為觸發 + class.code='AMB' + status='finished'）
 *     注：CPG-04 §2-3/§3-1 寫 'AC'，但 TWCore IG 依 FHIR R4 v3 ActCode 標準應為 'AMB'
 *          ─ 此處依 TWCore 規範採 'AMB'，'AC' 視為 CPG 誤植
 *   - LookbackDays: 30 天（測試 workaround；上線前須回 CPG 規範「今日」）
 *   - ICCode 觸發集合:
 *       健檢: 20 / 71 / 72 / 73 / 75 / 76 / 77 / 79
 *       發展篩檢: 7A / 7B / 7C / 7D / 7E / 7F（v2 新增 7E/7F）
 *       衛教: 01-07（搭配各次健檢）
 *
 * 關聯資源:
 *   - Patient: 基本資料（姓名、性別、出生日期、身分證號、電話、地址、胎序）
 *   - RelatedPerson: 依附就醫的父/母身分證號（DependID）
 *   - Organization: OrganizationCode（就醫機構）/ HealthCenterCode（衛生所）
 *   - Encounter: ICCode、就醫序號、就醫日期、class.code、依附旗標
 *   - Observation: 生長測量、健康/生長/身體/發展評估
 *   - QuestionnaireResponse: 題項作答（Col1-Col102，雙格式並存）
 *
 * 命名規則（依 CPG_Production_Guide Part 2 §6-3）:
 *   - 跨 CPG 標準: OrganizationCode、HealthCenterCode、PatientIdNumber、
 *                  PatientName、BirthDate、GenderCode、HomePhone、MobilePhone、
 *                  City、Address
 *   - 表二: HealthAssessmentResult、GrowthAssessmentResult、BodyHeight、
 *           BodyWeight、HeadCircumference、HeightPercentile、IsDependentVisit、
 *           DependentPersonId、IsPremature、ExpectedDeliveryDate、BirthOrder
 *   - 表三新增: DataFormatCode、AgeInYears、AgeInMonthsMod12、
 *               HasGrowthAbnormality、GrowthFollowupRecommendation 等
 *
 * 新增業務邏輯（CPG v2 §3-2）:
 *   - 聯動必填：IsDepend≠0 → DependID；Col16/18/20=1 → Col17/19/21；
 *               IsPremature=1 → PrematureDate
 *   - A/B/C 題組依月齡分流：
 *       A 題組（Col42-Col56 + Col95）: IC76 / Col1='1' / 1.5-2 歲
 *       B 題組（Col57-Col73 + Col96-Col99）: IC79 / Col1='2' / 36-48 月
 *       C 題組（Col74-Col89 + Col100）: IC79 / Col1='2' / 48-84 月
 *   - 健保卡類別（IC20 聽力篩檢專用）vs IsDepend（健檢欄位）區分
 *
 * 修正歷程:
 *   - v0.1.0: 初版（雙格式並存設計，120+ 欄位）
 *   - v0.2.0~v0.2.3: 多次修正 ValueSet / identifier collision / Tail() syntax
 *   - v0.3.0: v2 重產（依 CPG-04 v2.0，2026-05-22）─
 *             跨 CPG 標準命名 + 聯動規則 + A/B/C 月齡分流 + 健保卡類別拆分
 *   - v0.3.1: Encounter.identifier 三處（RelevantEncountersSorted /
 *             ICCodeValue / EncounterIdentifier）補 system 篩選
 *             system = 'https://nhi.gov.tw/fhir/identifier/nhi-order-code'
 *             依 CQL_Guidelines v1.5 規則 12 + FHIR_Naming_Convention v1.3 §九
 *             + CPG-04 §2-0；測試資料同步 system URI
 *
 * [待補] FHIR Path 不明確項目:
 *   - TokenId、AssessmentCenterCode、DevelopmentQuestionTimes、
 *     HeightPercentileRef、SpecialRemark (Col92)
 *
 * [待確認] 業務面待確認項目:
 *   - IsPremature / ExpectedDeliveryDate FHIR Path
 *     （Patient.extension vs Observation.valueBoolean）
 *   - IsDepend 適用範圍（PDF 僅 IC20 vs 02_初版寫 IC71/72 也可依附）
 *   - HearingScreeningCardType Extension URL（暫佔位）
 *   - A 題組 Col51 / C 題組 Col84/Col86 與其他題目文字重複，需業務確認
 */

library ChildPreventiveHealth version '0.3.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

// ===============================================================
// Code Systems
// ===============================================================
codesystem "LOINC": 'http://loinc.org'
codesystem "TWNID": 'http://hl7.org/fhir/sid/tw-nid'

// ===============================================================
// Parameters
// ===============================================================
parameter "MeasurementPeriod" Interval<DateTime>
  default Interval[
    @2026-01-01T00:00:00.000,
    @2026-12-31T23:59:59.999
  ]

// CPG-04 v2 §3-1: 即時上傳（健保卡當日 / 虛擬卡 24h 內 / 聽力篩檢 14 日內）
// 註: CQL parser 不接受「Integer 變數 days」語法，時間區間 hardcode 30 days；
//     30 days 為測試 workaround，上線前須收緊回事件驅動「今日」。
parameter "LookbackDays" Integer default 30

// ===============================================================
// Context
// ===============================================================
context Patient

// ===============================================================
// IC 觸發代碼集合（CPG-04 v2 §2-1 + §2-2）
// ===============================================================

// 健檢醫令（IC20/71/72/73/75/76/77/79）
define "HealthCheck_ICCodes":
  { '20', '71', '72', '73', '75', '76', '77', '79' }

// 發展篩檢醫令（7A-7F，v2 新增 7E/7F）
define "DevScreen_ICCodes":
  { '7A', '7B', '7C', '7D', '7E', '7F' }

// 衛教醫令（01-07，搭配各次健檢）
define "HealthEdu_ICCodes":
  { '01', '02', '03', '04', '05', '06', '07' }

// 健檢觸發代碼總和（CQL 撈取用）
define "ChildHealthCheck_Trigger_Codes":
  ("HealthCheck_ICCodes" union "DevScreen_ICCodes") union "HealthEdu_ICCodes"

// ===============================================================
// Helper Functions（returns 型別明確宣告）
// ===============================================================

// Encounter.period.start → DateTime
define function EncPeriodStartDT(E FHIR.Encounter) returns DateTime:
  E.period."start".value

// Observation.value as FHIR.Quantity → Decimal
define function ObsValueQuantity(O FHIR.Observation) returns Decimal:
  (O.value as FHIR.Quantity).value.value

// Observation.value as FHIR.string → String
define function ObsValueString(O FHIR.Observation) returns String:
  (O.value as FHIR.string).value

// Observation.value as CodeableConcept → 首個 coding.code
define function ObsValueCodeableCode(O FHIR.Observation) returns String:
  ((O.value as FHIR.CodeableConcept).coding[0].code).value

// 整合: 優先 codeable, 其次 string
define function ObsValueCodeOrString(O FHIR.Observation) returns String:
  Coalesce(
    ObsValueCodeableCode(O),
    ObsValueString(O)
  )

// Observation.effective → DateTime
define function ObsEffectiveDT(O FHIR.Observation) returns DateTime:
  (O.effective as FHIR.dateTime).value

// 是否為指定 LOINC code 的 Observation
define function HasLoincCode(O FHIR.Observation, code String) returns Boolean:
  exists (
    O.code.coding C
      where C.system.value = 'http://loinc.org'
        and C.code.value = code
  )

// QuestionnaireResponse 取單一答案（支援頂層 + 一層巢狀）
define function GetQRAnswer(QR FHIR.QuestionnaireResponse, lid String) returns String:
  Coalesce(
    First(
      QR.item I
        where I.linkId.value = lid
        return First(I.answer A return (A.value as FHIR.string).value)
    ),
    First(
      QR.item I
        where exists (
          I.item Sub
            where Sub.linkId.value = lid
        )
        return First(
          I.item Sub
            where Sub.linkId.value = lid
            return First(Sub.answer A return (A.value as FHIR.string).value)
        )
    )
  )

// ===============================================================
// Encounter 篩選
// CPG-04 v2 §3-1: identifier ∈ 觸發集 + class.code='AMB' + status='finished'
// 注：CPG 寫 'AC'，TWCore IG 採 FHIR R4 v3 ActCode 標準 'AMB'，此處從 TWCore
// ===============================================================
define "RelevantEncountersSorted":
  [Encounter] E
    where E.subject.reference.value = 'Patient/' + Patient.id
      and EncPeriodStartDT(E) between (Now() - 30 days) and Now()
      and E.class.code.value = 'AMB'
      and E.status.value = 'finished'
      and exists (
        E.identifier I
          where I.system.value = 'https://nhi.gov.tw/fhir/identifier/nhi-order-code'
            and I.value.value in "ChildHealthCheck_Trigger_Codes"
      )
    return Tuple { sortKey: EncPeriodStartDT(E), item: E }
    sort by sortKey desc

define "LatestEncounter":
  First("RelevantEncountersSorted").item

define "HasEncounter":
  exists "RelevantEncountersSorted"

// ===============================================================
// 機構連結 (Encounter → Location → Organization)
// 依 Guide §6-3-1 標準 2 段式
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

// Tail(EncounterOrganizations) - 衛生所 (依 Guide §6-3-1 fallback)
define "SecondaryOrganizations":
  Tail("EncounterOrganizations")

// ===============================================================
// Observation / QuestionnaireResponse 篩選
// ===============================================================
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
      sort by authored desc
  )

// ===============================================================
// §6-1-A 表一基本欄位（共用，頂層 linkId）
// 命名依 Guide §6-3-1 / §6-3-2 跨 CPG 標準
// ===============================================================

// 輸出欄位: Token ID（linkId: TOKENID）
// [待補] FHIR Path 不明確
define "TokenId":
  null

// 輸出欄位: 就醫日期（linkId: FuncDate）
define "EncounterDate":
  "LatestEncounter".period."start".value

// 輸出欄位: 出生日期（linkId: Birthday）
define "BirthDate":
  Patient.birthDate.value

// 輸出欄位: 身分證號（linkId: PersonalID）依 Guide §6-3-2
define "PatientIdNumber":
  First(
    Patient.identifier I
      where I.system.value = 'http://hl7.org/fhir/sid/tw-nid'
         or exists (I.type.coding Co where Co.code.value = 'NI')
      return I.value.value
  )

// 輸出欄位: 姓名（linkId: Name）依 Guide §6-3-2
define "PatientName":
  First(Patient.name N return N.text.value)

// 輸出欄位: 性別（linkId: Sex）依 Guide §6-3-2
// 健保署代碼 1=男 / 2=女；FHIR 端為 male/female，回傳前轉碼
define "GenderCode":
  case Patient.gender.value
    when 'male'   then '1'
    when 'female' then '2'
    else null
  end

// 輸出欄位: 電話 1（linkId: Phone1）依 Guide §6-3-2: HomePhone
define "HomePhone":
  First(
    Patient.telecom T
      where T.system.value = 'phone'
        and (T.use.value = 'home' or T.use is null)
      return T.value.value
  )

// 輸出欄位: 行動電話（表三 Phone2）依 Guide §6-3-2
define "MobilePhone":
  First(
    Patient.telecom T
      where T.system.value = 'phone'
        and T.use.value = 'mobile'
      return T.value.value
  )

// 輸出欄位: 縣市代碼（linkId: City）依 Guide §6-3-2
define "City":
  First(Patient.address A return A.city.value)

// 輸出欄位: 地址（linkId: Address）依 Guide §6-3-2
define "Address":
  First(Patient.address A return A.text.value)

// 輸出欄位: 發展異常類別（linkId: Category）
// Observation.component.valueCodeableConcept，多值
define "DevelopmentAbnormalCategory":
  First(
    "EncounterObservations" O
      where exists (
        O.code.coding C
          where C.code.value = 'development-abnormal-category'
      )
      return First(
        O.component Comp
          return ((Comp.value as FHIR.CodeableConcept).coding[0].code).value
      )
  )

// 輸出欄位: IC 代碼（linkId: ICCode）
define "ICCodeValue":
  First(
    "LatestEncounter".identifier I
      where I.system.value = 'https://nhi.gov.tw/fhir/identifier/nhi-order-code'
        and I.value.value in "ChildHealthCheck_Trigger_Codes"
      return I.value.value
  )

// 輸出欄位: 醫事機構代碼（linkId: HospitalID）依 Guide §6-3-1 標準 chain
define "OrganizationCode":
  First(
    "EncounterOrganizations" O
      return First(
        O.identifier I
          where I.value is not null
          return I.value.value
      )
  )

// --- 表一發展題項 Col1-Col10 + Col7Content + ColExt + ColExtContent ---
// CPG v2 §6-1-A: Col1-Col10 改名 QuestionItem1~QuestionItem9 等

// 輸出欄位: 題項 1（linkId: Col1）2=無 / 1=有
define "QuestionItem1":
  GetQRAnswer("LatestQuestionnaireResponse", 'Col1')

// 輸出欄位: 題項 2（linkId: Col2）
define "QuestionItem2":
  GetQRAnswer("LatestQuestionnaireResponse", 'Col2')

// 輸出欄位: 題項 3（linkId: Col3）
define "QuestionItem3":
  GetQRAnswer("LatestQuestionnaireResponse", 'Col3')

// 輸出欄位: 題項 4（linkId: Col4）
define "QuestionItem4":
  GetQRAnswer("LatestQuestionnaireResponse", 'Col4')

// 輸出欄位: 題項 5（linkId: Col5）
define "QuestionItem5":
  GetQRAnswer("LatestQuestionnaireResponse", 'Col5')

// 輸出欄位: 題項 6（linkId: Col6）
define "QuestionItem6":
  GetQRAnswer("LatestQuestionnaireResponse", 'Col6')

// 輸出欄位: 題項 7「其他」（linkId: Col7）2=無其他 / 1=有其他
define "QuestionItem7":
  GetQRAnswer("LatestQuestionnaireResponse", 'Col7')

// 輸出欄位: 其他內容（linkId: Col7Content）
// 聯動: Col7=1 時填寫
define "OtherQuestionItemContent":
  if Coalesce("QuestionItem7", '') = '1'
    then GetQRAnswer("LatestQuestionnaireResponse", 'Col7Content')
  else null

// 輸出欄位: 題項 8（linkId: Col8）
define "QuestionItem8":
  GetQRAnswer("LatestQuestionnaireResponse", 'Col8')

// 輸出欄位: 題項 9（linkId: Col9）
define "QuestionItem9":
  GetQRAnswer("LatestQuestionnaireResponse", 'Col9')

// 輸出欄位: 題項 10（linkId: Col10）
define "QuestionItem10":
  GetQRAnswer("LatestQuestionnaireResponse", 'Col10')

// 輸出欄位: 擴展題項（linkId: ColExt）1 聽力 / 2 視覺 / 3 早產兒 / 4 低出生體重 / 5 其它
define "ExtendedQuestionItem":
  GetQRAnswer("LatestQuestionnaireResponse", 'ColExt')

// 輸出欄位: 擴展題項其他內容（linkId: ColExtContent）
define "ExtendedQuestionContent":
  GetQRAnswer("LatestQuestionnaireResponse", 'ColExtContent')

// ===============================================================
// §6-1-B 表二（IC71/72/73/75/77）
// linkId 前綴: new_visit_prev_health_t12346_*
// ===============================================================

// 輸出欄位: 評估中心 ID（linkId 後綴: AssessID）
// [待補] FHIR Path 不明確
define "AssessmentCenterCode":
  null

// 輸出欄位: 健康評估結果（linkId 後綴: HealthResult）1=無明顯異常 / 2=需注意或異常
define "HealthAssessmentResult":
  First(
    "EncounterObservations" O
      where exists (O.code.coding C where C.code.value = 'health-assessment-result')
      return ObsValueCodeOrString(O)
  )

// 輸出欄位: 生長評估結果（linkId 後綴: GrowResult）0/1/2
define "GrowthAssessmentResult":
  First(
    "EncounterObservations" O
      where exists (O.code.coding C where C.code.value = 'growth-assessment-result')
      return ObsValueCodeOrString(O)
  )

// 輸出欄位: 身體檢查結果（linkId 後綴: BodyResult）0/1/2
define "BodyExaminationResult":
  First(
    "EncounterObservations" O
      where exists (O.code.coding C where C.code.value = 'body-examination-result')
      return ObsValueCodeOrString(O)
  )

// 輸出欄位: 發展評估結果（linkId 後綴: DevelopResult）0/1/2
define "DevelopmentAssessmentResult":
  First(
    "EncounterObservations" O
      where exists (O.code.coding C where C.code.value = 'development-assessment-result')
      return ObsValueCodeOrString(O)
  )

// 輸出欄位: 生長評估問題（linkId 後綴: GrowReason）多值
define "GrowthAbnormalReason":
  First(
    "EncounterObservations" O
      where exists (O.code.coding C where C.code.value = 'growth-abnormal-reason')
      return ObsValueCodeOrString(O)
  )

// 輸出欄位: 身體檢查問題（linkId 後綴: BobyReason）多值
define "BodyAbnormalReason":
  First(
    "EncounterObservations" O
      where exists (O.code.coding C where C.code.value = 'body-abnormal-reason')
      return ObsValueCodeOrString(O)
  )

// 輸出欄位: 發展評估問題（linkId 後綴: BodyGeneralReason）多值
define "DevelopmentAbnormalReason":
  First(
    "EncounterObservations" O
      where exists (O.code.coding C where C.code.value = 'development-abnormal-reason')
      return ObsValueCodeOrString(O)
  )

// 輸出欄位: 第幾次預防保健問題（linkId 後綴: DevelopQuestionTimes）
// [待補] FHIR Path 不明確
define "DevelopmentQuestionTimes":
  null

// 輸出欄位: 身高（linkId 後綴: Height）LOINC 8302-2
define "BodyHeight":
  First(
    "EncounterObservations" O
      where HasLoincCode(O, '8302-2')
      return ObsValueQuantity(O)
  )

// 輸出欄位: 體重（linkId 後綴: Weight）LOINC 29463-7
define "BodyWeight":
  First(
    "EncounterObservations" O
      where HasLoincCode(O, '29463-7')
      return ObsValueQuantity(O)
  )

// 輸出欄位: 頭圍（linkId 後綴: Head）LOINC 9843-4
define "HeadCircumference":
  First(
    "EncounterObservations" O
      where HasLoincCode(O, '9843-4')
      return ObsValueQuantity(O)
  )

// 輸出欄位: 身高百分位（linkId 後綴: HeightPercent）
define "HeightPercentile":
  First(
    "EncounterObservations" O
      where exists (O.code.coding C where C.code.value = 'height-percentile')
      return ObsValueQuantity(O)
  )

// 輸出欄位: 體重百分位（linkId 後綴: WeightPercent）
define "WeightPercentile":
  First(
    "EncounterObservations" O
      where exists (O.code.coding C where C.code.value = 'weight-percentile')
      return ObsValueQuantity(O)
  )

// 輸出欄位: 頭圍百分位（linkId 後綴: HeadPercent）Observation.component
define "HeadCircumferencePercentile":
  First(
    "EncounterObservations" O
      where exists (O.code.coding C where C.code.value = 'head-circumference-percentile')
      return First(
        O.component Comp
          return (Comp.value as FHIR.Quantity).value.value
      )
  )

// 輸出欄位: 衛生所代碼（linkId 後綴: ThirdId）依 Guide §6-3-1 fallback
define "HealthCenterCode":
  First(
    "SecondaryOrganizations" O
      return First(
        O.identifier I
          where I.value is not null
          return I.value.value
      )
  )

// 輸出欄位: 依附就醫旗標（linkId 後綴: IsDepend）0-4
// [待確認] IsDepend 適用範圍：PDF 僅 IC20，02_初版寫 IC71/72 也可依附
// [待補] FHIR Path 不明確，暫用 Encounter.identifier.extension
define "IsDependentVisit":
  First(
    "LatestEncounter".identifier I
      return First(
        I.extension E
          where E.url.value = 'http://example.org/StructureDefinition/encounter-isdepend'
          return (E.value as FHIR.string).value
      )
  )

// 輸出欄位: 依附人身分證號（linkId 後綴: DependID）RelatedPerson.identifier
// CPG §3-2-3 聯動: IsDepend ≠ 0 → DependID 必填
// CQL 聯動: 若 IsDepend=0 / null 則 DependID 輸出 null
define "DependentPersonId":
  if "IsDependentVisit" is null or "IsDependentVisit" = '0' then null
  else First(
    [RelatedPerson] RP
      where EndsWith(RP.patient.reference.value, Patient.id)
      return First(
        RP.identifier I
          where I.value is not null
          return I.value.value
      )
  )

// 輸出欄位: 是否早產（linkId 後綴: IsPremature）0 否 / 1 是
// [待確認] Patient.extension[premature] 或 Observation.valueBoolean
define "IsPremature":
  Coalesce(
    First(
      Patient.extension E
        where EndsWith(E.url.value, 'premature')
        return ToString((E.value as FHIR.boolean).value)
    ),
    First(
      "EncounterObservations" O
        where exists (O.code.coding C where C.code.value = 'premature-flag')
        return ToString((O.value as FHIR.boolean).value)
    )
  )

// 輸出欄位: 預產期（linkId 後綴: PrematureDate）
// CPG §3-2-5 聯動: IsPremature=1 時必填
// CQL 聯動: 若 IsPremature ≠ 'true' 則 ExpectedDeliveryDate 輸出 null
// [待確認] Patient.extension[expectedDeliveryDate] 或 Observation.effectiveDateTime
define "ExpectedDeliveryDate":
  if Coalesce("IsPremature", '') = 'true' then
    Coalesce(
      First(
        Patient.extension E
          where EndsWith(E.url.value, 'expectedDeliveryDate')
          return (E.value as FHIR.date).value
      ),
      First(
        "EncounterObservations" O
          where exists (O.code.coding C where C.code.value = 'expected-delivery-date')
          return ObsEffectiveDT(O)
      )
    )
  else null

// 輸出欄位: 胎序（linkId 後綴: TiSu）
// Patient.multipleBirth 是 choice<boolean|integer>，需 cast 取 integer
define "BirthOrder":
  if Patient.multipleBirth is null then null
  else ToString((Patient.multipleBirth as FHIR.integer).value)

// ===============================================================
// 新生兒聽力篩檢「健保卡類別」（CPG §3-2-3 註，IC20 專用）
// PDF A2 附表一之八第 13/14 項: 1 母 / 2 父 / 3 新生兒卡 / 4 無卡
// 與 IsDependentVisit 區分（後者用於健檢欄位）
// [待補] FHIR Path 不明確
// ===============================================================
define "HearingScreeningCardType":
  if "ICCodeValue" = '20' then
    First(
      "LatestEncounter".identifier I
        return First(
          I.extension E
            where E.url.value = 'http://example.org/StructureDefinition/encounter-cardtype'
            return (E.value as FHIR.string).value
        )
    )
  else null

// ===============================================================
// §6-1-C 表三（IC76/IC79）
// linkId 前綴: upload_prev_health_t57_*
// ===============================================================

// 輸出欄位: 資料格式（linkId 後綴: Col1）1=1.5-2 歲(IC76) / 2=3-7 歲(IC79)
define "DataFormatCode":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col1')

// 輸出欄位: 年齡（歲，linkId 後綴: Col6）由 BirthDate + EncounterDate 計算
define "AgeInYears":
  years between
    Patient.birthDate.value
    and (date from "LatestEncounter".period."start".value)

// 輸出欄位: 年齡（月 mod 12，linkId 後綴: Col7）
define "AgeInMonthsMod12":
  (months between
    Patient.birthDate.value
    and (date from "LatestEncounter".period."start".value)
  ) mod 12

// 輔助: 全月齡（A/B/C 題組分流用）
define "AgeInMonths":
  months between
    Patient.birthDate.value
    and (date from "LatestEncounter".period."start".value)

// --- 健康/生長評估 Col15-Col21 ---
// 注意：表三 0=無 / 1=有（與表二 1/2 邏輯不同），透過 QR 直接取值

// 輸出欄位: 健康評估（linkId 後綴: Col15）
define "Table3_HealthAssessmentResult":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col15')

// 輸出欄位: 生長異常旗標（linkId 後綴: Col16）0/1
define "HasGrowthAbnormality":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col16')

// 輸出欄位: 生長建議處置（linkId 後綴: Col17）
// CPG §3-2-4 聯動: Col16=1 時必填
define "GrowthFollowupRecommendation":
  if Coalesce("HasGrowthAbnormality", '') = '1'
    then GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col17')
  else null

// 輸出欄位: 身體檢查異常旗標（linkId 後綴: Col18）0/1
define "HasBodyAbnormality":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col18')

// 輸出欄位: 身體建議處置（linkId 後綴: Col19）
// CPG §3-2-4 聯動: Col18=1 時必填
define "BodyFollowupRecommendation":
  if Coalesce("HasBodyAbnormality", '') = '1'
    then GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col19')
  else null

// 輸出欄位: 發展異常旗標（linkId 後綴: Col20）0/1
define "HasDevelopmentAbnormality":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col20')

// 輸出欄位: 發展建議處置（linkId 後綴: Col21）
// CPG §3-2-4 聯動: Col20=1 時必填
define "DevelopmentFollowupRecommendation":
  if Coalesce("HasDevelopmentAbnormality", '') = '1'
    then GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col21')
  else null

// --- 異常項目細項 Col22-Col41（§4-4-C-3）---
// 生長評估異常 Col22-Col24
define "GrowthAbnormalHeight":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col22')

define "GrowthAbnormalWeight":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col23')

define "GrowthAbnormalHead":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col24')

// 身體檢查異常一般 Col25
define "BodyAbnormalGeneral":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col25')

// 一般檢查異常子項 Col26-Col38
define "BodyAbnormalHead":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col26')
define "BodyAbnormalSkin":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col27')
define "BodyAbnormalEar":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col28')
define "BodyAbnormalMouth":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col29')
define "BodyAbnormalThroat":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col30')
define "BodyAbnormalNeck":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col31')
define "BodyAbnormalChest":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col32')
define "BodyAbnormalHeartSound":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col33')
define "BodyAbnormalAbdomen":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col34')
define "BodyAbnormalLimbs":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col35')
define "BodyAbnormalGenitalia":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col36')
define "BodyAbnormalNeuro":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col37')
define "BodyAbnormalOther":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col38')

// 身體檢查其他子項 Col39-Col41
define "BodyAbnormalEye":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col39')
define "SoundResponse":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col40')
define "OralExam":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col41')

// ===============================================================
// A 題組 Col42-Col56 + Col95（§4-4-C-4）
// CPG §3-2-7 月齡分流: IC76 / Col1='1' / 1.5-2 歲（18-23 月）
// ===============================================================
define "IsAgeForGroupA":
  Coalesce(
    "ICCodeValue" = '76'
      and "DataFormatCode" = '1'
      and "AgeInMonths" >= 18
      and "AgeInMonths" < 24,
    false
  )

define function AGroupAnswer(lid String) returns String:
  if "IsAgeForGroupA" then GetQRAnswer("LatestQuestionnaireResponse", lid)
  else null

define "AGroupMotor":               // Col42 動作（總）
  AGroupAnswer('upload_prev_health_t57_Col42')
define "A1_HandStairs":             // Col43 A1 牽手上樓
  AGroupAnswer('upload_prev_health_t57_Col43')
define "A2_ClimbChair":             // Col44 A2 自爬椅子
  AGroupAnswer('upload_prev_health_t57_Col44')
define "AGroupLanguage":            // Col45 語言（總）
  AGroupAnswer('upload_prev_health_t57_Col45')
define "A3_FiveWords":              // Col46 A3 說 5 個單字
  AGroupAnswer('upload_prev_health_t57_Col46')
define "A4_PointBodyParts":         // Col47 A4 指身體部位
  AGroupAnswer('upload_prev_health_t57_Col47')
define "A5_FollowCommand":          // Col48 A5 聽從指令
  AGroupAnswer('upload_prev_health_t57_Col48')
define "A7_BodyExpression":         // Col49 A7 肢體表達
  AGroupAnswer('upload_prev_health_t57_Col49')
define "AGroupCognition":           // Col50 認知（總）
  AGroupAnswer('upload_prev_health_t57_Col50')
define "ACognitionItem":            // Col51 [待確認] 與 A4 重複
  AGroupAnswer('upload_prev_health_t57_Col51')
define "A9_SimilarObject":          // Col52 A9 相似物取代
  AGroupAnswer('upload_prev_health_t57_Col52')
define "AGroupSocialDev":           // Col53 / A6 社會發展（總）
  AGroupAnswer('upload_prev_health_t57_Col53')
define "A8_ImitateAdult":           // Col54 A8 模仿大人使用家裡用具
  AGroupAnswer('upload_prev_health_t57_Col54')
define "ASocialDevItem":            // Col55 用手指有趣的東西
  AGroupAnswer('upload_prev_health_t57_Col55')
define "AGroupOther":               // Col56 其他（總）
  AGroupAnswer('upload_prev_health_t57_Col56')

// A 題組額外 Col95 (A10 蹲下撿物)
define "A10_SquatPickup":
  AGroupAnswer('upload_prev_health_t57_Col95')

// A 題組其他說明
define "AOther":
  AGroupAnswer('upload_prev_health_t57_Col56Other')

// ===============================================================
// B 題組 Col57-Col73 + Col96-Col99（§4-4-C-5）
// CPG §3-2-7 月齡分流: IC79 / Col1='2' / 36-48 月（3-4 歲）
// ===============================================================
define "IsAgeForGroupB":
  Coalesce(
    "ICCodeValue" = '79'
      and "DataFormatCode" = '2'
      and "AgeInMonths" >= 36
      and "AgeInMonths" < 48,
    false
  )

define function BGroupAnswer(lid String) returns String:
  if "IsAgeForGroupB" then GetQRAnswer("LatestQuestionnaireResponse", lid)
  else null

define "BGroupMotor":               // Col57 動作（總）
  BGroupAnswer('upload_prev_health_t57_Col57')
define "B1_TwoFeetJump":            // Col58 B1 雙腳跳下
  BGroupAnswer('upload_prev_health_t57_Col58')
define "B4_DrawCircle":             // Col60 B4 畫圓
  BGroupAnswer('upload_prev_health_t57_Col60')
define "B6_UnbuttonClothes":        // Col61 B6 解扣脫衣
  BGroupAnswer('upload_prev_health_t57_Col61')
define "BGroupLanguage":            // Col62 語言（總）
  BGroupAnswer('upload_prev_health_t57_Col62')
define "B7_PronounUse":             // Col63 B7 代名詞使用
  BGroupAnswer('upload_prev_health_t57_Col63')
define "B9_ColorAndShape":          // Col67 B9 顏色與圖形
  BGroupAnswer('upload_prev_health_t57_Col67')
define "BGroupCognition":           // Col68 認知（總）
  BGroupAnswer('upload_prev_health_t57_Col68')
define "BGroupSocialDev":           // Col71 社會發展（總）
  BGroupAnswer('upload_prev_health_t57_Col71')
define "B5_UseToilet":              // Col72 B5 上廁所
  BGroupAnswer('upload_prev_health_t57_Col72')
define "BGroupOther":               // Col73 其他（總）
  BGroupAnswer('upload_prev_health_t57_Col73')

// B 題組額外 Col96-Col99
define "B2_RideTricycle":           // Col96 B2 踏三輪車
  BGroupAnswer('upload_prev_health_t57_Col96')
define "B3_SpoonEat":               // Col97 B3 用湯匙吃東西
  BGroupAnswer('upload_prev_health_t57_Col97')
define "B8_ObjectFunction":         // Col98 B8 物品功能
  BGroupAnswer('upload_prev_health_t57_Col98')
define "B10_QAResponse":            // Col99 B10 一問一答
  BGroupAnswer('upload_prev_health_t57_Col99')

// B 題組其他說明
define "BOther":
  BGroupAnswer('upload_prev_health_t57_Col73Other')

// ===============================================================
// C 題組 Col74-Col89 + Col100（§4-4-C-6）
// CPG §3-2-7 月齡分流: IC79 / Col1='2' / 48-84 月（4-7 歲含 84 月）
// ===============================================================
define "IsAgeForGroupC":
  Coalesce(
    "ICCodeValue" = '79'
      and "DataFormatCode" = '2'
      and "AgeInMonths" >= 48
      and "AgeInMonths" <= 84,
    false
  )

define function CGroupAnswer(lid String) returns String:
  if "IsAgeForGroupC" then GetQRAnswer("LatestQuestionnaireResponse", lid)
  else null

define "CGroupMotor":               // Col74 動作（總）
  CGroupAnswer('upload_prev_health_t57_Col74')
define "C1_StandOnOneLeg":          // Col75 C1 單腳站立
  CGroupAnswer('upload_prev_health_t57_Col75')
define "C2_StairOneFoot":           // Col76 C2 一腳一階上下樓梯
  CGroupAnswer('upload_prev_health_t57_Col76')
define "C3_UseScissors":            // Col77 C3 用剪刀
  CGroupAnswer('upload_prev_health_t57_Col77')
define "C5_DressButton":            // Col78 C5 穿衣扣釦
  CGroupAnswer('upload_prev_health_t57_Col78')
define "C7_ColorAndShape":          // Col79 C7 顏色與圖形
  CGroupAnswer('upload_prev_health_t57_Col79')
define "CGroupLanguage":            // Col80 語言（總）
  CGroupAnswer('upload_prev_health_t57_Col80')
define "C6_NormalExpression":       // Col83 C6 表達正常
  CGroupAnswer('upload_prev_health_t57_Col83')
define "C7_ColorAndShapeDup1":      // Col84 [待確認] 與 C7 重複
  CGroupAnswer('upload_prev_health_t57_Col84')
define "CGroupCognition":           // Col85 認知（總）
  CGroupAnswer('upload_prev_health_t57_Col85')
define "C7_CognitionItem":          // Col86 [待確認] 與 Col79/Col84 重複
  CGroupAnswer('upload_prev_health_t57_Col86')
define "CGroupSocialDev":           // Col87 社會發展（總）
  CGroupAnswer('upload_prev_health_t57_Col87')
define "C4_ImitateAdult":           // Col88 C4 扮演大人
  CGroupAnswer('upload_prev_health_t57_Col88')

// C 題組額外 Col100
define "C8_ContinuousCommand":      // Col100 C8 連續指令
  CGroupAnswer('upload_prev_health_t57_Col100')

// C 題組其他說明
define "COther":
  CGroupAnswer('upload_prev_health_t57_Col89Other')

// ===============================================================
// 表三結尾欄位 Col89, Col90-Col93, Col10Ref-Col14Ref（§4-4-C-7）
// ===============================================================

// Col89 發展狀況-其他總
define "DevAbnormalOther":
  GetQRAnswer("LatestQuestionnaireResponse", 'upload_prev_health_t57_Col89')

// Col90 健保卡就醫序號（Encounter.identifier.value）
define "EncounterIdentifier":
  First(
    "LatestEncounter".identifier I
      where I.system.value = 'https://nhi.gov.tw/fhir/identifier/nhi-order-code'
        and I.value is not null
      return I.value.value
  )

// Col91 醫事機構代碼 — 重用 OrganizationCode

// Col92 特殊紀載 — [待補] FHIR Path 不明確
define "SpecialRemark":
  null

// Col93 姓名（備用欄）— 重用 PatientName

// Col10Ref 身高百分位（參考）— [待補]
define "HeightPercentileRef":
  null

// Col12Ref 體重百分位（參考）
define "WeightPercentileRef":
  First(
    "EncounterObservations" O
      where exists (O.code.coding C where C.code.value = 'weight-percentile-ref')
      return ObsValueQuantity(O)
  )

// Col14Ref 頭圍百分位（參考）
define "HeadCircumferencePercentileRef":
  First(
    "EncounterObservations" O
      where exists (O.code.coding C where C.code.value = 'head-percentile-ref')
      return First(
        O.component Comp
          return (Comp.value as FHIR.Quantity).value.value
      )
  )

// ThirdId_2 衛生所代碼 — 重用 HealthCenterCode

// ===============================================================
// Summary Tuple (SDC populate 使用)
// key = Questionnaire item.linkId（甲方原樣，不變）
// value = CQL define 名稱（依 Guide §6-3 跨 CPG 標準命名）
// ===============================================================
define "Summary":
  Tuple {
    // --- 表一基本識別欄位（root level, §6-1-A）---
    TOKENID    : "TokenId",
    FuncDate   : "EncounterDate",
    Birthday   : "BirthDate",
    PersonalID : "PatientIdNumber",
    Name       : "PatientName",
    Sex        : "GenderCode",
    Phone1     : "HomePhone",
    City       : "City",
    Address    : "Address",
    Category   : "DevelopmentAbnormalCategory",
    ICCode     : "ICCodeValue",
    HospitalID : "OrganizationCode",

    // --- 表一發展題項 Col1-Col10 + ColExt ---
    Col1          : "QuestionItem1",
    Col2          : "QuestionItem2",
    Col3          : "QuestionItem3",
    Col4          : "QuestionItem4",
    Col5          : "QuestionItem5",
    Col6          : "QuestionItem6",
    Col7          : "QuestionItem7",
    Col7Content   : "OtherQuestionItemContent",
    Col8          : "QuestionItem8",
    Col9          : "QuestionItem9",
    Col10         : "QuestionItem10",
    ColExt        : "ExtendedQuestionItem",
    ColExtContent : "ExtendedQuestionContent",

    // --- 表二 group: new_visit_prev_health_t12346_*（§6-1-B）---
    new_visit_prev_health_t12346_AssessID             : "AssessmentCenterCode",
    new_visit_prev_health_t12346_HealthResult         : "HealthAssessmentResult",
    new_visit_prev_health_t12346_GrowResult           : "GrowthAssessmentResult",
    new_visit_prev_health_t12346_BodyResult           : "BodyExaminationResult",
    new_visit_prev_health_t12346_DevelopResult        : "DevelopmentAssessmentResult",
    new_visit_prev_health_t12346_GrowReason           : "GrowthAbnormalReason",
    new_visit_prev_health_t12346_BobyReason           : "BodyAbnormalReason",
    new_visit_prev_health_t12346_BodyGeneralReason    : "DevelopmentAbnormalReason",
    new_visit_prev_health_t12346_DevelopQuestionTimes : "DevelopmentQuestionTimes",
    new_visit_prev_health_t12346_Height               : "BodyHeight",
    new_visit_prev_health_t12346_Weight               : "BodyWeight",
    new_visit_prev_health_t12346_Head                 : "HeadCircumference",
    new_visit_prev_health_t12346_HeightPercent        : "HeightPercentile",
    new_visit_prev_health_t12346_WeightPercent        : "WeightPercentile",
    new_visit_prev_health_t12346_HeadPercent          : "HeadCircumferencePercentile",
    new_visit_prev_health_t12346_ThirdId              : "HealthCenterCode",
    new_visit_prev_health_t12346_IsDepend             : "IsDependentVisit",
    new_visit_prev_health_t12346_DependID             : "DependentPersonId",
    new_visit_prev_health_t12346_IsPremature          : "IsPremature",
    new_visit_prev_health_t12346_PrematureDate        : "ExpectedDeliveryDate",
    new_visit_prev_health_t12346_TiSu                 : "BirthOrder",

    // --- 表三 group: upload_prev_health_t57_*（§6-1-C）---
    upload_prev_health_t57_Address  : "Address",
    upload_prev_health_t57_Phone1   : "HomePhone",
    upload_prev_health_t57_Phone2   : "MobilePhone",
    upload_prev_health_t57_Col1     : "DataFormatCode",
    upload_prev_health_t57_Col2     : "EncounterDate",
    upload_prev_health_t57_Col3     : "GenderCode",
    upload_prev_health_t57_Col4     : "PatientIdNumber",
    upload_prev_health_t57_Col5     : "BirthDate",
    upload_prev_health_t57_Col6     : "AgeInYears",
    upload_prev_health_t57_Col7     : "AgeInMonthsMod12",
    upload_prev_health_t57_Col8     : "City",
    upload_prev_health_t57_Col9     : "BodyHeight",
    upload_prev_health_t57_Col10    : "HeightPercentile",
    upload_prev_health_t57_Col11    : "BodyWeight",
    upload_prev_health_t57_Col12    : "WeightPercentile",
    upload_prev_health_t57_Col13    : "HeadCircumference",
    upload_prev_health_t57_Col14    : "HeadCircumferencePercentile",
    upload_prev_health_t57_Col15    : "Table3_HealthAssessmentResult",
    upload_prev_health_t57_Col16    : "HasGrowthAbnormality",
    upload_prev_health_t57_Col17    : "GrowthFollowupRecommendation",
    upload_prev_health_t57_Col18    : "HasBodyAbnormality",
    upload_prev_health_t57_Col19    : "BodyFollowupRecommendation",
    upload_prev_health_t57_Col20    : "HasDevelopmentAbnormality",
    upload_prev_health_t57_Col21    : "DevelopmentFollowupRecommendation",
    upload_prev_health_t57_Col22    : "GrowthAbnormalHeight",
    upload_prev_health_t57_Col23    : "GrowthAbnormalWeight",
    upload_prev_health_t57_Col24    : "GrowthAbnormalHead",
    upload_prev_health_t57_Col25    : "BodyAbnormalGeneral",
    upload_prev_health_t57_Col26    : "BodyAbnormalHead",
    upload_prev_health_t57_Col27    : "BodyAbnormalSkin",
    upload_prev_health_t57_Col28    : "BodyAbnormalEar",
    upload_prev_health_t57_Col29    : "BodyAbnormalMouth",
    upload_prev_health_t57_Col30    : "BodyAbnormalThroat",
    upload_prev_health_t57_Col31    : "BodyAbnormalNeck",
    upload_prev_health_t57_Col32    : "BodyAbnormalChest",
    upload_prev_health_t57_Col33    : "BodyAbnormalHeartSound",
    upload_prev_health_t57_Col34    : "BodyAbnormalAbdomen",
    upload_prev_health_t57_Col35    : "BodyAbnormalLimbs",
    upload_prev_health_t57_Col36    : "BodyAbnormalGenitalia",
    upload_prev_health_t57_Col37    : "BodyAbnormalNeuro",
    upload_prev_health_t57_Col38    : "BodyAbnormalOther",
    upload_prev_health_t57_Col39    : "BodyAbnormalEye",
    upload_prev_health_t57_Col40    : "SoundResponse",
    upload_prev_health_t57_Col41    : "OralExam",
    upload_prev_health_t57_Col42    : "AGroupMotor",
    upload_prev_health_t57_Col43    : "A1_HandStairs",
    upload_prev_health_t57_Col44    : "A2_ClimbChair",
    upload_prev_health_t57_Col45    : "AGroupLanguage",
    upload_prev_health_t57_Col46    : "A3_FiveWords",
    upload_prev_health_t57_Col47    : "A4_PointBodyParts",
    upload_prev_health_t57_Col48    : "A5_FollowCommand",
    upload_prev_health_t57_Col49    : "A7_BodyExpression",
    upload_prev_health_t57_Col50    : "AGroupCognition",
    upload_prev_health_t57_Col51    : "ACognitionItem",
    upload_prev_health_t57_Col52    : "A9_SimilarObject",
    upload_prev_health_t57_Col53    : "AGroupSocialDev",
    upload_prev_health_t57_Col54    : "A8_ImitateAdult",
    upload_prev_health_t57_Col55    : "ASocialDevItem",
    upload_prev_health_t57_Col56    : "AGroupOther",
    upload_prev_health_t57_Col57    : "BGroupMotor",
    upload_prev_health_t57_Col58    : "B1_TwoFeetJump",
    upload_prev_health_t57_Col60    : "B4_DrawCircle",
    upload_prev_health_t57_Col61    : "B6_UnbuttonClothes",
    upload_prev_health_t57_Col62    : "BGroupLanguage",
    upload_prev_health_t57_Col63    : "B7_PronounUse",
    upload_prev_health_t57_Col67    : "B9_ColorAndShape",
    upload_prev_health_t57_Col68    : "BGroupCognition",
    upload_prev_health_t57_Col71    : "BGroupSocialDev",
    upload_prev_health_t57_Col72    : "B5_UseToilet",
    upload_prev_health_t57_Col73    : "BGroupOther",
    upload_prev_health_t57_Col74    : "CGroupMotor",
    upload_prev_health_t57_Col75    : "C1_StandOnOneLeg",
    upload_prev_health_t57_Col76    : "C2_StairOneFoot",
    upload_prev_health_t57_Col77    : "C3_UseScissors",
    upload_prev_health_t57_Col78    : "C5_DressButton",
    upload_prev_health_t57_Col79    : "C7_ColorAndShape",
    upload_prev_health_t57_Col80    : "CGroupLanguage",
    upload_prev_health_t57_Col83    : "C6_NormalExpression",
    upload_prev_health_t57_Col84    : "C7_ColorAndShapeDup1",
    upload_prev_health_t57_Col85    : "CGroupCognition",
    upload_prev_health_t57_Col86    : "C7_CognitionItem",
    upload_prev_health_t57_Col87    : "CGroupSocialDev",
    upload_prev_health_t57_Col88    : "C4_ImitateAdult",
    upload_prev_health_t57_Col89    : "DevAbnormalOther",
    upload_prev_health_t57_Col90    : "EncounterIdentifier",
    upload_prev_health_t57_Col91    : "OrganizationCode",
    upload_prev_health_t57_Col92    : "SpecialRemark",
    upload_prev_health_t57_Col93    : "PatientName",
    upload_prev_health_t57_Col95    : "A10_SquatPickup",
    upload_prev_health_t57_Col96    : "B2_RideTricycle",
    upload_prev_health_t57_Col97    : "B3_SpoonEat",
    upload_prev_health_t57_Col98    : "B8_ObjectFunction",
    upload_prev_health_t57_Col99    : "B10_QAResponse",
    upload_prev_health_t57_Col100   : "C8_ContinuousCommand",
    upload_prev_health_t57_Col101   : "IsPremature",
    upload_prev_health_t57_Col102   : "ExpectedDeliveryDate",
    upload_prev_health_t57_Col10Ref : "HeightPercentileRef",
    upload_prev_health_t57_Col12Ref : "WeightPercentileRef",
    upload_prev_health_t57_Col14Ref : "HeadCircumferencePercentileRef",
    upload_prev_health_t57_ThirdId_2 : "HealthCenterCode",
    upload_prev_health_t57_Col56Other : "AOther",
    upload_prev_health_t57_Col73Other : "BOther",
    upload_prev_health_t57_Col89Other : "COther",

    // --- IC20 聽力篩檢專用「健保卡類別」（CPG §3-2-3 註）---
    HearingScreeningCardType : "HearingScreeningCardType"
  }
