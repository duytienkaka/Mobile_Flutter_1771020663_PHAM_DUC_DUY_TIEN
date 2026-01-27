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

        // Check overlap
        var overlap = await _context.Bookings.AnyAsync(b =>
            b.CourtId == request.CourtId &&
            b.Status == "Confirmed" &&
            ((request.StartTime < b.EndTime && request.EndTime > b.StartTime))
        );

        if (overlap)
            return BadRequest("Sân đã được đặt trong khung giờ này");

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
                b.TotalPrice,
                b.Status
            })
            .OrderByDescending(b => b.StartTime)
            .ToList();

        return Ok(bookings);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> CancelBooking(int id)
    {
        var memberId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var booking = await _context.Bookings
            .Include(b => b.Member)
            .FirstOrDefaultAsync(b => b.Id == id && b.MemberId == memberId);

        if (booking == null)
            return NotFound("Không tìm thấy booking");

        if (booking.StartTime <= DateTime.UtcNow)
            return BadRequest("Không thể hủy booking đã qua");

        // Refund
        booking.Member.WalletBalance += booking.TotalPrice;

        _context.WalletTransactions.Add(new WalletTransaction
        {
            MemberId = booking.Member.Id,
            Amount = booking.TotalPrice,
            Type = "Refund",
            Description = "Hoàn tiền hủy booking"
        });

        _context.Bookings.Remove(booking);

        await _context.SaveChangesAsync();

        return Ok("Đã hủy booking và hoàn tiền");
    }
}