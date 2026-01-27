using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models;

[Table("Courts")]
public class Court
{
    [Key]
    public int Id { get; set; }

    public string Name { get; set; } = "";

    public decimal PricePerHour { get; set; }

    public bool IsActive { get; set; }

    // Navigation
    public ICollection<Booking> Bookings { get; set; }
}
