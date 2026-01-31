using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models;

[Table("WalletTransactions")]
public class WalletTransaction
{
    [Key]
    public int Id { get; set; }

    public int MemberId { get; set; }

    public decimal Amount { get; set; }

    public string Type { get; set; } = "";

    public string? Description { get; set; }

    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

    // Navigation
    public Member Member { get; set; }
}
