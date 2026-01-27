namespace PcmBackend.DTOs;

public class AddReviewRequest
{
    public int Rating { get; set; }
    public string Comment { get; set; } = "";
}