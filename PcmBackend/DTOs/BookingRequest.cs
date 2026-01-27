namespace PcmBackend.DTOs;

public class BookingRequest
{
    public int CourtId { get; set; }

    public DateTime StartTime { get; set; }

    public DateTime EndTime { get; set; }
}
