library MetabolicSyndromeLogic version '1.0.0'
using FHIR version '4.0.1'
include FHIRHelpers version '4.0.1'

// 1. 定義代碼系統與代碼 (Terminology) [1]
codesystem "LOINC": 'http://loinc.org'

code "WaistCircumference": '21482-5' from "LOINC" display '腰圍'
code "FastingGlucose": '1558-6' from "LOINC" display '飯前血糖'
code "Triglycerides": '2571-8' from "LOINC" display '三酸甘油酯'
code "HDL_Cholesterol": '2085-9' from "LOINC" display '高密度脂蛋白膽固醇'
code "BloodPressure": '85354-9' from "LOINC" display '血壓組合'
code "SystolicBP": '8480-6' from "LOINC" display '收縮壓'
code "DiastolicBP": '8462-4' from "LOINC" display '舒張壓'

context Patient

// 2. 抓取最新且有效的量測紀錄 (Most Recent & Valid Observation)
// 透過排序有效日期 (effective) 並過濾狀態來處理多筆資料
define "LatestWaist": 
  First(
    [Observation: "WaistCircumference"] O
      where O.status in { 'final', 'amended' }
      sort by effective descending
  )

define "LatestWaistValue":  
  (("LatestWaist".value) as Quantity).value

define "LatestBP":
  First([Observation: "BloodPressure"] BP 
    where BP.status in { 'final', 'amended' } 
    sort by effective descending)

define "LatestSystolicBPValue":
  (First("LatestBP".component C where C.code ~ "SystolicBP").value as Quantity).value

define "LatestDiastolicBPValue":  
  (First("LatestBP".component C where C.code ~ "DiastolicBP").value as Quantity).value

define "LatestGlucose":
  First(
    [Observation: "FastingGlucose"] O 
    where O.status in { 'final', 'amended' } 
    sort by effective descending
  )

define "LatestGlucoseValue":  
  (("LatestGlucose".value) as Quantity).value


define "LatestTG":
  First(
    [Observation: "Triglycerides"] O 
    where O.status in { 'final', 'amended' } 
    sort by effective descending
  )

define "LatestTGValue": 
  (("LatestTG".value) as Quantity).value

define "LatestHDL":
  First(
    [Observation: "HDL_Cholesterol"] O 
    where O.status in { 'final', 'amended' } 
    sort by effective descending
  )

define "LatestHDLValue": 
  (("LatestHDL".value) as Quantity).value

// 3. 各別指標異常判定邏輯 (Indicator Assessment) [1]

// 指標 1：腰圍異常 (男 >= 90cm, 女 >= 80cm) [1]
define "Is_Abnormal_Waist":  
  case 
    when Patient.gender = 'male' then "LatestWaist".value as Quantity >= 90 'cm'
    when Patient.gender = 'female' then "LatestWaist".value as Quantity >= 80 'cm'
    else false
  end

// 指標 2：血壓異常 (收縮壓 >= 130 或 舒張壓 >= 85 mmHg) [1]
define "Is_Abnormal_BP":
  exists ("LatestBP".component C where C.code ~ "SystolicBP" and C.value as Quantity >= 130 'mm[Hg]')
  or exists ("LatestBP".component C where C.code ~ "DiastolicBP" and C.value as Quantity >= 85 'mm[Hg]')

// 指標 3：飯前血糖異常 (>= 100 mg/dL) [1]
define "Is_Abnormal_Glucose":
  "LatestGlucose".value as Quantity >= 100 'mg/dL'

// 指標 4：三酸甘油酯異常 (>= 150 mg/dL) [1]
define "Is_Abnormal_TG":
  "LatestTG".value as Quantity >= 150 'mg/dL'

// 指標 5：高密度脂蛋白膽固醇異常 (男 < 40, 女 < 50 mg/dL) [1]
define "Is_Abnormal_HDL":
  case 
    when Patient.gender = 'male' then "LatestHDL".value as Quantity < 40 'mg/dL'
    when Patient.gender = 'female' then "LatestHDL".value as Quantity < 50 'mg/dL'
    else false
  end

// 4. 代謝症候群綜合判定 (Final Assessment) [1, 2]

// 統計符合異常指標的項數
define "Abnormal_Count":
  (Count({
    if "Is_Abnormal_Waist" then 1 else null,
    if "Is_Abnormal_BP" then 1 else null,
    if "Is_Abnormal_Glucose" then 1 else null,
    if "Is_Abnormal_TG" then 1 else null,
    if "Is_Abnormal_HDL" then 1 else null
  })) as Integer

// 若符合三項(含)以上，即判定為代謝症候群 [1, 2]
define "Is_Metabolic_Syndrome": 
  "Abnormal_Count" >= 3