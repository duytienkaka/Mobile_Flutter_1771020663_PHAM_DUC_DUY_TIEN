using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.Security.Claims;
using System.Text;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Models;
using System.IdentityModel.Tokens.Jwt;
using PcmBackend.DTOs;
using Microsoft.AspNetCore.Authorization;

namespace PcmBackend.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IConfiguration _config;

    public AuthController(AppDbContext context, IConfiguration config)
    {
        _context = context;
        _config = config;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterRequest request)
    {
        // Check if username already exists
        if (await _context.Members.AnyAsync(m => m.UserName == request.UserName))
            return BadRequest("Tên đăng nhập đã tồn tại");

        var member = new Member
        {
            UserName = request.UserName,
            Password = request.Password, // In production, hash the password
            FullName = request.FullName,
            WalletBalance = 0,
            TotalSpent = 0,
            Tier = "Standard",
            Role = "User",
            CreatedDate = DateTime.UtcNow
        };

        _context.Members.Add(member);
        await _context.SaveChangesAsync();

        return Ok(new { member.Id, member.FullName });
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginRequest request)
    {
        var member = await _context.Members
            .FirstOrDefaultAsync(x =>
                x.UserName == request.UserName &&
                x.Password == request.Password);

        if (member == null)
            return Unauthorized("Sai tài khoản hoặc mật khẩu");

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, member.Id.ToString()),
            new Claim(ClaimTypes.Name, member.UserName),
            new Claim("memberId", member.Id.ToString()),
            new Claim(ClaimTypes.Role, member.Role)
        };

        var key = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(_config["Jwt:Key"]!)
        );

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.AddDays(7),
            Issuer = _config["Jwt:Issuer"],
            Audience = _config["Jwt:Audience"],
            SigningCredentials = new SigningCredentials(
                key,
                SecurityAlgorithms.HmacSha256Signature
            )
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        var token = tokenHandler.CreateToken(tokenDescriptor);

        return Ok(new
        {
            member.Id,
            member.FullName,
            member.WalletBalance,
            member.Role,
            Token = tokenHandler.WriteToken(token)
        });
    }

    [HttpPut("change-password")]
    [Authorize]
    public async Task<IActionResult> ChangePassword(ChangePasswordRequest request)
    {
        var memberId = int.Parse(User.FindFirst("memberId")?.Value ?? "0");
        if (memberId == 0) return Unauthorized();

        var member = await _context.Members.FindAsync(memberId);
        if (member == null) return NotFound();

        if (member.Password != request.CurrentPassword)
            return BadRequest("Mật khẩu hiện tại không đúng");

        member.Password = request.NewPassword; // In production, hash the password
        await _context.SaveChangesAsync();

        return Ok("Đổi mật khẩu thành công");
    }
}
