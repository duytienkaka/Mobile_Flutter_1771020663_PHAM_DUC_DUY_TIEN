using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models;

[Table("TournamentMatches")]
public class TournamentMatch
{
    [Key]
    public int Id { get; set; }

    public int TournamentId { get; set; }
    public int? TeamAId { get; set; }
    public int? TeamBId { get; set; }
    public DateTime ScheduledTime { get; set; }
    public int? CourtId { get; set; }
    public int? ScoreA { get; set; }
    public int? ScoreB { get; set; }
    public int? WinnerId { get; set; } // TeamId của đội thắng
    public string Status { get; set; } = "Scheduled"; // Scheduled, Completed

    // Navigation
    public Tournament Tournament { get; set; }
    public TournamentTeam TeamA { get; set; }
    public TournamentTeam TeamB { get; set; }
    public Court Court { get; set; }
    public TournamentTeam Winner { get; set; }
}