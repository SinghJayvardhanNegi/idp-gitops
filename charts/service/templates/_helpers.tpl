{{- define "service.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "service.kubernetesId" -}}
{{- default (include "service.name" .) .Values.backstage.kubernetesId -}}
{{- end -}}

{{- define "service.labels" -}}
app.kubernetes.io/name: {{ include "service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
backstage.io/kubernetes-id: {{ include "service.kubernetesId" . }}
{{- end -}}

{{- define "service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/* Workload kind: Deployment (default), Job or CronJob - Devtron's chart types */}}
{{- define "service.kind" -}}
{{- default "Deployment" .Values.kind -}}
{{- end -}}

{{/* Pod spec shared by Deployment, Job and CronJob (resources, placement, image) */}}
{{- define "service.podSpec" -}}
{{- $kind := include "service.kind" . -}}
{{- if ne $kind "Deployment" }}
restartPolicy: {{ ternary "Never" "OnFailure" (eq $kind "Job") }}
{{- end }}
containers:
  - name: app
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    {{- with .Values.command }}
    command:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .Values.args }}
    args:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- if eq $kind "Deployment" }}
    ports:
      - name: http
        containerPort: {{ .Values.containerPort }}
    {{- end }}
    {{- with .Values.env }}
    env:
      {{- range $k, $v := . }}
      - name: {{ $k }}
        value: {{ $v | quote }}
      {{- end }}
    {{- end }}
    {{- if and (eq $kind "Deployment") .Values.probes.enabled }}
    readinessProbe:
      httpGet:
        path: {{ .Values.probes.path }}
        port: http
      initialDelaySeconds: {{ .Values.probes.initialDelaySeconds }}
    livenessProbe:
      httpGet:
        path: {{ .Values.probes.path }}
        port: http
      initialDelaySeconds: {{ add .Values.probes.initialDelaySeconds 10 }}
    {{- end }}
    resources:
      {{- toYaml .Values.resources | nindent 6 }}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}
