using Azure.Identity;
using Microsoft.Azure.Cosmos;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorPages();
builder.Services.AddApplicationInsightsTelemetry();

builder.Services.AddSingleton<CosmosClient>(
    o => new CosmosClient(
            builder.Configuration["COSMOS_URI"] ?? throw new Exception("Missing COSMOS_URI configuration"),
            new DefaultAzureCredential(new DefaultAzureCredentialOptions { ManagedIdentityClientId = builder.Configuration["USER_ASSIGNED_ID"]}),
            new CosmosClientOptions { ApplicationRegion = builder.Configuration["DEPLOYED_REGION"] ?? throw new Exception("Missing DEPLOYED_REGION configuration"),}
    )
);

builder.Services.AddTransient<Container>(o => {
    var client = o.GetService<CosmosClient>() ?? throw new Exception("Missing required COSMOS Client");
    return client.GetContainer(builder.Configuration["COSMOS_DB_NAME"], builder.Configuration["COSMOS_CONTAINER_NAME"]);
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

app.MapRazorPages();

app.Run();
