{{- file.Skip "Exposes template functions" }}

# Returns the currentYear in UTC
{{- define "currentYear" }}
{{- dateInZone "2006" (now) "UTC" }}
{{- end }}


# Returns a underscored version of the application's name
# that's safe to be used in packages
{{- define "goPackageSafeName" }}
{{- regexReplaceAll "\W+" .Config.Name "_"  }}
{{- end }}


# Returns the copyright string
{{- define "copyright" }}
{{- printf "Copyright %s Outreach Corporation. All Rights Reserved." (stencil.ApplyTemplate "currentYear") }}
{{- end }}
