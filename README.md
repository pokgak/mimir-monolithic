# README

This helm chart is for deploying a monolithic Mimir instance. It is a fork of the [mimir-distributed](https://github.com/grafana/mimir/tree/main/operations/helm/charts/mimir-distributed) helm chart. The fork is made because there is no official helm chart for deploying Mimir in monolithic mode.

## Features removed

All enterprise related features are removed from this chart. This chart also don't have support for zone-aware setup. Some other parts where I think not relevant for a monolithic setup is also removed.

## Disclaimer

This chart doesn't have thorough testing yet so use at your own risk.

## Installation

```
$ helm repo add pokgak https://pokgak.github.io/mimir-monolithic
$ helm install pokgak/mimir-monolithic
```

## Alternatives

If you don't want to deal with the complicated Mimir configuration, I recommend you to use [VictoriaMetrics](https://victoriametrics.com/) instaed tho it doesn't have support for object storage. So, make your own choice.