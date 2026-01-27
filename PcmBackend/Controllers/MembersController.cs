using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using PcmBackend.Data;

namespace PcmBackend.Controllers;

[ApiController]
[Route("api/members")]
[Authorize]
public class MembersController : ControllerBase
{
    private readonly AppDbContext _context;

    public MembersController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet("me")]
    public IActionResult Me()
    {
        var memberId = int.Parse(
            User.FindFirstValue(ClaimTypes.NameIdentifier)!
        );

        var member = _context.Members.Find(memberId);

        return Ok(new
        {
            member.Id,
            member.FullName,
            member.WalletBalance,
            member.Tier
        });
    }
}
