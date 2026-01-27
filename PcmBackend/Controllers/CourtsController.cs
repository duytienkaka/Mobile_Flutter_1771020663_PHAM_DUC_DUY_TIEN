using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PcmBackend.Data;

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
    }
}
