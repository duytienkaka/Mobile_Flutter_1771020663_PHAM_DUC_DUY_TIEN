using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using PcmBackend.Data;
using PcmBackend.Models;
using PcmBackend.DTOs;

namespace PcmBackend.Controllers;

[ApiController]
[Route("api/wallet")]
[Authorize]
public class WalletController : ControllerBase
{
    private readonly AppDbContext _context;

    public WalletController(AppDbContext context)
    {
        _context = context;
    }

    [HttpPost("topup")]
    public async Task<IActionResult> TopUp([FromBody] TopUpRequest request)
    {
        if (request.Amount <= 0)
            return BadRequest("Số tiền không hợp lệ");

        var userName = User.Identity!.Name;

        var member = _context.Members
            .FirstOrDefault(m => m.UserName == userName);

        if (member == null)
            return Unauthorized();

        member.WalletBalance += request.Amount;

        _context.WalletTransactions.Add(new WalletTransaction
        {
            MemberId = member.Id,
            Amount = request.Amount,
            Type = "Topup",
            Description = "Nạp tiền vào ví"
        });

        await _context.SaveChangesAsync();

        return Ok(new
        {
            Message = "Nạp tiền thành công",
            WalletBalance = member.WalletBalance
        });
    }
}
