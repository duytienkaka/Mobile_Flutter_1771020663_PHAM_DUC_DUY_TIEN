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

    [HttpPost("group")]
    public async Task<IActionResult> CreateGroupBooking(GroupBookingRequest request)
    {
        var userName = User.Identity!.Name;

        var creator = await _context.Members
            .FirstOrDefaultAsync(m => m.UserName == userName);

        if (creator == null)
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

        var totalHours = (int)(request.EndTime - request.StartTime).TotalHours;

        if (totalHours <= 0)
            return BadRequest("Thời gian không hợp lệ");

        var totalPrice = totalHours * court.PricePerHour;

        var invitedMembers = new List<Member>();
        foreach (var uname in request.InvitedUserNames)
        {
            var m = await _context.Members.FirstOrDefaultAsync(m => m.UserName == uname);
            if (m == null)
                return BadRequest($"Không tìm thấy thành viên {uname}");
            invitedMembers.Add(m);
        }

        var shareAmount = totalPrice / (invitedMembers.Count + 1); // including creator

        var groupBooking = new GroupBooking
        {
            CreatorId = creator.Id,
            CourtId = court.Id,
            StartTime = request.StartTime,
            EndTime = request.EndTime,
            TotalPrice = totalPrice,
            CreatedDate = DateTime.UtcNow
        };

        _context.GroupBookings.Add(groupBooking);
        await _context.SaveChangesAsync(); // to get Id

        // Add creator
        _context.GroupMembers.Add(new GroupMember
        {
            GroupBookingId = groupBooking.Id,
            MemberId = creator.Id,
            ShareAmount = shareAmount
        });

        // Add invited
        foreach (var m in invitedMembers)
        {
            _context.GroupMembers.Add(new GroupMember
            {
                GroupBookingId = groupBooking.Id,
                MemberId = m.Id,
                ShareAmount = shareAmount
            });
        }

        await _context.SaveChangesAsync();

        return Ok(new
        {
            GroupBookingId = groupBooking.Id,
            Message = "Tạo nhóm đặt sân thành công",
            TotalPrice = totalPrice,
            ShareAmount = shareAmount
        });
    }

    [HttpPost("group/{groupId}/pay")]
    public async Task<IActionResult> PayGroupShare(int groupId)
    {
        var userName = User.Identity!.Name;

        var member = await _context.Members
            .FirstOrDefaultAsync(m => m.UserName == userName);

        if (member == null)
            return Unauthorized();

        var groupMember = await _context.GroupMembers
            .Include(gm => gm.GroupBooking)
            .FirstOrDefaultAsync(gm => gm.GroupBookingId == groupId && gm.MemberId == member.Id);

        if (groupMember == null)
            return BadRequest("Bạn không phải thành viên của nhóm này");

        if (groupMember.IsPaid)
            return BadRequest("Bạn đã thanh toán rồi");

        if (member.WalletBalance < groupMember.ShareAmount)
            return BadRequest("Số dư ví không đủ");

        member.WalletBalance -= groupMember.ShareAmount;
        member.TotalSpent += groupMember.ShareAmount;

        groupMember.IsPaid = true;

        _context.WalletTransactions.Add(new WalletTransaction
        {
            MemberId = member.Id,
            Amount = -groupMember.ShareAmount,
            Type = "Payment",
            Description = $"Thanh toán phần nhóm {groupId}"
        });

        // Check if all paid
        var allMembers = await _context.GroupMembers
            .Where(gm => gm.GroupBookingId == groupId)
            .ToListAsync();

        if (allMembers.All(gm => gm.IsPaid))
        {
            groupMember.GroupBooking.Status = "Confirmed";

            // Create actual booking
            var booking = new Booking
            {
                MemberId = groupMember.GroupBooking.CreatorId,
                CourtId = groupMember.GroupBooking.CourtId,
                StartTime = groupMember.GroupBooking.StartTime,
                EndTime = groupMember.GroupBooking.EndTime,
                TotalPrice = groupMember.GroupBooking.TotalPrice,
                Status = "Confirmed"
            };

            _context.Bookings.Add(booking);
        }

        await _context.SaveChangesAsync();

        return Ok(new
        {
            Message = "Thanh toán thành công",
            WalletBalance = member.WalletBalance
        });
    }

    [HttpGet("group/my")]
    public async Task<IActionResult> MyGroupBookings()
    {
        var userName = User.Identity!.Name;

        var member = await _context.Members
            .FirstOrDefaultAsync(m => m.UserName == userName);

        if (member == null)
            return Unauthorized();

        var groupBookings = await _context.GroupMembers
            .Where(gm => gm.MemberId == member.Id)
            .Include(gm => gm.GroupBooking)
            .ThenInclude(gb => gb.Court)
            .Select(gm => new
            {
                gm.GroupBooking.Id,
                CourtName = gm.GroupBooking.Court.Name,
                gm.GroupBooking.StartTime,
                gm.GroupBooking.EndTime,
                gm.GroupBooking.TotalPrice,
                gm.GroupBooking.Status,
                gm.ShareAmount,
                gm.IsPaid
            })
            .ToListAsync();

        return Ok(groupBookings);
    }
}
