using Microsoft.EntityFrameworkCore;
using PcmBackend.Models;

namespace PcmBackend.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public DbSet<Member> Members => Set<Member>();
    public DbSet<WalletTransaction> WalletTransactions => Set<WalletTransaction>();
    public DbSet<Court> Courts => Set<Court>();
    public DbSet<Booking> Bookings => Set<Booking>();
    public DbSet<Review> Reviews => Set<Review>();
    public DbSet<GroupBooking> GroupBookings => Set<GroupBooking>();
    public DbSet<GroupMember> GroupMembers => Set<GroupMember>();
    public DbSet<Tournament> Tournaments => Set<Tournament>();
    public DbSet<TournamentTeam> TournamentTeams => Set<TournamentTeam>();
    public DbSet<TournamentMatch> TournamentMatches => Set<TournamentMatch>();
    public DbSet<TournamentRegistration> TournamentRegistrations => Set<TournamentRegistration>();
}
