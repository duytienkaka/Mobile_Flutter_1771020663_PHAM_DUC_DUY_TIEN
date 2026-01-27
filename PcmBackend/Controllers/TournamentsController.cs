using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.DTOs;
using PcmBackend.Models;

namespace PcmBackend.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class TournamentsController : ControllerBase
{
    private readonly AppDbContext _context;

    public TournamentsController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetTournaments()
    {
        var tournaments = await _context.Tournaments
            .Include(t => t.Creator)
            .Select(t => new
            {
                t.Id,
                t.Name,
                t.Sport,
                t.StartDate,
                t.EntryFee,
                t.MaxTeams,
                t.PrizePool,
                t.Status,
                CreatorName = t.Creator.FullName
            })
            .ToListAsync();

        return Ok(tournaments);
    }

    [HttpPost]
    public async Task<IActionResult> CreateTournament(CreateTournamentRequest request)
    {
        var memberId = int.Parse(User.FindFirst("memberId")?.Value ?? "0");
        if (memberId == 0) return Unauthorized();

        var tournament = new Tournament
        {
            Name = request.Name,
            Sport = request.Sport,
            StartDate = request.StartDate,
            EntryFee = request.EntryFee,
            MaxTeams = request.MaxTeams,
            PrizePool = request.PrizePool,
            CreatorId = memberId,
            Status = "Open"
        };

        _context.Tournaments.Add(tournament);
        await _context.SaveChangesAsync();

        return Ok(new { tournament.Id });
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetTournamentDetails(int id)
    {
        var tournament = await _context.Tournaments
            .Include(t => t.Creator)
            .Include(t => t.Teams)
                .ThenInclude(team => team.Registrations)
            .Include(t => t.Matches)
                .ThenInclude(m => m.TeamA)
            .Include(t => t.Matches)
                .ThenInclude(m => m.TeamB)
            .Include(t => t.Matches)
                .ThenInclude(m => m.Court)
            .FirstOrDefaultAsync(t => t.Id == id);

        if (tournament == null) return NotFound();

        var memberId = int.Parse(User.FindFirst("memberId")?.Value ?? "0");

        var result = new
        {
            tournament.Id,
            tournament.Name,
            tournament.Sport,
            tournament.StartDate,
            tournament.EntryFee,
            tournament.MaxTeams,
            tournament.PrizePool,
            tournament.Status,
            CreatorName = tournament.Creator.FullName,
            Teams = tournament.Teams.Select(team => new
            {
                team.Id,
                team.TeamName,
                MemberIds = team.Registrations.Select(r => r.MemberId).ToList(),
                IsRegistered = team.Registrations.Any(r => r.MemberId == memberId)
            }).ToList(),
            Matches = tournament.Matches.Select(m => new
            {
                m.Id,
                m.ScheduledTime,
                TeamAName = m.TeamA?.TeamName,
                TeamBName = m.TeamB?.TeamName,
                CourtName = m.Court?.Name,
                m.ScoreA,
                m.ScoreB,
                m.Status,
                WinnerName = m.Winner?.TeamName
            }).ToList()
        };

        return Ok(result);
    }

    [HttpPost("{id}/register")]
    public async Task<IActionResult> RegisterForTournament(int id, RegisterTournamentRequest request)
    {
        var memberId = int.Parse(User.FindFirst("memberId")?.Value ?? "0");
        if (memberId == 0) return Unauthorized();

        var tournament = await _context.Tournaments
            .Include(t => t.Teams)
                .ThenInclude(team => team.Registrations)
            .FirstOrDefaultAsync(t => t.Id == id);

        if (tournament == null) return NotFound();
        if (tournament.Status != "Open") return BadRequest("Tournament is not open for registration");

        // Check if member is already registered
        var existingRegistration = await _context.TournamentRegistrations
            .FirstOrDefaultAsync(r => r.TournamentId == id && r.MemberId == memberId);

        if (existingRegistration != null) return BadRequest("Already registered for this tournament");

        // Check wallet balance
        var member = await _context.Members.FindAsync(memberId);
        if (member.WalletBalance < tournament.EntryFee) return BadRequest("Insufficient balance");

        // Create or find team
        var team = await _context.TournamentTeams
            .FirstOrDefaultAsync(t => t.TournamentId == id && t.TeamName == request.TeamName);

        if (team == null)
        {
            team = new TournamentTeam
            {
                TournamentId = id,
                TeamName = request.TeamName
            };
            _context.TournamentTeams.Add(team);
            await _context.SaveChangesAsync(); // Save team first to get Id
        }

        // Add registration
        var registration = new TournamentRegistration
        {
            TournamentId = id,
            TeamId = team.Id,
            MemberId = memberId
        };
        _context.TournamentRegistrations.Add(registration);

        // Deduct fee
        member.WalletBalance -= tournament.EntryFee;
        var transaction = new WalletTransaction
        {
            MemberId = memberId,
            Amount = -tournament.EntryFee,
            Type = "TournamentEntry",
            Description = $"Tham gia giải đấu: {tournament.Name}"
        };
        _context.WalletTransactions.Add(transaction);

        await _context.SaveChangesAsync();

        return Ok();
    }
}