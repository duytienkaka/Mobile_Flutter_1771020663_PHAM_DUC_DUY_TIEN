namespace PcmBackend.DTOs;

public class CreateTournamentRequest
{
    public string Name { get; set; }
    public string Sport { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public decimal EntryFee { get; set; }
    public int MaxTeams { get; set; }
    public decimal PrizePool { get; set; }
}