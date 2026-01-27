using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models;

[Table("Tournaments")]
public class Tournament
{
    [Key]
    public int Id { get; set; }

    public string Name { get; set; }
    public string Sport { get; set; } // e.g., "Bóng đá", "Cầu lông"
    public DateTime StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public decimal EntryFee { get; set; }
    public int MaxTeams { get; set; }
    public decimal PrizePool { get; set; } = 0;
    public string Status { get; set; } = "Open"; // Open, InProgress, Completed
    public int CreatorId { get; set; }
    public DateTime CreatedDate { get; set; }

    // Navigation
    public Member Creator { get; set; }
    public ICollection<TournamentTeam> Teams { get; set; }
    public ICollection<TournamentMatch> Matches { get; set; }
}