{{- define "skyfjell.common.template.flux.helm-release" -}}
{{- $ := last . -}}
{{- $component := first . -}}
{{- $component = default (list) $component.ancestorNames | set $component "ancestorNames" -}}

{{- if $component.chart -}}
{{- $name :=  list $component.aggregateName $component.name $ | include (printf "%s.format.name" $.Chart.Name) -}}
{{- $parent := get $component "parent" | default (dict)  -}}
{{- $solution := $.Values.components.flux -}}

{{- $repo := get $.Values.components.helmRepositories.components $component.chart.source.name -}}
{{- $repo := $repo.name -}}

{{- $sourceName := list $repo $ | include (printf "%s.format.name" $.Chart.Name) -}}
{{- $sourceName := default $sourceName $component.chart.source.name -}}

{{- if and $component.enabled $solution.enabled }}
{{- include "skyfjell.common.require.api.flux.helm-release" $ -}}
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: {{ $name }}
  namespace: {{ $solution.namespace }}
  labels:
    {{- include (printf "%s.labels" $.Chart.Name) $ | nindent 4 }}
    {{- include "skyfjell.common.chartLabels" $ | nindent 4 }}
spec:
  releaseName: {{ $name }}
  targetNamespace: {{ list $component $ | include "skyfjell.common.format.component.namespace" }}
  # TODO: Support local and existing dependsOn
  chart:
    spec:
      chart: {{ $component.chart.name }}
      version: {{ default $component.chart.version }}
      sourceRef:
        kind: {{ default $component.chart.source.kind }}
        name: {{ $sourceName }}
        namespace: {{ $solution.namespace }}
  interval: {{ default $.Values.components.flux.interval $component.chart.interval }}
  {{/*
  # Include the values template for this component in the depending chart
  # Leave `values` key off of component to disable
  # ex: `define [chart-name].components.[component-name].values`
  # or: `define [chart-name].components.[component-name].components.[component-child-name].values`
  */}}
  {{- if hasKey $component "values" }}
  {{- $valuesTemplate := append $component.ancestorNames $component.name | join ".components." | printf "%s.components.%s.values" $.Chart.Name }}
  values: {{ include $valuesTemplate $ | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}

{{- with $component.components }}
  {{- range $child := . }}
    {{- $child = set $child "parent" $component -}}
    {{- $child = set $child "aggregateName" $component.name -}}
    {{- $child = default $child.namespace $component.namespace | set $child "namespace" -}}
    {{- $child = append $component.ancestorNames $component.name | set $child "ancestorNames" -}}
    {{- list $child $ | include "skyfjell.common.template.flux.helm-release" -}}
  {{- end }}
{{- end }}

{{- end }}