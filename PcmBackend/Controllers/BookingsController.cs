using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using PcmBackend.Data;
using PcmBackend.DTOs;
using PcmBackend.Models;

namespace PcmBackend.Controllers;

[ApiController]
[Route("api/bookings")]
[Authorize]
public class BookingsController : ControllerBase
{
    private readonly AppDbContext _context;

    public BookingsController(AppDbContext context)
    {
        _context = context;
    }

    [HttpPost]
    public async Task<IActionResult> CreateBooking(BookingRequest request)
    {
        var userName = User.Identity!.Name;

        var member = await _context.Members
            .FirstOrDefaultAsync(m => m.UserName == userName);

        if (member == null)
            return Unauthorized();

        var court = await _context.Courts.FindAsync(request.CourtId);

        if (court == null)
            return BadRequest("Không tìm thấy sân");

        var totalHours =
            (int)(request.EndTime - request.StartTime).TotalHours;

        if (totalHours <= 0)
            return BadRequest("Thời gian không hợp lệ");

        var totalPrice = totalHours * court.PricePerHour;

        if (member.WalletBalance < totalPrice)
            return BadRequest("Số dư ví không đủ");

        member.WalletBalance -= totalPrice;
        member.TotalSpent += totalPrice;

        var wallet = new WalletTransaction
        {
            MemberId = member.Id,
            Amount = -totalPrice,
            Type = "Payment",
            Description = "Thanh toán đặt sân"
        };

        var booking = new Booking
        {
            MemberId = member.Id,
            CourtId = court.Id,
            StartTime = request.StartTime,
            EndTime = request.EndTime,
            TotalPrice = totalPrice,
            Status = "Confirmed"
        };

        _context.WalletTransactions.Add(wallet);
        _context.Bookings.Add(booking);

        await _context.SaveChangesAsync();

        return Ok(new
        {
            Message = "Đặt sân thành công",
            TotalPrice = totalPrice,
            WalletBalance = member.WalletBalance
        });
    }

    [HttpGet("my")]
    [Authorize]
    public IActionResult MyBookings()
    {
        var userName = User.Identity!.Name;

        var bookings = _context.Bookings
            .Where(b => b.Member.UserName == userName)
            .Select(b => new
            {
                b.Id,
                CourtName = b.Court.Name,
                b.StartTime,
                b.EndTime,
                b.TotalPrice
            })
            .OrderByDescending(b => b.StartTime)
            .ToList();

        return Ok(bookings);
    }

}
