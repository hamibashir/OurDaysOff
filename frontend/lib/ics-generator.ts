import { Plan } from "@/types/api";

/**
 * Generates RFC 5545 compliant .ics string for calendar export.
 * Preserves original start_at, end_at, and timezone context.
 */
export function generateIcsFile(plan: Plan, locationName?: string): string {
  const formatIcsDate = (dateStr: string | null): string => {
    if (!dateStr) return "";
    const date = new Date(dateStr);
    return date
      .toISOString()
      .replace(/[-:]/g, "")
      .replace(/\.\d{3}/, "");
  };

  const dtStart = formatIcsDate(plan.start_at);
  const dtEnd = formatIcsDate(plan.end_at || plan.start_at);
  const dtStamp = formatIcsDate(new Date().toISOString());
  const uid = `plan-${plan.id}-${Date.now()}@ourdaysoff.com`;

  const icsLines = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//Our Days Off//Schedule Coordination Platform//EN",
    "CALSCALE:GREGORIAN",
    "METHOD:PUBLISH",
    "BEGIN:VEVENT",
    `UID:${uid}`,
    `DTSTAMP:${dtStamp}`,
    `DTSTART:${dtStart}`,
    `DTEND:${dtEnd}`,
    `SUMMARY:${escapeIcsText(plan.title)}`,
    `DESCRIPTION:${escapeIcsText(plan.description || "Meetup coordinated via Our Days Off")}`,
    `LOCATION:${escapeIcsText(locationName || "TBD")}`,
    "STATUS:CONFIRMED",
    "END:VEVENT",
    "END:VCALENDAR",
  ];

  return icsLines.join("\r\n");
}

export function downloadIcsFile(plan: Plan, locationName?: string) {
  const icsContent = generateIcsFile(plan, locationName);
  const blob = new Blob([icsContent], { type: "text/calendar;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  
  const link = document.createElement("a");
  link.href = url;
  link.setAttribute("download", `${plan.title.replace(/[^a-z0-9]/gi, "_").toLowerCase()}.ics`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

function escapeIcsText(text: string): string {
  return text
    .replace(/\\/g, "\\\\")
    .replace(/;/g, "\\;")
    .replace(/,/g, "\\,")
    .replace(/\n/g, "\\n");
}
