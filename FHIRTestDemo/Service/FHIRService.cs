using FHIRTest.Models;
using Hl7.Fhir.Model;
using Hl7.Fhir.Rest;
using Hl7.Fhir.Serialization;
using Hl7.Fhir.Utility;
using QRCoder;
using System.IO;
using System.IO.Compression;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.Unicode;


namespace FHIRTest.Service
{
    public class FHIRService
    {

        FhirClient client = null;

        public FHIRService()
        {
            client = new FhirClient(SettingsModel.HAPI_FHIR_URL);
        }

        /// <summary>
        ///  JSON 壓縮為 Brotli 格式，再轉為 BASE64 字串
        /// </summary>
        /// <param name="jsonData"></param>
        /// <returns></returns>
        public string getJson2Base64(string jsonData)
        {
            //回傳資料
            string ret = "";

            // 將 JSON 數據轉換為字節數組
            byte[] jsonBytes = Encoding.UTF8.GetBytes(jsonData);

            // 創建內存流
            using (MemoryStream outputStream = new MemoryStream())
            {
                // 創建 Brotli 壓縮流
                using (BrotliStream brotliStream = new BrotliStream(outputStream, CompressionMode.Compress))
                {
                    // 將 JSON 數據寫入 Brotli 壓縮流
                    brotliStream.Write(jsonBytes, 0, jsonBytes.Length);
                }

                // 獲取壓縮後的數據
                byte[] compressedData = outputStream.ToArray();

                // 將壓縮後的數據轉換為 BASE64 字符串
                ret = Convert.ToBase64String(compressedData);

            }

            //回傳
            return ret;
        }

        /// <summary>
        /// 文字產生 QRCode 的 BASE64 字串
        /// </summary>
        /// <param name="data"></param>
        /// <returns></returns>
        public string getQRCode(string data)
        {
            // 創建 QRCodeGenerator 實例
            QRCodeGenerator qrGenerator = new QRCodeGenerator();

            // 創建 QRCodeData 實例
            QRCodeData qrCodeData = qrGenerator.CreateQrCode(data, QRCodeGenerator.ECCLevel.L);

            // 創建 QRCode 實例
            PngByteQRCode qrCode = new PngByteQRCode(qrCodeData);

            // 將 QRCode 繪製到位圖上
            byte[] qrCodeImage = qrCode.GetGraphic(29);

            //byte[] image = PngByteQRCodeHelper.GetQRCode(data, QRCodeGenerator.ECCLevel.L, 29);

            // 將位圖轉換為 BASE64 字符串
            string base64String = Convert.ToBase64String(qrCodeImage);
            //using (MemoryStream ms = new MemoryStream())
            //{
            //    qrCodeImage.Save(ms, System.Drawing.Imaging.ImageFormat.Png);
            //    byte[] imageBytes = ms.ToArray();
            //    base64String = Convert.ToBase64String(imageBytes);
            //}

            return base64String;
        }

        /// <summary>
        /// 取得FHIR SERVER資料
        /// </summary>
        /// <returns></returns>
        public string getTestData(ref FormDataViewModel vm, string PatName = "甄○康", string EmpName = "洪文武", string HospName = "洪文武診所")
        {
            
            try
            {

                // Read Organization from FHIR Server by Name
                Bundle orgBundle = client.Search<Organization>(new string[] { $"name={HospName}" });
                Organization org = (Organization)orgBundle.Entry[0].Resource;
                org.Text.Div = "<div xmlns=\"http://www.w3.org/1999/xhtml\">Organization</div>";

                // Read Practitioner from FHIR Server by Name
                Bundle pracBundle = client.Search<Practitioner>(new string[] { $"name={EmpName}" });
                Practitioner prac = (Practitioner)pracBundle.Entry[0].Resource;
                prac.Text.Div = "<div xmlns=\"http://www.w3.org/1999/xhtml\">Practitioner</div>";

                // Read Patient from FHIR Server by Name
                Bundle patBundle = client.Search<Patient>(new string[] { $"name={PatName}" });
                Patient pat = (Patient)patBundle.Entry[0].Resource;
                pat.Text.Div = "<div xmlns=\"http://www.w3.org/1999/xhtml\">Patient</div>";

                // read Coverage from FHIR Server by Patient Id
                Bundle covBundle = client.Search<Coverage>(new string[] { $"beneficiary=Patient/{pat.Id}" });
                Coverage cov = (Coverage)covBundle.Entry[0].Resource;
                cov.Text.Div = "<div xmlns=\"http://www.w3.org/1999/xhtml\">Coverage</div>";

                //read encounter from FHIR Server by Patient Id order by date
                Bundle encBundle = client.Search<Encounter>(new string[] { $"subject=Patient/{pat.Id}", "_sort=date" });
                Encounter enc = (Encounter)encBundle.Entry[0].Resource;
                enc.Text.Div = "<div xmlns=\"http://www.w3.org/1999/xhtml\">Encounter</div>";

                vm.PatName = pat.Name[0].Text;
                char[] charArray = vm.PatName.ToCharArray();
                string patNM = "";
                for (int i = 0; i < charArray.Length; i++)
                {
                    if (i == 0) { patNM = charArray[i].ToString(); }
                    else if (i == charArray.Length - 1) { patNM += charArray[i].ToString(); }
                    else { patNM += "○"; }
                }
                vm.PatName = patNM;

                vm.DptName = enc.Type[0].Text;
                vm.strOPDDate = enc.Period.Start;

                //Read condition from FHIR Server by Patient Id
                Bundle conBundle = client.Search<Condition>(new string[] { $"subject=Patient/{pat.Id}" });
                Condition con = (Condition)conBundle.Entry[0].Resource;
                con.Text.Div = "<div xmlns=\"http://www.w3.org/1999/xhtml\">Condition</div>";

                //read observation from FHIR Server by Patient Id 
                Bundle obsBundle = client.Search<Observation>(new string[] { $"subject=Patient/{pat.Id}" });
                Observation obs = (Observation)obsBundle.Entry[0].Resource;
                obs.Text.Div = "<div xmlns=\"http://www.w3.org/1999/xhtml\">Observation</div>";

                //read medicationRequest from FHIR Server by Patient Id
                Bundle medReqBundle = client.Search<MedicationRequest>(new string[] { $"subject=Patient/{pat.Id}" });
                MedicationRequest medReq = (MedicationRequest)medReqBundle.Entry[0].Resource;
                medReq.Text.Div = "<div xmlns=\"http://www.w3.org/1999/xhtml\">MedicationRequest</div>";

                //MedicationRequest.Medication is a ResourceReference, so we need to get the Medication Id by reading the Medication Resource
                var medRef = medReq.Medication as ResourceReference;
                var med = client.Read<Medication>(medRef.Reference);
                med.Text.Div = "<div xmlns=\"http://www.w3.org/1999/xhtml\">Medication</div>";

                DateTime dtNow = DateTime.Now;

                // using the read FHIR resources to  create a new Composition
                var composition = new Composition
                {
                    Status = CompositionStatus.Final,
                    Type = new CodeableConcept("http://loinc.org", "29551-9", "Medication prescribed Narrative"),
                    Subject = new ResourceReference("Patient/" + pat.Id),
                    Author = new List<ResourceReference> { new ResourceReference("Organization/" + org.Id) },
                    Custodian = new ResourceReference("Organization/" + org.Id),
                    Encounter = new ResourceReference("Encounter/" + enc.Id),                    
                    Date = dtNow.ToString("yyyy-MM-ddTHH:mm:ss.fffffffK"),
                    Title = "電子處方箋",
                    Section = new List<Composition.SectionComponent>
                    {
                        new Composition.SectionComponent
                        {
                            Title = "Medication",
                            Entry = new List<ResourceReference> { new ResourceReference(medReq.Id) }
                        },
                        new Composition.SectionComponent
                        {
                            Title = "Observation",
                            Entry = new List<ResourceReference> { new ResourceReference(obs.Id) }
                        }
                    }
                };

                string uuid = Guid.NewGuid().ToString();
                // create a new bundle from the read FHIR Data
                var bundle = new Bundle
                {
                    Type = Bundle.BundleType.Document,
                    Id = uuid,
                    Identifier = new Identifier("http://www.moi.gov.tw/", uuid),
                    Timestamp = dtNow,
                    Entry = new List<Bundle.EntryComponent>
                    {
                        new Bundle.EntryComponent
                        {
                            FullUrl = "https://twcore.mohw.gov.tw/ig/emr-ig/Composition/com",
                            Resource = composition
                        },
                        new Bundle.EntryComponent
                        {
                            FullUrl = "https://twcore.mohw.gov.tw/ig/emr-ig/Patient/pat",
                            Resource = pat
                        },
                        new Bundle.EntryComponent
                        {
                            FullUrl = "https://twcore.mohw.gov.tw/ig/emr-ig/Organization/org",
                            Resource = org
                        },
                        new Bundle.EntryComponent
                        {
                            FullUrl = "https://twcore.mohw.gov.tw/ig/emr-ig/Practitioner/pra",
                            Resource = prac
                        },
                        new Bundle.EntryComponent
                        {
                            FullUrl = "https://twcore.mohw.gov.tw/ig/emr-ig/Encounter/enc",
                            Resource = enc
                        },
                        new Bundle.EntryComponent
                        {
                            FullUrl = "https://twcore.mohw.gov.tw/ig/emr-ig/Observation/obs",
                            Resource = obs
                        },
                        new Bundle.EntryComponent
                        {
                            FullUrl = "https://twcore.mohw.gov.tw/ig/emr-ig/Condition/con",
                            Resource = con
                        },
                        new Bundle.EntryComponent
                        {
                            FullUrl = "https://twcore.mohw.gov.tw/ig/emr-ig/Coverage/cov",
                            Resource = cov
                        },
                        new Bundle.EntryComponent
                        {
                            FullUrl = "https://twcore.mohw.gov.tw/ig/emr-ig/Medication/med-01",
                            Resource = med
                        },
                        new Bundle.EntryComponent
                        {FullUrl = "https://twcore.mohw.gov.tw/ig/emr-ig/MedicationRequest/med-req-01",
                            Resource = medReq
                        },

                    }
                };

                //Serialization of Bundle
                //var jsonBundle = JsonConvert.SerializeObject(bundle);
                //var jsonBundle = FhirSerializer.SerializeResourceToJson(bundle);
                //var jsonBundle = JsonSerializer.Serialize(bundle);

                FhirJsonSerializer serializer = new FhirJsonSerializer(new SerializerSettings() { Pretty = true, });
                var jsonBundle = serializer.SerializeToString(bundle);

                return jsonBundle;

            }
            catch (Exception ex)
            {

                return string.Format("Error:{0}", ex.Message);
            }
        }

        public async Task<string> getTestDataAsync()
        {
            // Read Organization from FHIR Server by Name
            Bundle orgBundle = await client.SearchAsync<Organization>(new string[] { "name=洪文武診所" });
            Organization org = (Organization)orgBundle.Entry[0].Resource;

            // Read Practitioner from FHIR Server by Name
            Bundle pracBundle = await client.SearchAsync<Practitioner>(new string[] { "name=洪文武" });
            Practitioner prac = (Practitioner)pracBundle.Entry[0].Resource;

            // Read Patient from FHIR Server by Name
            Bundle patBundle = await client.SearchAsync<Patient>(new string[] { "name=甄○康" });
            Patient pat = (Patient)patBundle.Entry[0].Resource;

            // read Coverage from FHIR Server by Patient Id
            Bundle covBundle = await client.SearchAsync<Coverage>(new string[] { $"beneficiary=Patient/{pat.Id}" });
            Coverage cov = (Coverage)covBundle.Entry[0].Resource;

            //read encounter from FHIR Server by Patient Id order by date
            Bundle encBundle = await client.SearchAsync<Encounter>(new string[] { $"subject=Patient/{pat.Id}", "_sort=date" });
            Encounter enc = (Encounter)encBundle.Entry[0].Resource;

            //Read condition from FHIR Server by Patient Id
            Bundle conBundle = await client.SearchAsync<Condition>(new string[] { $"subject=Patient/{pat.Id}" });
            Condition con = (Condition)conBundle.Entry[0].Resource;

            //read observation from FHIR Server by Patient Id 
            Bundle obsBundle = await client.SearchAsync<Observation>(new string[] { $"subject=Patient/{pat.Id}" });
            Observation obs = (Observation)obsBundle.Entry[0].Resource;

            //read medicationRequest from FHIR Server by Patient Id
            Bundle medReqBundle = await client.SearchAsync<MedicationRequest>(new string[] { $"subject=Patient/{pat.Id}" });
            MedicationRequest medReq = (MedicationRequest)medReqBundle.Entry[0].Resource;

            //MedicationRequest.Medication is a ResourceReference, so we need to get the Medication Id by reading the Medication Resource
            var medRef = medReq.Medication as ResourceReference;
            var med = await client.ReadAsync<Medication>(medRef.Reference);

            return "end";
        }


        /// <summary>
        /// 簽章值(寫死範例)
        /// </summary>
        /// <returns></returns>
        public string SignDataBase64()
        {
            string ret = "gky/2WbOt1z0fZWxaME+zk9SESXHDT1cNXN8R7qqWj9fW5Dt8XRLmD2mhuhFboz5xS+dhN9kTHFdZstnCMQHTF9Iwium1nBBT+GL0yBNG9TgTFI7svHk31/HVHa34b4zF6EZilJW62GFmVIbXfi507Dy1QVmvoVV7bC8K9Uir155B9f+edA2xrha3vJB+PP2CJ/Tocu76Dr4nk5bUmyXTi40QHFwLjojCJ90PJE0LFhy3+SHo3DZqBOz9gXct8tmzKVkzCWugS586qtPWi+BDE9WjxlIEtTYqEWGOmPKWINMT2qTZrh574eHkvneXdP+sWXZDENeE3Tj7v9tsKAIWA==";

            return ret;
        }
    }
}
