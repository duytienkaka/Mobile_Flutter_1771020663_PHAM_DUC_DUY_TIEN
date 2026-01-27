using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models;

[Table("GroupBookings")]
public class GroupBooking
{
    [Key]
    public int Id { get; set; }

    public int CreatorId { get; set; }
    public int CourtId { get; set; }

    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }

    public decimal TotalPrice { get; set; }

    public string Status { get; set; } = "Pending"; // Pending, Confirmed, Cancelled

    public DateTime CreatedDate { get; set; }

    // Navigation
    public Member Creator { get; set; }
    public Court Court { get; set; }
    public ICollection<GroupMember> Members { get; set; }
}