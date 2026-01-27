using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models;

[Table("Members")]
public class Member
{
    [Key]
    public int Id { get; set; }

    [Required]
    public string UserName { get; set; } = "";

    [Required]
    public string Password { get; set; } = "";

    public string FullName { get; set; } = "";

    public decimal WalletBalance { get; set; }

    public decimal TotalSpent { get; set; }

    public string Tier { get; set; } = "Standard";

    public DateTime CreatedDate { get; set; }

    // Navigation
    public ICollection<WalletTransaction> WalletTransactions { get; set; }
    public ICollection<Booking> Bookings { get; set; }
}
