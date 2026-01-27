using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PcmBackend.Data;
using PcmBackend.DTOs;
using PcmBackend.Models;
using System.Security.Claims;

namespace PcmBackend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class CourtsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public CourtsController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public IActionResult GetCourts()
        {
            var courts = _context.Courts
                .Select(c => new
                {
                    c.Id,
                    c.Name,
                    c.PricePerHour
                })
                .ToList();

            return Ok(courts);
        }

        [HttpGet("{id}/reviews")]
        public IActionResult GetReviews(int id)
        {
            var reviews = _context.Reviews
                .Where(r => r.CourtId == id)
                .Select(r => new
                {
                    r.Id,
                    r.Rating,
                    r.Comment,
                    r.CreatedDate,
                    MemberName = r.Member.FullName
                })
                .ToList();

            return Ok(reviews);
        }

        [HttpPost("{id}/reviews")]
        [Authorize]
        public async Task<IActionResult> AddReview(int id, [FromBody] AddReviewRequest request)
        {
            var memberId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            var review = new Review
            {
                CourtId = id,
                MemberId = memberId,
                Rating = request.Rating,
                Comment = request.Comment,
                CreatedDate = DateTime.UtcNow
            };

            _context.Reviews.Add(review);
            await _context.SaveChangesAsync();

            return Ok();
        }
    }
}
