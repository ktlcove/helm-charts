{{- define "rocketmq.broker" -}}
{{- $cname := printf "%s-broker-%s-%s" .fullname .name .id }}
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ $cname }}
  labels:
    {{ .labels | toYaml | nindent 4 }}
    rocketmq.role: broker
    rocketmq.broker: {{ .name }}-{{ .id }}
  annotations:
    rocketmq.broker/properties.checksum: "todo, add properties checksum here"
spec:
  replicas: 1
  serviceName: default
  selector:
    matchLabels:
      {{ .labels | toYaml | nindent 6 }}
      rocketmq.role: broker
      rocketmq.broker: {{ .name }}-{{ .id }}
  template:
    metadata:
      labels:
        {{ .labels | toYaml | nindent 8 }}
        rocketmq.role: broker
        rocketmq.broker: {{ .name }}-{{ .id }}
    spec:
      containers:
      - name: rocketmq-broker
        image: {{ .image.repository }}:{{ .image.tag }}
        imagePullPolicy: {{ .image.pullPolicy }}
        command: 
        - /bin/sh
        - mqbroker
        - -c
        - /etc/rocketmq/broker.properties
        {{- with .env }}
        env:
        {{- range $key, $value := .env }}
        - name: {{ $key }}
          value: {{ $value }}
        {{- end }}
        {{- end }}

        {{- with .resources }}
        resources:
          {{- toYaml . | nindent 10 }}
        {{- end }}
        
        ports:
        - containerPort: 10909
        - containerPort: 10911
        
        volumeMounts:
        - name: properties
          mountPath: /etc/rocketmq
        {{- if .pvc.enabled }}
        - name: {{ $cname }}-data
          mountPath: /data/rocketmq
        {{- end }}
      {{- with .nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      {{- with .tolerations }}
      tolerations:
        {{- toYaml . | nindent 6 }}
      {{- end }}

      {{- with .affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      volumes:
      - configMap:
          defaultMode: 420
          name: {{ $cname }}-properties
        name: properties
  {{- if .pvc.enabled }}
  volumeClaimTemplates:
  - apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: {{ $cname }}-data
    spec:
      accessModes:
        {{ .pvc.accessModes | toYaml | nindent 8 }}
      resources:
        requests:
          storage: {{ .pvc.size }}
      storageClassName: {{ .pvc.storageClass }}
  {{- end }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $cname }}-properties
  labels:
    {{ .labels | toYaml | nindent 4 }}
    rocketmq.role: broker
    rocketmq.broker: {{ .name }}-{{ .id }}
data:
  broker.properties: |
    brokerName={{ .name }}
    brokerId={{ .id | toString }}
    {{- range $key, $value := .properties }}
    {{ ( printf "%s=%s" $key $value ) }}
    {{- end }}

{{- end }}