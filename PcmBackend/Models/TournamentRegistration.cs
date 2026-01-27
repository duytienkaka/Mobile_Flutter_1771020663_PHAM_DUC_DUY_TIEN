using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models;

[Table("TournamentRegistrations")]
public class TournamentRegistration
{
    [Key]
    public int Id { get; set; }

    public int TournamentId { get; set; }
    public int MemberId { get; set; }
    public int TeamId { get; set; }
    public decimal PaidAmount { get; set; }
    public DateTime PaidDate { get; set; }

    // Navigation
    public Tournament Tournament { get; set; }
    public Member Member { get; set; }
    public TournamentTeam Team { get; set; }
}