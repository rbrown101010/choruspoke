import SwiftUI

struct CronJobsSheetView: View {
    @EnvironmentObject private var appModel: RunnerAppModel
    @State private var jobs: [RunnerCronJob] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        RunnerPanel(title: "Cron Jobs") {
            Group {
                if appModel.client == nil {
                    RunnerEmptyState(
                        icon: "clock.arrow.circlepath",
                        title: "Connect to runner first",
                        message: "Cron jobs load from the live local stack."
                    )
                } else if isLoading && jobs.isEmpty {
                    ProgressView()
                        .tint(RunnerTheme.primaryText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error {
                    RunnerEmptyState(
                        icon: "clock.badge.exclamationmark",
                        title: "Couldn’t load cron jobs",
                        message: error
                    )
                } else if jobs.isEmpty {
                    RunnerEmptyState(
                        icon: "clock",
                        title: "No cron jobs yet",
                        message: "Automations created in runner will show up here."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(jobs) { job in
                                cronJobCard(job)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                    }
                }
            }
        }
        .task {
            await load()
        }
    }

    private func load() async {
        guard let client = appModel.client else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await client.listCronJobs()
            jobs = response.jobs.sorted {
                ($0.state?.nextRunAtMs ?? .greatestFiniteMagnitude) < ($1.state?.nextRunAtMs ?? .greatestFiniteMagnitude)
            }
            error = nil
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func cronJobCard(_ job: RunnerCronJob) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(statusColor(for: job))
                    .frame(width: 8, height: 8)
                    .padding(.top, 5)

                VStack(alignment: .leading, spacing: 5) {
                    Text(job.name ?? "Untitled job")
                        .font(RunnerTypography.sans(15, weight: .semibold))
                        .foregroundStyle(RunnerTheme.primaryText)

                    Text(scheduleSummary(job.schedule))
                        .font(RunnerTypography.sans(13, weight: .medium))
                        .foregroundStyle(RunnerTheme.secondaryText)
                }

                Spacer(minLength: 10)

                statusPill(statusLabel(for: job), color: statusColor(for: job))
            }

            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 11, weight: .semibold))

                Text(nextRunSummary(for: job))
            }
            .font(RunnerTypography.sans(12, weight: .medium))
            .foregroundStyle(RunnerTheme.tertiaryText)

            if let issue = issueSummary(for: job) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(RunnerTheme.statusWarning)
                        .padding(.top, 1)

                    Text(issue)
                        .font(RunnerTypography.sans(12, weight: .medium))
                        .foregroundStyle(RunnerTheme.secondaryText)
                        .lineLimit(2)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.black.opacity(0.16))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(RunnerTheme.border.opacity(0.65), lineWidth: 1)
                )
            }
        }
        .padding(16)
        .runnerCard()
    }

    private func statusPill(_ status: String, color: Color) -> some View {
        Text(status)
            .font(RunnerTypography.sans(11, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(color.opacity(0.12)))
            .overlay(Capsule().stroke(color.opacity(0.18), lineWidth: 1))
    }

    private func statusLabel(for job: RunnerCronJob) -> String {
        if issueSummary(for: job) != nil {
            return "Issue"
        }

        let lower = job.state?.lastStatus?.lowercased() ?? ""
        if lower.contains("running") {
            return "Running"
        }

        return job.enabled ? "Enabled" : "Paused"
    }

    private func statusColor(for job: RunnerCronJob) -> Color {
        if issueSummary(for: job) != nil {
            return RunnerTheme.statusError
        }

        let lower = job.state?.lastStatus?.lowercased() ?? ""
        if lower.contains("running") {
            return RunnerTheme.accent
        }

        return job.enabled ? RunnerTheme.secondaryText : RunnerTheme.tertiaryText
    }

    private func nextRunSummary(for job: RunnerCronJob) -> String {
        guard let nextRun = job.state?.nextRunAtMs else {
            return job.enabled ? "Waiting for next run" : "Paused"
        }

        let date = Date(timeIntervalSince1970: nextRun / 1000)
        return "Next \(relativeDayLabel(for: date)) at \(RunnerDate.shortTime.string(from: date))"
    }

    private func issueSummary(for job: RunnerCronJob) -> String? {
        guard let raw = job.state?.lastError?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }

        let lower = raw.lowercased()
        if lower.contains("channel is required") || lower.contains("no configured channels") {
            return "Needs a configured channel before it can run."
        }

        if let firstLine = raw.split(whereSeparator: \.isNewline).first {
            return String(firstLine)
        }

        return raw
    }

    private func relativeDayLabel(for date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "today"
        }

        if calendar.isDateInTomorrow(date) {
            return "tomorrow"
        }

        if let oneWeekOut = calendar.date(byAdding: .day, value: 7, to: Date()), date < oneWeekOut {
            return date.formatted(.dateTime.weekday(.wide)).lowercased()
        }

        return date.formatted(.dateTime.month(.abbreviated).day())
    }

    private func scheduleSummary(_ schedule: RunnerCronSchedule) -> String {
        switch schedule.kind {
        case "every":
            let seconds = (schedule.everyMs ?? 0) / 1000
            if seconds >= 3600 {
                return "Every \(Int(seconds / 3600))h"
            }
            if seconds >= 60 {
                return "Every \(Int(seconds / 60))m"
            }
            return "Every \(Int(seconds))s"

        case "at":
            if let at = schedule.at, let date = runnerISODate(from: at) {
                return "One-time · \(RunnerDate.shortDateTime.string(from: date))"
            }
            return schedule.at ?? "One time"

        default:
            if let expr = schedule.expr {
                let pieces = expr.split(separator: " ")
                if pieces.count >= 5,
                   let minute = Int(pieces[0]),
                   let hour = Int(pieces[1]) {
                    let dayOfMonth = String(pieces[2])
                    let month = String(pieces[3])
                    let dayOfWeek = String(pieces[4]).uppercased()
                    let time = formattedTime(hour: hour, minute: minute) ?? expr

                    if dayOfMonth == "*" && month == "*" {
                        if dayOfWeek == "*" {
                            return "Daily · \(time)"
                        }

                        if dayOfWeek == "1-5" || dayOfWeek == "MON-FRI" {
                            return "Weekdays · \(time)"
                        }

                        if dayOfWeek == "0,6" || dayOfWeek == "6,0" || dayOfWeek == "SAT,SUN" || dayOfWeek == "SUN,SAT" {
                            return "Weekends · \(time)"
                        }

                        if let weekdayText = weekdaySummary(for: dayOfWeek) {
                            return "\(weekdayText) · \(time)"
                        }
                    }

                    if month == "*" && dayOfWeek == "*" && dayOfMonth != "*" {
                        return "Monthly · Day \(dayOfMonth) · \(time)"
                    }
                }

                if let tz = schedule.tz, !tz.isEmpty, tz != TimeZone.current.identifier {
                    return "\(expr) · \(tz)"
                }

                return expr
            }

            return "Custom schedule"
        }
    }

    private func formattedTime(hour: Int, minute: Int) -> String? {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components).map(RunnerDate.shortTime.string(from:))
    }

    private func weekdaySummary(for expression: String) -> String? {
        let dayMap: [String: String] = [
            "0": "Sunday",
            "1": "Monday",
            "2": "Tuesday",
            "3": "Wednesday",
            "4": "Thursday",
            "5": "Friday",
            "6": "Saturday",
            "7": "Sunday",
            "SUN": "Sunday",
            "MON": "Monday",
            "TUE": "Tuesday",
            "WED": "Wednesday",
            "THU": "Thursday",
            "FRI": "Friday",
            "SAT": "Saturday",
        ]

        let tokens = expression
            .split(separator: ",")
            .map { dayMap[String($0)] }

        guard !tokens.isEmpty, tokens.allSatisfy({ $0 != nil }) else {
            return nil
        }

        let days = tokens.compactMap { $0 }
        if days.count == 1 {
            return days[0]
        }
        if days.count == 2 {
            return "\(days[0]) & \(days[1])"
        }
        return "Selected days"
    }
}
