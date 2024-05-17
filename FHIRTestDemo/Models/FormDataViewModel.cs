namespace FHIRTest.Models
{
    public class FormDataViewModel
    {
        /// <summary> 狀態 Y.正常 N.失敗 </summary>
        public string status { get; set; } = "Y";
        /// <summary> 就醫日期 </summary>
        public string strOPDDate { get; set; } = "";
        /// <summary> 就醫科別(中文名稱) </summary>
        public string DptName { get; set; } = "";
        /// <summary> 病人姓名(用○遮掩) </summary>
        public string PatName { get; set; } = "";
        /// <summary> 開立院所名稱(中文名稱) </summary>
        public string HospName { get; set; } = "";
        /// <summary> QRCode圖片 </summary>
        public List<string> lstQRCode { get; set; } = new List<string>();
    }
}
