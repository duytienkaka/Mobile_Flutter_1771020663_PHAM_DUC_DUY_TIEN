using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using PcmBackend.Data;
using PcmBackend.Models;


var builder = WebApplication.CreateBuilder(args);
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy
            .AllowAnyOrigin()
            .AllowAnyMethod()
            .AllowAnyHeader();
    });
});

builder.Services.AddDbContext<AppDbContext>(options =>
{
    options.UseSqlite("Data Source=pcm.db");
});

// =========================
// JWT
// =========================
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!)
        )
    };
});

builder.Services.AddAuthorization();

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "PcmBackend", Version = "v1" });

    c.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.ApiKey,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Description = "Nhập: Bearer {token}"
    });

    c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new string[] {}
        }
    });
});


var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI();
app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

    db.Database.EnsureCreated();

    if (!db.Members.Any())
    {
        // Admin account
        db.Members.Add(new Member
        {
            UserName = "admin",
            Password = "admin123",
            FullName = "Administrator",
            WalletBalance = 10000000,
            Tier = "Platinum",
            Role = "Admin",
            CreatedDate = DateTime.UtcNow
        });

        // User accounts
        db.Members.Add(new Member
        {
            UserName = "user1",
            Password = "user123",
            FullName = "Nguyễn Văn A",
            WalletBalance = 500000,
            Tier = "Silver",
            Role = "User",
            CreatedDate = DateTime.UtcNow
        });

        db.Members.Add(new Member
        {
            UserName = "user2",
            Password = "user123",
            FullName = "Trần Thị B",
            WalletBalance = 750000,
            Tier = "Gold",
            Role = "User",
            CreatedDate = DateTime.UtcNow
        });

        db.Members.Add(new Member
        {
            UserName = "user3",
            Password = "user123",
            FullName = "Lê Văn C",
            WalletBalance = 300000,
            Tier = "Bronze",
            Role = "User",
            CreatedDate = DateTime.UtcNow
        });

        db.Courts.Add(new Court
        {
            Name = "Sân 1",
            PricePerHour = 120000,
            IsActive = true
        });

        db.Courts.Add(new Court
        {
            Name = "Sân 2",
            PricePerHour = 100000,
            IsActive = true
        });

        db.Courts.Add(new Court
        {
            Name = "Sân 3",
            PricePerHour = 150000,
            IsActive = true
        });

        db.Courts.Add(new Court
        {
            Name = "Sân Futsal A",
            PricePerHour = 80000,
            IsActive = true
        });

        db.Courts.Add(new Court
        {
            Name = "Sân Futsal B",
            PricePerHour = 90000,
            IsActive = true
        });

        db.Courts.Add(new Court
        {
            Name = "Sân VIP 1",
            PricePerHour = 200000,
            IsActive = true
        });

        db.Courts.Add(new Court
        {
            Name = "Sân VIP 2",
            PricePerHour = 180000,
            IsActive = true
        });

        db.Courts.Add(new Court
        {
            Name = "Sân Mini 1",
            PricePerHour = 70000,
            IsActive = true
        });

        db.Courts.Add(new Court
        {
            Name = "Sân Mini 2",
            PricePerHour = 75000,
            IsActive = true
        });

        db.SaveChanges();
    }
}

app.Run();
