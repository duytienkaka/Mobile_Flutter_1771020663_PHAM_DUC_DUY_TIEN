using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models;

[Table("TournamentTeams")]
public class TournamentTeam
{
    [Key]
    public int Id { get; set; }

    public int TournamentId { get; set; }
    public string TeamName { get; set; }
    public List<int> MemberIds { get; set; } = new(); // Danh sách ID thành viên
    public bool IsRegistered { get; set; } = false;

    // Navigation
    public Tournament Tournament { get; set; }
    public ICollection<TournamentRegistration> Registrations { get; set; } = new List<TournamentRegistration>();
}