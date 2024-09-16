defmodule Supafana.Grafana.Alerts do
  require Logger

  def specs(supabase_project_ref, folder_uid, datasource_uid, max_connections \\ 200) do
    basic = [
      low_cpu_alert(supabase_project_ref, folder_uid, datasource_uid),
      high_cpu_alert(supabase_project_ref, folder_uid, datasource_uid),
      low_memory_alert(supabase_project_ref, folder_uid, datasource_uid),
      high_disk_usage_alert(supabase_project_ref, folder_uid, datasource_uid),
      deadlock_alert(supabase_project_ref, folder_uid, datasource_uid)
    ]

    case max_connections do
      nil ->
        basic

      max_connections when is_number(max_connections) ->
        basic ++
          [
            connection_count_alert(
              supabase_project_ref,
              folder_uid,
              datasource_uid,
              max_connections
            )
          ]
    end
  end

  # TEST
  def low_cpu_alert(supabase_project_ref, folder_uid, datasource_uid) do
    %{
      "title" => "Low CPU Usage Alert",
      "ruleGroup" => "CPU_Alerts",
      "folderUID" => folder_uid,
      "noDataState" => "OK",
      "execErrState" => "OK",
      "for" => "5m",
      "orgId" => 1,
      "condition" => "B",
      "annotations" => %{
        "summary" => "Low CPU usage detected"
      },
      "labels" => %{
        "severity" => "critical"
      },
      "data" => [
        %{
          "refId" => "A",
          "queryType" => "",
          "relativeTimeRange" => %{
            "from" => 600,
            "to" => 0
          },
          "datasourceUid" => datasource_uid,
          "model" => %{
            "expr" =>
              "100 * avg(1 - rate(node_cpu_seconds_total{mode=\"idle\",supabase_project_ref=\"#{supabase_project_ref}\"}[5m])) < 10",
            "hide" => false,
            "intervalMs" => 1000,
            "maxDataPoints" => 43200,
            "refId" => "A"
          }
        },
        %{
          "refId" => "B",
          "queryType" => "",
          "relativeTimeRange" => %{
            "from" => 0,
            "to" => 0
          },
          "datasourceUid" => "-100",
          "model" => %{
            "conditions" => [
              %{
                "evaluator" => %{
                  "params" => [10],
                  "type" => "lt"
                },
                "operator" => %{
                  "type" => "and"
                },
                "query" => %{
                  "params" => ["A"]
                },
                "reducer" => %{
                  "params" => [],
                  "type" => "last"
                },
                "type" => "query"
              }
            ],
            "datasource" => %{
              "type" => "__expr__",
              "uid" => "-100"
            },
            "hide" => false,
            "intervalMs" => 1000,
            "maxDataPoints" => 43200,
            "refId" => "B",
            "type" => "classic_conditions"
          }
        }
      ]
    }
  end

  def high_cpu_alert(supabase_project_ref, folder_uid, datasource_uid) do
    %{
      "title" => "High CPU Usage Alert",
      "ruleGroup" => "CPU_Alerts",
      "folderUID" => folder_uid,
      "noDataState" => "OK",
      "execErrState" => "OK",
      "for" => "5m",
      "orgId" => 1,
      "condition" => "B",
      "annotations" => %{
        "summary" => "High CPU usage detected"
      },
      "labels" => %{
        "severity" => "critical"
      },
      "data" => [
        %{
          "refId" => "A",
          "queryType" => "",
          "relativeTimeRange" => %{
            "from" => 600,
            "to" => 0
          },
          "datasourceUid" => datasource_uid,
          "model" => %{
            "expr" =>
              "100 * avg(1 - rate(node_cpu_seconds_total{mode=\"idle\",supabase_project_ref=\"#{supabase_project_ref}\"}[5m])) > 85",
            "hide" => false,
            "intervalMs" => 1000,
            "maxDataPoints" => 43200,
            "refId" => "A"
          }
        },
        %{
          "refId" => "B",
          "queryType" => "",
          "relativeTimeRange" => %{
            "from" => 0,
            "to" => 0
          },
          "datasourceUid" => "-100",
          "model" => %{
            "conditions" => [
              %{
                "evaluator" => %{
                  "params" => [85],
                  "type" => "gt"
                },
                "operator" => %{
                  "type" => "and"
                },
                "query" => %{
                  "params" => ["A"]
                },
                "reducer" => %{
                  "params" => [],
                  "type" => "last"
                },
                "type" => "query"
              }
            ],
            "datasource" => %{
              "type" => "__expr__",
              "uid" => "-100"
            },
            "hide" => false,
            "intervalMs" => 1000,
            "maxDataPoints" => 43200,
            "refId" => "B",
            "type" => "classic_conditions"
          }
        }
      ]
    }
  end

  def low_memory_alert(supabase_project_ref, folder_uid, datasource_uid) do
    %{
      "title" => "Low Available Memory Alert",
      "ruleGroup" => "Memory_Alerts",
      "folderUID" => folder_uid,
      "noDataState" => "OK",
      "execErrState" => "OK",
      "for" => "5m",
      "orgId" => 1,
      "condition" => "B",
      "annotations" => %{
        "summary" => "Low available memory detected"
      },
      "labels" => %{
        "severity" => "critical"
      },
      "data" => [
        %{
          "refId" => "A",
          "queryType" => "",
          "relativeTimeRange" => %{
            "from" => 600,
            "to" => 0
          },
          "datasourceUid" => datasource_uid,
          "model" => %{
            "expr" => """
            100 - ((node_memory_MemAvailable_bytes{supabase_project_ref=\"#{supabase_project_ref}\"} * 100) / node_memory_MemTotal_bytes{supabase_project_ref=\"#{supabase_project_ref}\"}) < 10
            """,
            "hide" => false,
            "intervalMs" => 1000,
            "maxDataPoints" => 43200,
            "refId" => "A"
          }
        },
        %{
          "refId" => "B",
          "queryType" => "",
          "relativeTimeRange" => %{
            "from" => 0,
            "to" => 0
          },
          "datasourceUid" => "-100",
          "model" => %{
            "conditions" => [
              %{
                "evaluator" => %{
                  "params" => [10],
                  "type" => "lt"
                },
                "operator" => %{
                  "type" => "and"
                },
                "query" => %{
                  "params" => ["A"]
                },
                "reducer" => %{
                  "params" => [],
                  "type" => "last"
                },
                "type" => "query"
              }
            ],
            "datasource" => %{
              "type" => "__expr__",
              "uid" => "-100"
            },
            "hide" => false,
            "intervalMs" => 1000,
            "maxDataPoints" => 43200,
            "refId" => "B",
            "type" => "classic_conditions"
          }
        }
      ]
    }
  end

  def high_disk_usage_alert(supabase_project_ref, folder_uid, datasource_uid) do
    %{
      "title" => "High Disk Usage Alert",
      "ruleGroup" => "Disk_Alerts",
      "folderUID" => folder_uid,
      "noDataState" => "OK",
      "execErrState" => "OK",
      "for" => "5m",
      "orgId" => 1,
      "condition" => "B",
      "annotations" => %{
        "summary" => "Disk usage exceeding 90%"
      },
      "labels" => %{
        "severity" => "critical"
      },
      "data" => [
        %{
          "refId" => "A",
          "queryType" => "",
          "relativeTimeRange" => %{
            "from" => 600,
            "to" => 0
          },
          "datasourceUid" => datasource_uid,
          "model" => %{
            "expr" => """
            100 - ((node_filesystem_avail_bytes{supabase_project_ref=\"#{supabase_project_ref}\",mountpoint=\"/\",fstype!=\"rootfs\"} * 100) / node_filesystem_size_bytes{supabase_project_ref=\"#{supabase_project_ref}\",mountpoint=\"/\",fstype!=\"rootfs\"}) > 90
            """,
            "hide" => false,
            "intervalMs" => 1000,
            "maxDataPoints" => 43200,
            "refId" => "A"
          }
        },
        %{
          "refId" => "B",
          "queryType" => "",
          "relativeTimeRange" => %{
            "from" => 0,
            "to" => 0
          },
          "datasourceUid" => "-100",
          "model" => %{
            "conditions" => [
              %{
                "evaluator" => %{
                  "params" => [90],
                  "type" => "gt"
                },
                "operator" => %{
                  "type" => "and"
                },
                "query" => %{
                  "params" => ["A"]
                },
                "reducer" => %{
                  "params" => [],
                  "type" => "last"
                },
                "type" => "query"
              }
            ],
            "datasource" => %{
              "type" => "__expr__",
              "uid" => "-100"
            },
            "hide" => false,
            "intervalMs" => 1000,
            "maxDataPoints" => 43200,
            "refId" => "B",
            "type" => "classic_conditions"
          }
        }
      ]
    }
  end

  def connection_count_alert(supabase_project_ref, folder_uid, datasource_uid, max_connections) do
    %{
      "title" => "Connection Count Alert",
      "ruleGroup" => "Connection_Alerts",
      "folderUID" => folder_uid,
      "noDataState" => "OK",
      "execErrState" => "OK",
      "for" => "5m",
      "orgId" => 1,
      "condition" => "B",
      "annotations" => %{
        "summary" => "Active connections are exceeding 75% of max connections"
      },
      "labels" => %{
        "severity" => "critical"
      },
      "data" => [
        %{
          "refId" => "A",
          "queryType" => "",
          "relativeTimeRange" => %{
            "from" => 600,
            "to" => 0
          },
          "datasourceUid" => datasource_uid,
          "model" => %{
            "expr" => """
            sum(supavisor_connections_active{supabase_project_ref=\"#{supabase_project_ref}\"}) / #{max_connections} * 100 > 75
            """,
            "hide" => false,
            "intervalMs" => 1000,
            "maxDataPoints" => 43200,
            "refId" => "A"
          }
        },
        %{
          "refId" => "B",
          "queryType" => "",
          "relativeTimeRange" => %{
            "from" => 0,
            "to" => 0
          },
          "datasourceUid" => "-100",
          "model" => %{
            "conditions" => [
              %{
                "evaluator" => %{
                  "params" => [75],
                  "type" => "gt"
                },
                "operator" => %{
                  "type" => "and"
                },
                "query" => %{
                  "params" => ["A"]
                },
                "reducer" => %{
                  "params" => [],
                  "type" => "last"
                },
                "type" => "query"
              }
            ],
            "datasource" => %{
              "type" => "__expr__",
              "uid" => "-100"
            },
            "hide" => false,
            "intervalMs" => 1000,
            "maxDataPoints" => 43200,
            "refId" => "B",
            "type" => "classic_conditions"
          }
        }
      ]
    }
  end

  def deadlock_alert(supabase_project_ref, folder_uid, datasource_uid) do
    %{
      "title" => "Deadlock Alert",
      "ruleGroup" => "Transaction_Alerts",
      "folderUID" => folder_uid,
      "noDataState" => "OK",
      "execErrState" => "OK",
      "for" => "5m",
      "orgId" => 1,
      "condition" => "B",
      "annotations" => %{
        "summary" => "Deadlock detected in the database"
      },
      "labels" => %{
        "severity" => "critical"
      },
      "data" => [
        %{
          "refId" => "A",
          "queryType" => "",
          "relativeTimeRange" => %{
            "from" => 600,
            "to" => 0
          },
          "datasourceUid" => datasource_uid,
          "model" => %{
            "expr" => """
            rate(pg_stat_database_deadlocks_total{supabase_project_ref=\"#{supabase_project_ref}\"}[5m]) > 0
            """,
            "hide" => false,
            "intervalMs" => 1000,
            "maxDataPoints" => 43200,
            "refId" => "A"
          }
        }
      ]
    }
  end
end
