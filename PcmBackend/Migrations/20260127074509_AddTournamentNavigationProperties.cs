using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PcmBackend.Migrations
{
    /// <inheritdoc />
    public partial class AddTournamentNavigationProperties : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_TournamentMatches_WinnerId",
                table: "TournamentMatches",
                column: "WinnerId");

            migrationBuilder.AddForeignKey(
                name: "FK_TournamentMatches_TournamentTeams_WinnerId",
                table: "TournamentMatches",
                column: "WinnerId",
                principalTable: "TournamentTeams",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_TournamentMatches_TournamentTeams_WinnerId",
                table: "TournamentMatches");

            migrationBuilder.DropIndex(
                name: "IX_TournamentMatches_WinnerId",
                table: "TournamentMatches");
        }
    }
}
