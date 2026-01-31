using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
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
            Type = "TopUpApproved",
            Description = "Nạp tiền QR",
            CreatedDate = DateTime.UtcNow,
        });

        await _context.SaveChangesAsync();

        return Ok(new
        {
            Message = "Nạp tiền thành công",
            WalletBalance = member.WalletBalance
        });
    }

    [HttpPost("topup/request")]
    public async Task<IActionResult> RequestTopUp([FromBody] TopUpRequest request)
    {
        if (request.Amount <= 0)
            return BadRequest("Số tiền không hợp lệ");

        var userName = User.Identity!.Name;

        var member = _context.Members
            .FirstOrDefault(m => m.UserName == userName);

        if (member == null)
            return Unauthorized();

        _context.WalletTransactions.Add(new WalletTransaction
        {
            MemberId = member.Id,
            Amount = request.Amount,
            Type = "TopUpPending",
            Description = "Chờ admin xác nhận",
            CreatedDate = DateTime.UtcNow,
        });

        await _context.SaveChangesAsync();

        return Ok(new
        {
            Message = "Đã gửi yêu cầu nạp tiền, vui lòng chờ admin xác nhận"
        });
    }

    [HttpGet("history")]
    public IActionResult GetHistory()
    {
        var userName = User.Identity!.Name;

        var transactions = _context.WalletTransactions
            .Include(t => t.Member)
            .Where(t => t.Member.UserName == userName)
            .OrderByDescending(t => t.CreatedDate)
            .Select(t => new
            {
                t.Id,
                t.Amount,
                t.Type,
                t.Description,
                t.CreatedDate
            })
            .Take(50)
            .ToList();

        return Ok(transactions);
    }
}
