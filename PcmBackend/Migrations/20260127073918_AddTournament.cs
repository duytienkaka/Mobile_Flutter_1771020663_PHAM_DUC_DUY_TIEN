using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PcmBackend.Migrations
{
    /// <inheritdoc />
    public partial class AddTournament : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Tournaments",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    Name = table.Column<string>(type: "TEXT", nullable: false),
                    Sport = table.Column<string>(type: "TEXT", nullable: false),
                    StartDate = table.Column<DateTime>(type: "TEXT", nullable: false),
                    EndDate = table.Column<DateTime>(type: "TEXT", nullable: true),
                    EntryFee = table.Column<decimal>(type: "TEXT", nullable: false),
                    MaxTeams = table.Column<int>(type: "INTEGER", nullable: false),
                    PrizePool = table.Column<decimal>(type: "TEXT", nullable: false),
                    Status = table.Column<string>(type: "TEXT", nullable: false),
                    CreatorId = table.Column<int>(type: "INTEGER", nullable: false),
                    CreatedDate = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Tournaments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Tournaments_Members_CreatorId",
                        column: x => x.CreatorId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TournamentTeams",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    TournamentId = table.Column<int>(type: "INTEGER", nullable: false),
                    TeamName = table.Column<string>(type: "TEXT", nullable: false),
                    MemberIds = table.Column<string>(type: "TEXT", nullable: false),
                    IsRegistered = table.Column<bool>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TournamentTeams", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TournamentTeams_Tournaments_TournamentId",
                        column: x => x.TournamentId,
                        principalTable: "Tournaments",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TournamentMatches",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    TournamentId = table.Column<int>(type: "INTEGER", nullable: false),
                    TeamAId = table.Column<int>(type: "INTEGER", nullable: true),
                    TeamBId = table.Column<int>(type: "INTEGER", nullable: true),
                    ScheduledTime = table.Column<DateTime>(type: "TEXT", nullable: false),
                    CourtId = table.Column<int>(type: "INTEGER", nullable: true),
                    ScoreA = table.Column<int>(type: "INTEGER", nullable: true),
                    ScoreB = table.Column<int>(type: "INTEGER", nullable: true),
                    WinnerId = table.Column<int>(type: "INTEGER", nullable: true),
                    Status = table.Column<string>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TournamentMatches", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TournamentMatches_Courts_CourtId",
                        column: x => x.CourtId,
                        principalTable: "Courts",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_TournamentMatches_TournamentTeams_TeamAId",
                        column: x => x.TeamAId,
                        principalTable: "TournamentTeams",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_TournamentMatches_TournamentTeams_TeamBId",
                        column: x => x.TeamBId,
                        principalTable: "TournamentTeams",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_TournamentMatches_Tournaments_TournamentId",
                        column: x => x.TournamentId,
                        principalTable: "Tournaments",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TournamentRegistrations",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    TournamentId = table.Column<int>(type: "INTEGER", nullable: false),
                    MemberId = table.Column<int>(type: "INTEGER", nullable: false),
                    TeamId = table.Column<int>(type: "INTEGER", nullable: false),
                    PaidAmount = table.Column<decimal>(type: "TEXT", nullable: false),
                    PaidDate = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TournamentRegistrations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TournamentRegistrations_Members_MemberId",
                        column: x => x.MemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_TournamentRegistrations_TournamentTeams_TeamId",
                        column: x => x.TeamId,
                        principalTable: "TournamentTeams",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_TournamentRegistrations_Tournaments_TournamentId",
                        column: x => x.TournamentId,
                        principalTable: "Tournaments",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_TournamentMatches_CourtId",
                table: "TournamentMatches",
                column: "CourtId");

            migrationBuilder.CreateIndex(
                name: "IX_TournamentMatches_TeamAId",
                table: "TournamentMatches",
                column: "TeamAId");

            migrationBuilder.CreateIndex(
                name: "IX_TournamentMatches_TeamBId",
                table: "TournamentMatches",
                column: "TeamBId");

            migrationBuilder.CreateIndex(
                name: "IX_TournamentMatches_TournamentId",
                table: "TournamentMatches",
                column: "TournamentId");

            migrationBuilder.CreateIndex(
                name: "IX_TournamentRegistrations_MemberId",
                table: "TournamentRegistrations",
                column: "MemberId");

            migrationBuilder.CreateIndex(
                name: "IX_TournamentRegistrations_TeamId",
                table: "TournamentRegistrations",
                column: "TeamId");

            migrationBuilder.CreateIndex(
                name: "IX_TournamentRegistrations_TournamentId",
                table: "TournamentRegistrations",
                column: "TournamentId");

            migrationBuilder.CreateIndex(
                name: "IX_Tournaments_CreatorId",
                table: "Tournaments",
                column: "CreatorId");

            migrationBuilder.CreateIndex(
                name: "IX_TournamentTeams_TournamentId",
                table: "TournamentTeams",
                column: "TournamentId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "TournamentMatches");

            migrationBuilder.DropTable(
                name: "TournamentRegistrations");

            migrationBuilder.DropTable(
                name: "TournamentTeams");

            migrationBuilder.DropTable(
                name: "Tournaments");
        }
    }
}
