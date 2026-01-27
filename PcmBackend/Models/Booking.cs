using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models;

[Table("Bookings")]
public class Booking
{
    [Key]
    public int Id { get; set; }

    public int MemberId { get; set; }
    public int CourtId { get; set; }

    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }

    public decimal TotalPrice { get; set; }

    public string Status { get; set; } = "Confirmed";

    public DateTime CreatedDate { get; set; }

    // Navigation
    public Member Member { get; set; }
    public Court Court { get; set; }
}
