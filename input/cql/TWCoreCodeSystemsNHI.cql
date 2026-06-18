/*
 * Library : TWCore_CodeSystems_NHI
 * Title   : TW NHI 公衛表單共用 CodeSystem / LOINC / SNOMED 定義
 * Version : 1.2.0
 * Date    : 2026-05-20
 *
 * 資料來源：
 *   - 1150305_代碼系統.ods  →  頁籤「#代碼系統_檢驗檢查LOINC」
 *     （參考 MD：01_source\代碼檔相關資料\代碼系統_檢驗檢查LOINC.MD）
 *   - 附表三《特約醫事服務機構上傳檢驗（查）結果...格式說明（114-01-01 實施）》
 *     （參考 MD：01_source\代碼檔相關資料\附表三_檢驗查結果上傳項目.MD）
 *   - CodeSystem成人健檢MAPPING_Code_1140522.pdf
 *
 * 用途：
 *   集中定義所有公衛表單 CQL 所需的 CodeSystem 與 LOINC / SNOMED code。
 *   各表單 CQL 透過 include 引用，不需重複宣告。
 *
 * 引用方式：
 *   include TWCore_CodeSystems_NHI version '1.2.0' called CS
 *
 * 使用範例：
 *   exists (O.code.coding Co where Co.code.value in CS."肌酸酐血清 LOINC Codes")
 *   exists (O.code.coding Co where Co.code.value = CS."血糖 空腹 LOINC")
 *
 * 命名慣例：
 *   - 單一 LOINC code → define "{中文名稱} LOINC" : '...'
 *   - 多個同類 LOINC  → define "{中文名稱} LOINC Codes" : { '...', '...' }
 *   - SNOMED code     → define "{中文名稱} SNOMED" : '...'
 *
 * 修正歷程：
 *   - v1.0.0 (2026-05): 初版
 *   - v1.1.0 (2026-05-20): 補入 MD 對照表標為「建議對應項目」之代碼：
 *       - NHI 08002C「白血球計數 LOINC Codes」+ '6690-2'
 *       - NHI 09025C「AST GOT LOINC Codes」+ '1920-8'
 *       - NHI 09029C「總膽紅素 LOINC Codes」+ '1975-2'
 *     上述 3 筆係 CPG-13 §2-2 結核檢驗報告所需，
 *     由 01_source\代碼檔相關資料\代碼系統_檢驗檢查LOINC.MD 確證。
 *   - v1.2.0 (2026-05-20): 依附表三晉升 CPG-13 §2-2 中 3 個通用代碼進 TWCore，
 *     並擴充 1 個既有 list：
 *       - 新增 NHI 09027C「ALP LOINC Codes」（鹼性磷酯酶）= { '6768-6' }
 *       - 新增 NHI 09002C「BUN 尿素氮 LOINC Codes」= { '3094-0' }
 *       - 新增 NHI 09005C/09140C「血糖 LOINC Codes」= { '2345-7', '17865-7' }
 *       - 擴充「腎絲球過濾率 LOINC Codes」+ '62238-1'（CPG-13 §2-2 eGFR）
 *     上述均符合「2+ 表單會用」之晉升準則；NHI 由附表三（114-01-01）驗證。
 *     命名統一採 list 形式（與 "ALT GPT LOINC Codes" 等既有風格一致），
 *     引用端以 `in` 比對，避免單值/多值混用造成的型別推導歧義。
 */

library TWCoreCodeSystemsNHI version '1.2.0'

// ⚠️ 此 Library 只含 codesystem 宣告與 List<String> define，
//    不需要也不應加入 context Patient。
using FHIR version '4.0.1'

// ═══════════════════════════════════════════════════════════════════════════════
// 一、Code Systems 宣告
// ═══════════════════════════════════════════════════════════════════════════════

// 國際標準
codesystem "LOINC"   : 'http://loinc.org'
codesystem "SNOMED"  : 'http://snomed.info/sct'
codesystem "ICD10CM" : 'http://hl7.org/fhir/sid/icd-10-cm'

// FHIR 標準
codesystem "ObservationStatus"    : 'http://hl7.org/fhir/observation-status'
codesystem "ConditionClinical"    : 'http://terminology.hl7.org/CodeSystem/condition-clinical'
codesystem "AdministrativeGender" : 'http://hl7.org/fhir/administrative-gender'

// TW Core IG
codesystem "TW NHI Order"         : 'http://nhi.gov.tw/fhir/CodeSystem/nhi-order-code'
codesystem "TW ICD10CM 2021"      : 'http://twcore.mohw.gov.tw/ig/twcore/CodeSystem/icd-10-cm-2021-tw'
codesystem "TW NID System"        : 'http://hl7.org/fhir/sid/tw-nid'

// ═══════════════════════════════════════════════════════════════════════════════
// 二、公衛表單醫令代碼（NHI Order Codes）
// ═══════════════════════════════════════════════════════════════════════════════

// ── 口腔黏膜篩檢 ──────────────────────────────────────────────────────────────
define "口腔篩檢 成人 醫令":            '95'
define "口腔篩檢 原住民 醫令":          '97'
define "口腔篩檢 醫令 Codes":           { '95', '97' }

// ── 糞便潛血 ─────────────────────────────────────────────────────────────────
define "糞便潛血 醫令":                 '85'

// ── 成人預防保健 ──────────────────────────────────────────────────────────────
define "成人健檢 第一期 醫令":          '01'
define "成人健檢 第二期 醫令":          '02'
define "成人健檢 醫令 Codes":           { '01', '02' }

// ── 兒童預防保健 ──────────────────────────────────────────────────────────────
define "兒童健檢 醫令":                 '04'

// ── 婦女乳房攝影 ──────────────────────────────────────────────────────────────
define "乳房攝影 醫令":                 '08'

// ── 子宮頸抹片 ────────────────────────────────────────────────────────────────
define "子宮頸抹片 醫令":               '09'

// ═══════════════════════════════════════════════════════════════════════════════
// 三、成人健檢 LOINC Codes（來源：CodeSystem成人健檢MAPPING_Code_1140522.pdf）
// ═══════════════════════════════════════════════════════════════════════════════

// ── 身體測量 ─────────────────────────────────────────────────────────────────
define "身高 LOINC"                   : '8302-2'
define "體重 LOINC"                   : '29463-7'
define "BMI LOINC"                    : '39156-5'
define "血壓 LOINC"                   : '85354-9'
define "腰圍 LOINC"                   : '56117-5'

// ── 生活習慣 ─────────────────────────────────────────────────────────────────
define "吸菸狀態 LOINC"               : '72166-2'
define "喝酒 SNOMED"                  : '160573003'
define "嚼檳榔 SNOMED"               : '227491007'
define "運動 SNOMED"                  : '128976003'

// ── 憂鬱檢測 ─────────────────────────────────────────────────────────────────
define "憂鬱檢測 BDI LOINC"           : '89210-9'
define "憂鬱檢測 第一題 LOINC"        : '44255-8'
define "憂鬱檢測 第二題 LOINC"        : '44250-9'

// ── 腎功能期別 ────────────────────────────────────────────────────────────────
define "腎功能檢查期別 LOINC"         : '88240-7'

// ── 健康諮詢（SNOMED）──────────────────────────────────────────────────────────
define "健康諮詢 戒煙 SNOMED"         : '225323000'
define "健康諮詢 節酒 SNOMED"         : '281078001'
define "健康諮詢 戒檳榔 SNOMED"       : '51011006'
define "健康諮詢 規律運動 SNOMED"     : '410289001'
define "健康諮詢 維持正常體重 SNOMED" : '388970003'
define "健康諮詢 健康飲食 SNOMED"     : '424753004'
define "健康諮詢 事故傷害預防 SNOMED" : '710737001'
define "健康諮詢 口腔保健 SNOMED"     : '58707002'
define "健康諮詢 腎病衛教 SNOMED"     : '720510004'
define "健康諮詢 慢性疾病風險 SNOMED" : '423167009'
define "B C型肝炎檢查 SNOMED"         : '444266007'

// ── 尿液 ──────────────────────────────────────────────────────────────────────
define "尿蛋白 LOINC"                 : '35663-4'

// ── 血糖 ──────────────────────────────────────────────────────────────────────
define "血糖 空腹 LOINC"              : '17865-7'

// ── 血脂 ──────────────────────────────────────────────────────────────────────
define "總膽固醇 LOINC"               : '2093-3'
define "三酸甘油脂 LOINC"             : '2571-8'
define "LDL膽固醇 LOINC"              : '2089-1'
define "HDL膽固醇 LOINC"              : '2085-9'

// ── 肝功能（單一最常用代碼） ────────────────────────────────────────────────
define "GOT AST 主要 LOINC"           : '1920-8'
define "GPT ALT 主要 LOINC"           : '1742-6'

// ── 腎功能（單一最常用代碼） ────────────────────────────────────────────────
define "肌酸酐 血清 主要 LOINC"       : '2160-0'
define "腎絲球過濾率 Panel LOINC"     : '45066-8'
define "腎絲球過濾率 LOINC"           : '33914-3'

// ── 肝炎（單一代碼） ────────────────────────────────────────────────────────
define "B型肝炎表面抗原 主要 LOINC"   : '5195-3'
define "C型肝炎病毒抗體 主要 LOINC"   : '12128-1'

// ── 尿酸 ──────────────────────────────────────────────────────────────────────
define "尿酸 LOINC"                   : '3084-1'

// ── 慢性疾病風險值（SNOMED）──────────────────────────────────────────────────
define "冠心病 風險 SNOMED"           : '53741008'
define "糖尿病 風險 SNOMED"           : '73211009'
define "高血壓 風險 SNOMED"           : '38341003'
define "腦中風 風險 SNOMED"           : '230690007'
define "心血管疾病 風險 SNOMED"       : '49601007'

// ═══════════════════════════════════════════════════════════════════════════════
// 四、NHI 檢驗代碼 → LOINC 代碼集合
//     （來源：1150305_代碼系統.ods #代碼系統_檢驗檢查LOINC 頁籤）
//     同性質 LOINC 歸為一組，供 CQL where 條件使用
// ═══════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// 【血液常規】
// ─────────────────────────────────────────────────────────────────────────────

// 白血球計數（NHI: 08002C）
// 包含血液、尿液、各體腔液、骨髓等來源
define "白血球計數 LOINC Codes" : {
  '6690-2',    // Leukocytes [#/volume] in Blood by Automated count（MD 標記「建議對應項目」/ v1.1.0）
  '26464-8',   // Leukocytes in Bld
  '49498-9',   // Leukocytes in Bld
  '804-5', '805-2', '806-0', '807-8', '808-6', '809-4', '810-2', '813-6', '814-4',
  '33028-2',   // Leukocytes in Bld^BPU
  '100849-9',  // Leukocytes in Amnio fld
  '13349-6',   // Leukocytes in Stool
  '14373-5',   // Leukocytes in Gast fld
  '14810-6',   // Leukocytes in Bronchial
  '14811-4',   // Leukocytes in Pericard fld
  '20408-1', '24122-4', '30405-5', '51487-7', '58805-3', '63555-7', // Urine
  '26465-5',   // Leukocytes in CSF
  '26466-3', '57845-0', // Body fld
  '26467-1', '62251-4', // Plr fld
  '26468-9',   // Periton fld
  '26469-7',   // Synv fld
  '30401-4',   // Bronchial
  '30402-2',   // Gast fld
  '30403-0',   // Pericard fld
  '30404-8',   // Stool
  '33765-9',   // BPU platelet pheresis
  '40533-2', '49928-5', '99775-9', // Dial fld prt
  '47281-1',   // BldCo
  '53518-7', '68368-0', '57847-6', // Dial fld
  '57846-8',   // Pericard fld
  '62239-9',   // Bld^Fetus
  '68434-0',   // Vitr fld
  '72348-6',   // Prostatic fld
  '82587-7',   // Bone mar
  '92635-2',   // Bld.buffy coat
  '95218-4',   // Stem cell product
  '98020-1',   // Respiratory.lower
  '99051-5', '99776-7', // BAL
  '10579-1', '811-0', '812-8' // Semen (FERT)
}

// 血色素（NHI: 08003C）
define "血色素 LOINC Codes" : {
  '718-7',     // Hemoglobin in Bld (最常用)
  '20509-6',   // Hemoglobin in Bld
  '55782-7',   // Hemoglobin in Bld
  '59260-0',   // Hemoglobin in Bld
  '97556-5',   // Hemoglobin in BldC (CHEM class)
  '14775-1',   // BldA
  '30313-1', '75928-2', '93846-4', // BldA
  '30350-3', '76769-9', // BldV
  '30351-1', '76768-1', // BldMV
  '30352-9',   // BldC
  '30353-7',   // BldCoV
  '30354-5',   // BldCoA
  '33025-8', '33026-6', // BldCo
  '33509-1', '33517-4', // Body fld
  '34618-9',   // XXX
  '40719-7',   // BldCo
  '42810-2', '71694-4', '73895-5', // Retic
  '48035-0',   // CSF
  '49137-3', '50559-4', '57751-0', '726-0', // Urine
  '54289-4',   // Bld^BPU
  '61180-6',   // Bld^Fetus
  '69950-4',   // Pericard fld
  '97550-8', '97555-7', // BldCV
  '24360-0'    // Hemoglobin & Hematocrit panel
}

// 血小板（NHI: 08006C）
define "血小板 LOINC Codes" : {
  '777-3',     // Platelets in Bld (最常用)
  '778-1',     // Platelets in Bld
  '26515-7',   // Platelets in Bld
  '49497-1',   // Platelets in Bld
  '79427-1',   // Platelets in Bld
  '97995-5',   // Platelets in Bld
  '13056-7',   // Plas
  '13057-5',   // Dial fld
  '40574-6',   // Body fld
  '47284-5', '55802-3', // BldCo
  '62244-9',   // Bld^Fetus
  '74464-9',   // BldC
  '74775-8',   // PRP
  '11126-0'    // Bone mar
}

// 白血球分類計數（NHI: 08013C）
define "白血球分類計數 LOINC Codes" : {
  '57021-8',   // CBC W Auto Differential panel
  '57022-6',   // CBC W Reflex Manual Differential panel
  '57782-5',   // CBC W Ordered Manual Differential panel
  '24318-8',   // Manual Differential panel
  '69738-3',   // Differential panel, method unspecified
  '69742-5'    // CBC W Differential panel, method unspecified
}

// 白血球分類個別項目
define "嗜中性球 分葉 LOINC"    : '26505-8'
define "嗜中性球 桿狀 LOINC"    : '26508-2'
define "嗜中性球 總 LOINC"      : '26511-6'
define "淋巴球 LOINC"           : '26478-8'
define "單核球 LOINC"           : '26485-3'
define "嗜酸性球 LOINC"         : '26450-7'
define "嗜鹼性球 LOINC"         : '30180-4'
define "芽細胞 LOINC"           : '26446-5'
define "前骨髓球 LOINC"         : '26524-9'
define "骨髓球 LOINC"           : '26498-6'
define "後骨髓球 LOINC"         : '28541-1'
define "有核紅血球 LOINC"       : '34200-6'
define "異型淋巴球 LOINC"       : '30413-9'
define "漿細胞 LOINC"           : '13047-6'
define "前淋巴球 LOINC"         : '30465-9'
define "前單核球 LOINC"         : '30466-7'

// ─────────────────────────────────────────────────────────────────────────────
// 【生化 - 肝功能】
// ─────────────────────────────────────────────────────────────────────────────

// AST / GOT（NHI: 09025C）
define "AST GOT LOINC Codes" : {
  '1920-8',    // AST [Enzymatic activity/volume] in Ser/Plas（MD 標記「建議對應項目」/ v1.1.0）
  '27344-1',   // AST in Ser/Plas (推薦優先使用)
  '30239-8',   // AST in Ser/Plas
  '44786-2',   // AST in Ser/Plas
  '88112-8',   // AST in Ser/Plas
  '96587-1',   // AST in Bld.dot
  '14409-7',   // Plr fld
  '14410-5',   // Periton fld
  '14411-3',   // Synv fld
  '14412-1',   // Gast fld
  '14413-9',   // Urine
  '14414-7',   // Dial fld
  '16412-9',   // RBC
  '1919-0',    // Body fld
  '43822-6',   // Body fld
  '100739-2', '48136-6', // AST.macromolecular in Ser/Plas
  '54500-4'    // AST.macromolecular/AST.total ratio
}

// ALT / GPT（NHI: 09026C）
define "ALT GPT LOINC Codes" : {
  '1742-6',    // ALT in Ser/Plas (推薦優先使用)
  '1743-4',    // ALT in Ser/Plas
  '1744-2',    // ALT in Ser/Plas
  '44785-4',   // ALT in Ser/Plas
  '76625-3',   // ALT in Bld
  '77144-4',   // ALT in Ser/Plas/Bld
  '96586-3',   // ALT in Bld.dot
  '16324-6',   // ALT in RBC
  '16325-3',   // ALT/AST ratio
  '1741-8',    // Amnio fld
  '25302-1',   // Body fld
  '50168-4',   // Dial fld
  '54491-6',   // Periton fld
  '54492-4',   // Plr fld
  '100738-4', '48134-1' // ALT.macromolecular
}

// 乳酸脫氫酶 LDH（NHI: 09033C）
define "LDH LOINC Codes" : {
  '14804-9',   // LDH in Ser/Plas (推薦優先使用)
  '14805-6',   // LDH in Ser/Plas
  '2532-0',    // LDH in Ser/Plas
  '32324-6',   // LDH in XXX
  '42929-0',   // LDH panel in Ser/Plas
  '100742-6',  // LDH.macromolecular
  '11053-6',   // RBC
  '14403-0',   // Gast fld
  '14803-1',   // Body fld
  '17041-5',   // Urine
  '47678-8', '47863-6', // Urine
  '2527-0',    // Amnio fld
  '49279-3',   // LDH isoenzymes
  '57664-5',   // Semen
  '60017-1',   // Body fld
  '60018-9', '60019-7', // Pericard fld
  '60020-5',   // Periton fld
  '60021-3', '60022-1', // Plr fld
  '60023-9', '60024-7', // CSF
  '68387-0',   // Periton fld
  '68452-2', '68453-0', // Synv fld
  '81430-1',   // Dial fld prt
  '19248-4',   // LDH 2
  '2546-0'     // LDH 4
}

// 白蛋白（NHI: 09038C）
define "白蛋白 LOINC Codes" : {
  '1751-7',    // Albumin in Ser/Plas (推薦優先使用)
  '54347-0',   // Albumin in Ser/Plas
  '61151-7', '61152-5', '62234-0', '62235-7', // Ser/Plas
  '77148-5',   // Ser/Plas/Bld
  '76631-1',   // Bld
  '1745-9',    // Amnio fld
  '1746-7',    // CSF
  '43711-1', '76480-3', // CSF
  '1747-5', '43212-0', '43713-7', // Body fld
  '1748-3',    // Plr fld
  '1749-1',    // Periton fld
  '51693-0',   // Pericard fld
  '1750-9', '10558-5', // Semen
  '1752-5',    // Synv fld
  '1753-3', '1754-1', '1755-8', '21059-1', '29946-1', '49002-9', // Urine
  '50949-7', '51190-7', '54346-2', '61195-4', '61196-2', '77940-5', // Urine
  '40599-3',   // Dial fld prt
  '32293-3'    // XXX
}

// 總膽紅素（NHI: 09029C）
define "總膽紅素 LOINC Codes" : {
  '1975-2',    // Bilirubin.total [Mass/volume] in Ser/Plas（MD 標記「建議對應項目」/ v1.1.0）
  '14631-6',   // Bilirubin in Ser/Plas (推薦優先使用)
  '42719-5',   // Bilirubin in Bld
  '54363-7',   // Bilirubin in Bld
  '59827-6',   // BldA
  '59828-4',   // BldV
  '77137-8',   // Ser/Plas/Bld
  '89871-8',   // BldV
  '89872-6',   // BldA
  '97770-2',   // BldC
  '20505-4', '41016-7', '44033-9', '50551-1', '53327-3', '68367-2', '70199-5', // Urine
  '12476-8', '13877-6', '27198-1', '43887-9', '47225-8', '72925-1', // Amnio fld
  '14420-4',   // Dial fld
  '14421-2',   // Plr fld
  '14422-0', '39461-9', // Periton fld
  '14423-8',   // Synv fld
  '14424-6',   // Gast fld
  '1976-0', '59166-9', // Stool
  '29767-1', '43824-2', // Body fld
  '32303-0', '33870-7', '38250-7', // XXX
  '47994-9', '48624-1', // BldCo
  '49763-6',   // Pericard fld
  '53415-6', '74906-9', // CSF
  '54362-9'    // Dial fld
}

// 直接膽紅素（NHI: 09030C）
define "直接膽紅素 LOINC Codes" : {
  '14629-0',   // Bilirubin.glucuronidated+albumin bound in Ser/Plas (推薦)
  '43820-0',   // Ser/Plas
  '48623-3',   // BldCo
  '14152-3', '25564-6', // Body fld
  '56905-3',   // Plr fld
  '56906-1'    // Periton fld
}

// 直接及總膽紅素比值（NHI: 09138C）
define "膽紅素比值 LOINC"     : '35672-5'
define "膽紅素比值 Panel LOINC" : '34543-9'

// ─────────────────────────────────────────────────────────────────────────────
// 【生化 - 腎功能】
// ─────────────────────────────────────────────────────────────────────────────

// 肌酸酐 血清（NHI: 09015C）
// 注意：以 09015C 對應的 LOINC 主要為血清/血漿/全血
define "肌酸酐 血清 LOINC Codes" : {
  '2160-0',    // Creatinine in Ser/Plas (推薦優先使用 / 成人健檢指定)
  '14682-9',   // Creatinine in Ser/Plas
  '44784-7',   // Creatinine in Ser/Plas
  '77140-2',   // Creatinine in Ser/Plas/Bld
  '101475-2',  // Creatinine in BldV
  '21232-4',   // Creatinine in BldA
  '38483-4',   // Creatinine in Bld
  '59826-8',   // Creatinine in Bld
  '96590-5'    // Creatinine in Bld.dot
}

// 腎絲球過濾率 GFR（NHI: 09015C 同組）
define "腎絲球過濾率 LOINC Codes" : {
  '33914-3',   // GFR/1.73 sq M.predicted (推薦優先使用)
  '45066-8',   // Creatinine & GFR panel
  '62238-1',   // GFR/1.73 sq M.predicted by Creatinine-based formula (CKD-EPI) （v1.2.0 新增，CPG-13 §2-2）
  '77147-7',   // GFR in Ser/Plas/Bld
  '98979-8'    // GFR in Ser/Plas/Bld
}

// 肌酐 尿（NHI: 09016C）
// 注意：對應 Urine 及各體腔液，LOINC 代碼眾多
// 常用尿液代碼
define "肌酐 尿 主要 LOINC Codes" : {
  '12585-6',   // Creatinine in Urine (推薦)
  '12586-4',   // Creatinine in Urine
  '14683-7',   // Creatinine in Urine
  '14684-5',   // Creatinine in Urine
  '16689-2',   // Creatinine in Urine
  '16690-0',   // Creatinine in Urine
  '20511-2',   // Creatinine in Urine
  '20624-3',   // Creatinine in Urine
  '25886-3',   // Creatinine in Urine
  '30002-0', '30004-6', // Urine
  '32543-1', '33798-0', '35262-5', '35674-1', // Urine
  '39473-4',   // Urine
  '51592-4', '53120-2', '53499-0', // Urine
  '55593-8', '57344-4', '57346-9', // Urine
  '58998-6', '72821-2', '75363-2', // Urine
  '93733-4', '93734-2', '93735-9', // Urine
  '94844-8', '99384-0'  // Urine
}

// ─────────────────────────────────────────────────────────────────────────────
// 【生化 - 電解質】
// ─────────────────────────────────────────────────────────────────────────────

// 鈣 總鈣（NHI: 09011C）
define "總鈣 血清 主要 LOINC" : '17861-6'   // Calcium in Ser/Plas

define "總鈣 LOINC Codes" : {
  '17861-6',   // Calcium in Ser/Plas (推薦)
  '17862-4', '2004-0', '12511-2', // Urine
  '27182-5',   // Bld
  '42593-4',   // BldC
  '42857-3',   // BldV
  '49765-1',   // Bld
  '65540-7',   // Ser/Plas (alternative)
  '54364-5', '57919-3', // Flu.nonbiological
  '54365-2',   // BldCo
  '12181-4', '15155-5', // Body fld
  '14415-4',   // Amnio fld
  '14416-2',   // Plr fld
  '14417-0',   // Periton fld
  '14418-8',   // Synv fld
  '14419-6',   // Gast fld
  '14636-5',   // Calculus
  '49764-4',   // Amnio fld
  '69425-7'    // Semen (FERT)
}

// 游離鈣（NHI: 24007B）
define "游離鈣 血清 主要 LOINC" : '1995-0'   // Calcium.ionized in Ser/Plas

define "游離鈣 LOINC Codes" : {
  '12180-6',   // Calcium.ionized in Ser/Plas
  '13959-2',   // Calcium.ionized in Ser/Plas
  '17863-2',   // Calcium.ionized in Ser/Plas
  '17864-0',   // Calcium.ionized in Ser/Plas
  '1995-0',    // Calcium.ionized in Ser/Plas (推薦)
  '34581-9',   // BldA
  '38230-9',   // Bld
  '41644-6',   // BldC
  '41645-3',   // BldV
  '41646-1',   // BldMV
  '46093-1',   // Dial fld
  '47596-2',   // Bld
  '50837-4',   // Body fld
  '59470-5',   // BldA
  '59471-3',   // BldV
  '83064-6',   // BldCRRT
  // pH 7.4 校正
  '19072-8', '47598-8', '50838-2', '53087-3', '53088-1',
  '53138-4', '53139-2', '53140-0', '54366-0', '57333-7',
  '59472-1', '59473-9',
  // 比值
  '49935-0', '49936-8'
}

// ─────────────────────────────────────────────────────────────────────────────
// 【感染 - 肝炎】
// ─────────────────────────────────────────────────────────────────────────────

// B型肝炎表面抗原 HBsAg（NHI: 14030C / 14031C / 14032C / 27033C）
define "HBsAg 主要 LOINC Codes" : {
  '5195-3',    // HBsAg in Ser（推薦優先使用 / 成人健檢指定）
  '58452-4',   // HBsAg in Ser（NHI 14030C/14031C 共用）
  '65633-0',   // HBsAg in Ser/Plas
  '70154-0',   // HBsAg in Ser/Plas
  '95234-1',   // HBsAg in Ser/Plas
  '63557-3',   // HBsAg in Ser/Plas（NHI 14032C）
  '75410-1',   // HBsAg in Ser/Plas/Bld（NHI 14032C）
  '99385-7'    // HBsAg in Ser/Plas（NHI 14032C）
}

// C型肝炎病毒抗體 HCV Ab（NHI: 14051C）
define "HCV Ab 主要 LOINC Codes" : {
  '13955-0',   // HCV Ab in Ser/Plas（推薦優先使用）
  '16128-1',   // HCV Ab in Ser
  '22327-1',   // HCV Ab in Ser
  '72376-7',   // HCV Ab in Ser/Plas
  '95237-4',   // HCV Ab in Ser/Plas
  '12128-1',   // HCV Ab in Ser（成人健檢指定）
  // IgG
  '16129-9', '16936-7', '40726-2', '57006-9', '89359-4',
  // IgM
  '51824-1', '53376-0',
  // Signal/Cutoff
  '48159-8',
  // Panel
  '95206-9'
}

// ─────────────────────────────────────────────────────────────────────────────
// 【腫瘤標記】
// ─────────────────────────────────────────────────────────────────────────────

// 甲型胎兒蛋白 AFP（NHI: 12007C / 27049C）
define "AFP 主要 LOINC Codes" : {
  '1834-1',    // AFP in Ser/Plas（最常用、兩個 NHI 代碼共用）
  '1832-5',    // AFP in Ser/Plas
  '1833-3',    // AFP in Ser/Plas
  '19171-8', '19172-6', '19173-4', '19176-7', '19177-5', // Ser/Plas
  '20450-3', '31993-9', '43798-8', '44910-8', // Ser/Plas
  '83072-9', '83073-7', '83074-5', '83075-2', // (NHI 12007C)
  '99077-0',   // AFP.L3 (NHI 12007C)
  '42332-7',   // AFP.L3/AFP.total ratio
  '53960-1', '53961-9', '53962-7', // AFP.tumor marker
  '90290-8',   // AFP Ab (SERO)
  '10459-6'    // AFP Ag (PATH)
}

// 攝護腺特異抗原 PSA（NHI: 12081C / 27052C）
define "PSA 主要 LOINC Codes" : {
  '19197-3',   // PSA in Ser/Plas（推薦）
  '19195-7', '19198-1', '19199-9', '19200-5', // Ser/Plas
  '34611-4', '35741-8', '47738-0', // Ser/Plas
  '59221-2', '59223-8', '59230-3', // Ser/Plas
  '83112-3',   // PSA（NHI 12081C）
  '100716-0',  // Prostate Specific Ag
  '10508-0',   // PSA (PATH)
  '33667-7',   // PSA.protein bound
  '53764-7'    // PSA panel
}

// 游離 PSA / Free PSA（NHI: 12198C / 27083B）
define "Free PSA LOINC Codes" : {
  '10886-0',   // PSA.free in Ser/Plas
  '19201-3', '19203-9', '19204-7', '19205-4', '19206-2', // Ser/Plas
  '59224-6', '59231-1', '59232-9', '59239-4', // Ser/Plas
  '83113-1',   // PSA.free (NHI 12198C)
  // Free/Total ratio
  '12841-3', '59235-2', '59236-0', '59237-8', '59238-6', '72576-2'
}

// HER2（NHI: 12195B）
define "HER2 LOINC Codes" : {
  '32996-1',   // HER2
  '48676-1',   // HER2
  '85319-2',   // HER2
  '18474-7'    // HER2 Ag
}

// PD-L1（NHI: 30103B）
define "PD-L1 LOINC Codes" : {
  '83052-1', '83054-7', '85147-7', // clone 22C3
  '83055-4', '83056-2', '85148-5', // clone 28-8
  '83057-0', '85149-3',            // clone SP142
  '99064-8'                        // clone SP263
}

// ─────────────────────────────────────────────────────────────────────────────
// 【免疫】
// ─────────────────────────────────────────────────────────────────────────────

// β2-微球蛋白（NHI: 12052B）
define "Beta2 微球蛋白 LOINC Codes" : {
  '1951-3',    // Beta-2-Microglobulin in Ser（推薦）
  '10873-8',   // Ser
  '14626-6',   // Ser/Plas
  '1952-1',    // Urine
  '1953-9',    // CSF
  '32301-4', '32302-2', // Ser/Plas
  '39458-5', '43818-4', '43819-2', '43919-0', // various
  '48166-3', '49081-3', '50824-2', '54356-1', // various
  '56662-0', '59217-0', '59218-8', // various
  '76484-5', '83076-0', '83077-8', '83078-6', '83079-4', '88711-7'
}

// 免疫球蛋白 IgM（NHI: 12028B / 12029B）
define "IgM LOINC Codes" : {
  '2471-1',    // IgM in Ser（推薦）
  '2472-9',    // IgM in Ser
  '14002-0',   // IgM in Ser
  '15185-2',   // IgM in Ser
  '26958-9',   // IgM in Ser
  '50992-7', '54902-2', '55925-2', '56123-3', '58764-2',
  '6783-5', '6784-3', '76491-0'
}

// 免疫球蛋白輕鏈 κ/λ（NHI: 12160B）
define "免疫球蛋白輕鏈 LOINC Codes" : {
  '27365-6',   // Ig light chains.kappa
  '11050-2',   // Ig light chains.kappa
  '11051-0',   // Ig light chains.lambda
  '27394-6',   // Ig light chains.lambda
  '36916-5', '80515-0', // kappa.free
  '33944-0', '80516-8', // lambda.free
  '80517-6',   // kappa.free/lambda.free ratio
  '40844-3',   // kappa.free/lambda ratio
  '15189-4', '33559-6', '48773-6', '49908-7', '6788-4', // kappa/lambda ratio
  '1759-0'     // Albumin/Globulin
}

// ANCA（NHI: 12171B）
define "ANCA LOINC Codes" : {
  '17351-8', '17352-6', '21023-7', '35279-9', '45151-8',
  '51924-9', '63292-7', '63293-5',
  '5128-4',  // cANCA
  '5262-1'   // pANCA
}

// 動情激素接受體 ER（NHI: 27061B）
define "ER 動情激素接受體 LOINC Codes" : {
  '14130-9', '16112-5', // Estrogen receptor
  '40556-3', '85337-4', // Estrogen receptor Ag
  '85310-1'             // ER fluorescence intensity
}

// 黃體激素接受體 PR（NHI: 27062B）
define "PR 黃體激素接受體 LOINC Codes" : {
  '10861-3', '16113-3', '31207-4', // Progesterone receptor
  '40557-1', '85339-0',            // PR Ag
  '85331-7'                        // PR fluorescence intensity
}

// ─────────────────────────────────────────────────────────────────────────────
// 【荷爾蒙】
// ─────────────────────────────────────────────────────────────────────────────

// 睪固酮（NHI: 09121C / 27021B）
define "睪固酮 LOINC Codes" : {
  '2986-8',    // Testosterone in Ser/Plas（推薦）
  '49041-7', '70239-9', '83115-6', '83116-4', // NHI 09121C
  '14914-6', '17685-9', '25987-9',             // NHI 27021B
  '49042-5', '70240-7', '96559-0',             // NHI 27021B
  // Free testosterone
  '103227-5', '2991-8',
  // Free+weakly bound
  '2990-0', '41018-3', '51005-7',
  // Ratios
  '15432-8', '49043-3', '6891-6',
  // challenge
  '100797-0', '100798-8'
}

// 雌二醇 Estradiol（NHI: 09127C / 27019B）
define "雌二醇 LOINC Codes" : {
  '2238-4',    // Estradiol in Ser/Plas（推薦）
  '2239-2',    // Estradiol in Ser/Plas
  '2243-4',    // Estradiol
  '2245-9',    // Estradiol
  '83096-8', '83097-6', // NHI 09127C
  '12595-5', '14715-7', '21263-9', // NHI 27019B
  '25401-1', '31176-1', '34286-5', '34287-3',
  '35384-7', '55857-7', '55858-5',
  '72873-3', '97741-3', '97742-1'
}

// 濾泡刺激素 FSH（NHI: 09125C / 27013B）
define "FSH LOINC Codes" : {
  '83098-4',   // FSH（NHI 09125C）
  '100794-7',  // FSH（NHI 27013B）
  '15067-2', '15068-0', '20433-9', '25639-6', '27203-9', '34306-1',
  '34549-6'    // FSH & LH panel
}

// ─────────────────────────────────────────────────────────────────────────────
// 【感染 - HPV】
// ─────────────────────────────────────────────────────────────────────────────

// HPV（NHI: 12182C）
define "HPV 16 LOINC"       : '77399-4'
define "HPV 18 LOINC"       : '77400-0'
define "HPV 高危型 LOINC Codes" : {
  '82675-0',   // HPV 16+18+31+33+35+39+45+51+52+56+58+59+66+68
  '77399-4',   // HPV 16
  '77400-0',   // HPV 18
  '95536-9',   // HPV 45
  '104170-6',  // HPV 31+33+52+58
  '106051-6',  // HPV 35+39+51+56+59+66+68
  '104132-6'   // HPV interpretation
}

// ─────────────────────────────────────────────────────────────────────────────
// 【聽力】
// ─────────────────────────────────────────────────────────────────────────────

// 純音聽力（NHI: 22001C）
define "純音聽力 LOINC Codes" : {
  '45498-3',   // Hearing (MDS)
  '45499-1',   // Hearing aid present & used
  '45500-6',   // Hearing aid present & not used regularly
  '46678-9',   // Hearing (RFC)
  '54599-6'    // Hearing aid used during assessment period
}

// 詐聾聽力（NHI: 22015B）
define "詐聾聽力 LOINC Codes" : {
  '45498-3',   // Hearing (MDS, 與純音共用)
  '46678-9'    // Hearing (RFC, 與純音共用)
}

// 自記聽力（NHI: 22025B）
define "自記聽力 LOINC"     : '46530-2'

// ─────────────────────────────────────────────────────────────────────────────
// 【白血球表面標記（NHI: 12204B）】
// ─────────────────────────────────────────────────────────────────────────────

define "白血球表面標記 LOINC Codes" : {
  '20584-9',   // Leukocytes
  '54221-7',   // Lymphoma markers
  '61125-1',   // Monocytes/100 leukocytes
  '67128-9',   // Leukocytes.abnormal/100 leukocytes
  '73900-3',   // Cells.CD3-CD8-CD57+/100 leukocytes
  '73903-7',   // Cells.CD3-CD57+/100 leukocytes
  '74226-2',   // Plasma cells assessment
  '101147-7'   // Monocytes/100 leukocytes
}

// ─────────────────────────────────────────────────────────────────────────────
// 【蛋白電泳（NHI: 09065B / 09100B / 12103B / 12159B）】
// ─────────────────────────────────────────────────────────────────────────────

define "蛋白電泳 LOINC Codes" : {
  '12851-2', '13439-5', '48423-8', '49295-9', '49296-7', // Ser 蛋白電泳
  '13438-7', '32210-7', '49299-1', '49301-5',            // Urine 蛋白電泳
  '49300-7', '14895-7',                                   // 免疫電泳
  '14896-5',                                              // 尿液免疫固定電泳
  '87835-5',                                              // Protein.monoclonal
  '13978-2',   // Alpha 1 globulin/Protein.total
  '13980-8',   // Albumin/Protein.total
  '13981-6',   // Alpha 2 globulin/Protein.total
  '13982-4',   // Beta globulin/Protein.total
  '13983-2',   // Gamma globulin/Protein.total
  '90991-1', '101665-8', '101668-2', // Electrophoresis panels
  '95801-7'    // Ig light chains.free & immunofixation panel
}

// ═══════════════════════════════════════════════════════════════════════════════
// 五、v1.2.0 晉升項目（來源：CPG-13 §2-2 + 附表三 114-01-01）
//     原為 TB_Lab_Report.cql v0.3.x 之 TbInlineLabLoincCodes 內容；
//     經附表三驗證 NHI 屬通用代碼後晉升至 TWCore。
// ═══════════════════════════════════════════════════════════════════════════════

// 鹼性磷酯酶 ALP（NHI: 09027C）
// Alkaline phosphatase in Ser/Plas（CPG-13 §2-2 主要）
// 註：採 list 形式以利後續 CDC / 院方擴充變體（與 "ALT GPT LOINC Codes" 等一致）
define "ALP LOINC Codes" : { '6768-6' }

// BUN 血中尿素氮（NHI: 09002C）
// Urea nitrogen in Ser/Plas（CPG-13 §2-2 主要）
define "BUN 尿素氮 LOINC Codes" : { '3094-0' }

// 血糖（NHI: 09005C 空腹 / 09140C 餐後）
// 既有 "血糖 空腹 LOINC" = '17865-7' 保留供「明確要空腹」之單碼比對情境
// 本 list 為通用判斷（任一血糖代碼皆視為符合）
// '2345-7' = Glucose [Mass/volume] in Ser/Plas（CPG-13 §2-2，未指明空腹/餐後）
// '17865-7' = Fasting glucose [Mass/volume] in Ser/Plas（NHI 09005C 空腹）
define "血糖 LOINC Codes" : { '2345-7', '17865-7' }
