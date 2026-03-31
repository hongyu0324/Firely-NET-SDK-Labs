library AdultPreventiveHealthCheck version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1'

codesystem "LOINC": 'http://loinc.org'
codesystem "ICD-10": 'http://hl7.org/fhir/sid/icd-10'

code "Height": '8302-2' from "LOINC" display '身高'
code "Weight": '29463-7' from "LOINC" display '體重'
code "BMI": '39156-5' from "LOINC" display 'BMI'
code "WaistCircumference": '56115-9' from "LOINC" display '腰圍'
code "SystolicBP": '8480-6' from "LOINC" display '收縮壓'
code "DiastolicBP": '8462-4' from "LOINC" display '舒張壓'
code "FastingGlucose": '1558-6' from "LOINC" display '飯前血糖'
code "TotalCholesterol": '2093-3' from "LOINC" display '總膽固醇'
code "SmokingStatus": '72166-2' from "LOINC" display '吸菸狀態'
code "AlcoholUse": '74013-4' from "LOINC" display '飲酒狀態'
code "BetelNutUse": 'BETEL-USE' from "LOINC" display '檳榔使用狀態'
code "AC-EXAM": 'AC-EXAM' from "LOINC" display '成人健檢'
code "Hypertension": 'I10' from "ICD-10" display '高血壓'
code "Diabetes": 'E11' from "ICD-10" display '第二型糖尿病'

context Patient

define PatientAge:
  AgeInYears()

define Gender:
  Patient.gender

define LastAdultCheckEncounter:
  Last(
    [Encounter] E
      where E.status = 'finished'
        and E.type.coding contains "AC-EXAM"
      sort by end of period
  )

define function LatestObservation(codeValue Code):
  Last(
    [Observation] O
      where O.status in { 'final', 'amended' }
        and O.code.coding contains codeValue
      sort by effective descending
  )

define HeightObservation:
  LatestObservation("Height")

define WeightObservation:
  LatestObservation("Weight")

define BMIObservation:
  LatestObservation("BMI")

define WaistCircumferenceObservation:
  LatestObservation("WaistCircumference")

define SystolicBPObservation:
  LatestObservation("SystolicBP")

define DiastolicBPObservation:
  LatestObservation("DiastolicBP")

define FastingGlucoseObservation:
  LatestObservation("FastingGlucose")

define TotalCholesterolObservation:
  LatestObservation("TotalCholesterol")

define SmokingStatusObservation:
  LatestObservation("SmokingStatus")

define AlcoholUseObservation:
  LatestObservation("AlcoholUse")

define BetelNutUseObservation:
  LatestObservation("BetelNutUse")

define HasHypertension:
  exists (
    [Condition] C
      where C.code.coding contains "Hypertension"
        and C.clinicalStatus.coding.code contains 'active'
  )

define HasDiabetes:
  exists (
    [Condition] C
      where C.code.coding contains "Diabetes"
        and C.clinicalStatus.coding.code contains 'active'
  )
