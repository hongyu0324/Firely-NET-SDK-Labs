using FHIRTest.Models;
using FHIRTest.Service;
using Hl7.Fhir.Model;
using Hl7.Fhir.Rest;
using Hl7.Fhir.Serialization;
using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;
using System.Text;

namespace FHIRTest.Controllers
{
    public class HomeController : Controller
    {
        private readonly ILogger<HomeController> _logger;

        public HomeController(ILogger<HomeController> logger)
        {
            _logger = logger;
        }

        public IActionResult Index()
        {
            FHIRViewModel model = new FHIRViewModel();
            model.PatName = Encoding.UTF8.GetString(Encoding.UTF8.GetBytes("甄○康"));
            model.EmpName = Encoding.UTF8.GetString(Encoding.UTF8.GetBytes("洪文武"));
            return View(model);
        }

        public IActionResult Privacy()
        {
            return View();
        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }

        [Obsolete]
        public string CallApi(string id)
        {

            //參考 https://docs.fire.ly/projects/Firely-NET-SDK/en/latest/start.html 說明

            string ret = "";

            try
            {
                var client = new FhirClient("http://localhost:8080/fhir");

                //var txt = client.Read<Patient>("3");

                var pathEP = @"D:\project\FHIR\Data\";

                var orgFile = pathEP + "Organization-org.json";
                var parser = new FhirJsonParser();
                var org = new Organization();
                ret = System.IO.File.ReadAllText(orgFile);
            }
            catch (Exception ex)
            {
                ret = ex.Message;
            }


            return ret;

        }

        public IActionResult FormData(FHIRViewModel model)
        {
            FormDataViewModel vm = new FormDataViewModel();

            FHIRService srv = new FHIRService();

            vm.strOPDDate = DateTime.Now.ToString("yyyy/MM/dd");
            vm.DptName = "家醫科";
            vm.PatName = "甄○康";
            vm.HospName = "洪文武診所";

            //醫事人員簽章資料
            //byte[] SignBytes = Encoding.UTF8.GetBytes("簽章值");
            //string EmpSign = Convert.ToBase64String(SignBytes);
            string EmpSign = srv.SignDataBase64();

            //電子處方箋 json
            string jsonData = "";
            jsonData = srv.getTestData(ref vm, model.PatName, model.EmpName);

            if (jsonData.StartsWith("Error"))
            {
                vm.status = "N";
            }
            else
            {

                //JSON 壓縮為 Brotli 格式，再轉為 BASE64 字串
                string jsonData64 = srv.getJson2Base64(jsonData);

                int intEmpSign = EmpSign.Length;
                int intJson = jsonData64.Length;

                int intflg = 1628;

                //處方箋資訊
                List<string> lstTmpJson = new List<string>();

                if (intEmpSign + intJson > intflg)
                {
                    int firstLength = intflg - intEmpSign;
                    int secondLength = intflg;

                    // 取得第一部分
                    string firstPart = jsonData64.Substring(0, Math.Min(firstLength, jsonData64.Length));
                    lstTmpJson.Add(firstPart);

                    // 取得剩餘部分
                    string remaining = jsonData64.Substring(firstPart.Length);
                    int remainingLength = remaining.Length;

                    // 每 secondLength 長度一組輸出
                    for (int i = 0; i < remainingLength; i += secondLength)
                    {
                        int length = Math.Min(secondLength, remainingLength - i);
                        string group = remaining.Substring(i, length);
                        lstTmpJson.Add(group);
                    }
                }
                else
                {
                    lstTmpJson.Add(jsonData64);
                }

                int idx = 0;
                string JsonQR = "";
                foreach (string itm in lstTmpJson)
                {
                    idx++;
                    JsonQR = "";
                    if (idx == 1)
                    {
                        JsonQR = "{\"S\":\"" + EmpSign + "\",\"D" + idx.ToString() + "\":\"" + itm + "\"}";
                    }
                    else
                    {
                        JsonQR = "{\"D" + idx.ToString() + "\":\"" + itm + "\"}";
                    }

                    vm.lstQRCode.Add(srv.getQRCode(JsonQR));
                }
            }


            return View(vm);
        }

    }

}