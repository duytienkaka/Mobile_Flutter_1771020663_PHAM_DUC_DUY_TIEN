using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models;

[Table("GroupMembers")]
public class GroupMember
{
    [Key]
    public int Id { get; set; }

    public int GroupBookingId { get; set; }
    public int MemberId { get; set; }

    public decimal ShareAmount { get; set; }
    public bool IsPaid { get; set; } = false;

    // Navigation
    public GroupBooking GroupBooking { get; set; }
    public Member Member { get; set; }
}