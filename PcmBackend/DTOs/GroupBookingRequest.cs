namespace PcmBackend.DTOs;

public class GroupBookingRequest
{
    public int CourtId { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public List<string> InvitedUserNames { get; set; } = new();
}