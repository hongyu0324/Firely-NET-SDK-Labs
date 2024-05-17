using System.Text.Encodings.Web;
using System.Text.Unicode;
using FHIRTest.Models;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllersWithViews();

// ���J JSON �ɮ�
var configuration = new ConfigurationBuilder()
    .SetBasePath(AppContext.BaseDirectory) // �]�m�j�M���|
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true) // ���J appsettings.json �ɮ�
    .Build();

// Ū�� JSON �ɮפ������e
SettingsModel.HAPI_FHIR_URL = configuration["AppSettings:HAPI_FHIR_URL"] ?? "";

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
