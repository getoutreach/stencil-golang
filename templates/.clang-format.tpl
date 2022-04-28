{{- if not (has "library" (stencil.Arg "type")) }}
{{ file.Skip "Application is a library" }}
{{- end }}
---
Language: Proto
BasedOnStyle: google
PenaltyBreakAssignment: 10000
PenaltyBreakComment: 0
ColumnLimit: 140
AlignConsecutiveAssignments: true
ReflowComments: true
BreakBeforeBinaryOperators: None
---

