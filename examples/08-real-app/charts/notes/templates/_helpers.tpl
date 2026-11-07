{{- define "notes.labels" -}}
app.kubernetes.io/part-of: notes
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* The security settings every container shares: no root, no privilege changes, a read-only filesystem. */}}
{{- define "notes.containerSecurity" -}}
allowPrivilegeEscalation: false
readOnlyRootFilesystem: true
capabilities:
  drop: ["ALL"]
{{- end }}

{{- define "notes.podSecurity" -}}
runAsNonRoot: true
seccompProfile:
  type: RuntimeDefault
{{- end }}

{{/* The database's connection string, from the Secret the operator creates (<cluster>-app). */}}
{{- define "notes.databaseEnv" -}}
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-app
      key: uri
{{- end }}
