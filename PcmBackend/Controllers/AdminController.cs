using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.DTOs;
using PcmBackend.Models;

namespace PcmBackend.Controllers;

[ApiController]
[Route("api/admin")]
[Authorize(Roles = "Admin")]
public class AdminController : ControllerBase
{
    private readonly AppDbContext _context;

    public AdminController(AppDbContext context)
    {
        _context = context;
    }

    // User Management
    [HttpGet("users")]
    public async Task<IActionResult> GetUsers()
    {
        var users = await _context.Members
            .Select(m => new
            {
                m.Id,
                m.UserName,
                m.FullName,
                m.WalletBalance,
                m.TotalSpent,
                m.Tier,
                m.Role,
                m.CreatedDate
            })
            .ToListAsync();

        return Ok(users);
    }

    [HttpPut("users/{id}/role")]
    public async Task<IActionResult> UpdateUserRole(int id, [FromBody] UpdateRoleRequest request)
    {
        var member = await _context.Members.FindAsync(id);
        if (member == null) return NotFound();

        var normalized = (request.Role ?? string.Empty).Trim().ToLowerInvariant();
        if (normalized is not "admin" and not "user") return BadRequest("Role không hợp lệ");

        member.Role = normalized == "admin" ? "Admin" : "User";
        await _context.SaveChangesAsync();

        return Ok();
    }

    [HttpDelete("users/{id}")]
    public async Task<IActionResult> DeleteUser(int id)
    {
        var member = await _context.Members.FindAsync(id);
        if (member == null) return NotFound();

        _context.Members.Remove(member);
        await _context.SaveChangesAsync();

        return Ok();
    }

    // Court Management
    [HttpGet("courts")]
    public async Task<IActionResult> GetCourts()
    {
        var courts = await _context.Courts.ToListAsync();
        return Ok(courts);
    }

    [HttpPut("courts/{id}")]
    public async Task<IActionResult> UpdateCourt(int id, Court updatedCourt)
    {
        var court = await _context.Courts.FindAsync(id);
        if (court == null) return NotFound();

        court.Name = updatedCourt.Name;
        court.PricePerHour = updatedCourt.PricePerHour;
        court.IsActive = updatedCourt.IsActive;

        await _context.SaveChangesAsync();
        return Ok(court);
    }

    [HttpDelete("courts/{id}")]
    public async Task<IActionResult> DeleteCourt(int id)
    {
        var court = await _context.Courts.FindAsync(id);
        if (court == null) return NotFound();

        _context.Courts.Remove(court);
        await _context.SaveChangesAsync();

        return Ok();
    }

    // Booking Management
    [HttpGet("bookings")]
    public async Task<IActionResult> GetBookings()
    {
        var bookings = await _context.Bookings
            .Include(b => b.Member)
            .Include(b => b.Court)
            .OrderByDescending(b => b.StartTime)
            .Select(b => new
            {
                b.Id,
                MemberName = b.Member.FullName,
                UserName = b.Member.UserName,
                CourtName = b.Court.Name,
                b.StartTime,
                b.EndTime,
                b.TotalPrice,
                b.Status,
                b.CreatedDate
            })
            .ToListAsync();

        return Ok(bookings);
    }

    [HttpDelete("bookings/{id}")]
    public async Task<IActionResult> DeleteBooking(int id)
    {
        var booking = await _context.Bookings.FindAsync(id);
        if (booking == null) return NotFound();

        _context.Bookings.Remove(booking);
        await _context.SaveChangesAsync();

        return Ok();
    }

    // Tournament Management
    [HttpGet("tournaments")]
    public async Task<IActionResult> GetTournaments()
    {
        var tournaments = await _context.Tournaments
            .Include(t => t.Creator)
            .ToListAsync();

        return Ok(tournaments);
    }

    [HttpDelete("tournaments/{id}")]
    public async Task<IActionResult> DeleteTournament(int id)
    {
        var tournament = await _context.Tournaments.FindAsync(id);
        if (tournament == null) return NotFound();

        _context.Tournaments.Remove(tournament);
        await _context.SaveChangesAsync();

        return Ok();
    }

    // Top-up Management
    [HttpGet("topup-requests")]
    public async Task<IActionResult> GetTopUpRequests()
    {
        try
        {
            var pending = await _context.WalletTransactions
                .Include(t => t.Member)
                .Where(t => !string.IsNullOrEmpty(t.Type) && EF.Functions.Like(t.Type!, "%TopUpPending%"))
                .OrderByDescending(t => t.CreatedDate)
                .Take(500)
                .Select(t => new
                {
                    t.Id,
                    t.Amount,
                    t.Type,
                    t.Description,
                    t.CreatedDate,
                    Member = new
                    {
                        t.Member.Id,
                        t.Member.FullName,
                        t.Member.UserName
                    }
                })
                .ToListAsync();

            return Ok(pending);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"GetTopUpRequests error: {ex}");
            return StatusCode(500, ex.Message);
        }
    }

    [HttpPost("topup-requests/{id}/approve")]
    public async Task<IActionResult> ApproveTopUp(int id)
    {
        var transaction = await _context.WalletTransactions
            .Include(t => t.Member)
            .FirstOrDefaultAsync(t => t.Id == id && t.Type == "TopUpPending");

        if (transaction == null)
            return NotFound("Yêu cầu nạp tiền không tồn tại hoặc đã xử lý");

        transaction.Type = "TopUpApproved";
        transaction.Description = "Đã duyệt bởi admin";

        transaction.Member.WalletBalance += transaction.Amount;

        await _context.SaveChangesAsync();

        return Ok(new
        {
            Message = "Đã duyệt nạp tiền",
            WalletBalance = transaction.Member.WalletBalance
        });
    }

    [HttpPost("courts")]
    public async Task<IActionResult> CreateCourt(Court court)
    {
        court.IsActive = true; // Default to active
        _context.Courts.Add(court);
        await _context.SaveChangesAsync();
        return Ok(court);
    }

    [HttpPost("tournaments")]
    public async Task<IActionResult> CreateTournament(CreateTournamentRequest request)
    {
        var adminId = int.Parse(User.FindFirst("memberId")?.Value ?? "0");
        if (adminId == 0) return Unauthorized();

        var tournament = new Tournament
        {
            Name = request.Name,
            Sport = request.Sport,
            StartDate = request.StartDate,
            EntryFee = request.EntryFee,
            MaxTeams = request.MaxTeams,
            PrizePool = request.PrizePool,
            CreatorId = adminId,
            Status = "Open",
            CreatedDate = DateTime.UtcNow
        };

        _context.Tournaments.Add(tournament);
        await _context.SaveChangesAsync();

        return Ok(new { tournament.Id });
    }
}