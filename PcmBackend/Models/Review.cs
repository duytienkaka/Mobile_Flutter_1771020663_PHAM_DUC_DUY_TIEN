using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models;

[Table("Reviews")]
public class Review
{
    [Key]
    public int Id { get; set; }

    public int CourtId { get; set; }
    public Court Court { get; set; }

    public int MemberId { get; set; }
    public Member Member { get; set; }

    [Range(1, 5)]
    public int Rating { get; set; } // 1-5 sao

    public string Comment { get; set; } = "";

    public DateTime CreatedDate { get; set; }
}