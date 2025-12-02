const std = @import("std");
pub fn trim(s: []const u8) []const u8 {
    var start: usize = 0;
    var end: usize = s.len;
    while (start < s.len and (s[start] == ' ' or s[start] == '\t')) start += 1;
    while (end > start and (s[end-1] == ' ' or s[end-1] == '\t')) end -= 1;
    return s[start .. end];
}
