import classNames from "classnames";
import { useQuery, useMutation } from "@tanstack/react-query";
import React from "react";
import dayjs from "dayjs";
import relativeTime from "dayjs/plugin/relativeTime";

import { HiExternalLink as ExternalLink } from "react-icons/hi";

import { apiServer, queryClient, queryKeys, useMembers } from "./client";

// import SupafanaLogo from "./landing/assets/logo.svg?url";
import GrafanaLogo from "./landing/assets/grafana-logo-icon.svg?url";

import { nbsp } from "./Utils";

dayjs.extend(relativeTime);

import type { Project as ProjectT } from "../types/supabase";
import type { Grafana as GrafanaT, Alert, EmailAlertContact } from "../types/z_types";

const SupafanaProject = ({
  project,
  grafana,
}: {
  project: ProjectT;
  grafana: GrafanaT | undefined;
}) => {
  const state = grafana?.state ?? "Ready";
  const plan = grafana?.plan ?? "Trial";
  const created = grafana?.inserted_at ? dayjs(grafana.inserted_at).fromNow() : null;

  const provisionGrafanaMutation = useMutation({
    mutationFn: () => {
      return apiServer.url(`/grafanas/${project.id}`).put().text();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.grafanas(project.organization_id) });
    },
  });

  const upgradeGrafanaMutation = useMutation({
    mutationFn: () => {
      return apiServer
        .url(`/billing/subscriptions/${project.id}`)
        .put()
        .json<{ status: string; url?: string }>();
    },
    onSuccess: res => {
      if (res.status === "redirect" && res.url) {
        window.location.href = res.url;
      } else {
        queryClient.invalidateQueries({ queryKey: queryKeys.grafanas(project.organization_id) });
      }
    },
  });

  const deleteGrafanaMutation = useMutation({
    mutationFn: () => {
      return apiServer.url(`/grafanas/${project.id}`).delete().text();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.grafanas(project.organization_id) });
    },
  });

  const intervalRef = React.useRef<ReturnType<typeof setTimeout>>();

  React.useEffect(() => {
    if (grafana) {
      if (["Provisioning", "Deleting", "Creating", "Starting", "Unknown"].includes(grafana.state)) {
        if (!intervalRef.current) {
          intervalRef.current = setInterval(() => {
            queryClient.invalidateQueries({
              queryKey: queryKeys.grafanas(project.organization_id),
            });
            queryClient.invalidateQueries({
              queryKey: queryKeys.billing(project.organization_id),
            });
          }, 9000);
        }
      } else if (grafana.plan === "Trial") {
        if (!intervalRef.current) {
          intervalRef.current = setInterval(() => {
            queryClient.invalidateQueries({
              queryKey: queryKeys.grafanas(project.organization_id),
            });
          }, 30000);
        }
      } else {
        clearInterval(intervalRef.current);
        intervalRef.current = undefined;
      }
    }
  }, [grafana]);

  const [passwordCopied, setPasswordCopied] = React.useState(false);

  React.useEffect(() => {
    if (passwordCopied) {
      setTimeout(() => {
        setPasswordCopied(false);
      }, 500);
    }
  }, [passwordCopied]);

  const trialEnded =
    (grafana &&
      dayjs(grafana.first_start_at).add(grafana.trial_length_min, "minute").isBefore(dayjs())) ??
    false;

  const updateGrafanaMutation = useMutation({
    mutationFn: ({ maxClientConnections }: { maxClientConnections: string }) => {
      return apiServer
        .url(`/grafanas/${project.id}`)
        .post({ maxClientConnections: Number(maxClientConnections) })
        .text();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.grafanas(project.organization_id) });
      queryClient.invalidateQueries({ queryKey: queryKeys.alerts(project.id) });
    },
    onError: () => {
      setMaxClientConnections("200");
    },
  });

  const [maxClientConnections, setMaxClientConnections] = React.useState<string>(
    `${grafana?.max_client_connections ?? "200"}`
  );

  if (!grafana) {
    if (project.status.startsWith("ACTIVE")) {
      return (
        <div className="flex items-center justify-center bg-dots rounded-xl w-full py-8">
          {provisionGrafanaMutation.isPending || !provisionGrafanaMutation.isIdle ? (
            <span className="loading loading-ring loading-lg text-accent" />
          ) : (
            <button
              onClick={() => {
                provisionGrafanaMutation.mutate();
              }}
              className="btn btn-xs btn-primary text-white"
            >
              Provision Grafana
            </button>
          )}
        </div>
      );
    } else {
      return null;
    }
  }

  return (
    <table className="text-gray-200 dark:text-gray-700 bg-dots table">
      <tbody className="text-black dark:text-white">
        <tr>
          <RowTdHeader>
            <span className="text-black dark:text-white font-bold">Grafana</span>
          </RowTdHeader>
          <td colSpan={state === "Running" ? 1 : 2}>
            <a
              className={classNames(
                "inline-flex items-center gap-1.5 font-medium link link-primary dark:link-secondary",
                state === "Running" && "vertical-rl sm:horizontal-tb"
              )}
              href={`/dashboard/${project.id}/`}
              title={`Open ${project.name} in Supafana`}
              target="_blank"
            >
              <img src={GrafanaLogo} alt="Supabase logo" width={12} height={12} />
              {project.name}
              <ExternalLink size={18} />
            </a>
          </td>
          {state === "Running" && (
            <td>
              <a
                href={`/dashboard/${project.id}/`}
                title={`Open ${project.name} in Supafana`}
                target="_blank"
              >
                <button className="btn btn-xs btn-accent w-20">
                  <span>Open</span>
                </button>
              </a>
            </td>
          )}
        </tr>
        <tr>
          <RowTdHeader>State</RowTdHeader>
          <td>
            <span className="font-medium vertical-rl sm:horizontal-tb">{state}</span>
          </td>
          {state === "Running" && (
            <td>
              <button
                onClick={() => {
                  if (window.confirm("Are you sure?") === true) {
                    deleteGrafanaMutation.mutate();
                  }
                }}
                className="btn btn-xs btn-warning w-20"
              >
                {deleteGrafanaMutation.isPending ? (
                  <span className="loading loading-ring loading-xs text-black h-3" />
                ) : (
                  <span>Delete</span>
                )}
              </button>
            </td>
          )}
          {(["Failed"].includes(state) ||
            (plan === "Supafana Pro" && ["Deleted"].includes(state))) && (
            <td>
              {project.status.startsWith("ACTIVE") ? (
                <button
                  onClick={() => {
                    if (!provisionGrafanaMutation.isPending) {
                      provisionGrafanaMutation.mutate();
                    }
                  }}
                  className="btn btn-xs btn-primary w-20 text-white"
                >
                  {provisionGrafanaMutation.isPending ? (
                    <span className="loading loading-ring loading-xs h-3" />
                  ) : (
                    <span>Provision</span>
                  )}
                </button>
              ) : (
                <span className="text-zinc-500">
                  You’ll have to{" "}
                  <a
                    className="link link-primary dark:link-secondary"
                    href={`https://supabase.com/dashboard/project/${project.id}`}
                  >
                    restore
                  </a>{" "}
                  this project to provision Supafana
                </span>
              )}
            </td>
          )}
          {plan === "Trial" && trialEnded && state === "Deleted" && (
            <td>
              <span
                className="text-gray-500"
                dangerouslySetInnerHTML={{ __html: nbsp("↓ Upgrade to provision") }}
              />
            </td>
          )}
          {plan === "Trial" && !trialEnded && state === "Deleted" && (
            <td>
              {project.status.startsWith("ACTIVE") ? (
                <button
                  onClick={() => {
                    provisionGrafanaMutation.mutate();
                  }}
                  className="btn btn-xs btn-primary w-20 text-white"
                >
                  {provisionGrafanaMutation.isPending ? (
                    <span className="loading loading-ring loading-xs h-3" />
                  ) : (
                    <span>Provision</span>
                  )}
                </button>
              ) : (
                <span className="text-zinc-500">
                  You’ll have to{" "}
                  <a
                    className="link link-primary dark:link-secondary"
                    href={`https://supabase.com/dashboard/project/${project.id}`}
                  >
                    restore
                  </a>{" "}
                  this project to provision Supafana
                </span>
              )}
            </td>
          )}
        </tr>
        {plan !== "Trial" && (
          <tr>
            <RowTdHeader>Plan</RowTdHeader>
            <td colSpan={2}>
              <span className="font-medium break-all">{plan}</span>
            </td>
          </tr>
        )}
        {plan === "Trial" && grafana.first_start_at && (
          <tr>
            {trialEnded ? (
              <RowTdHeader>Trial ended</RowTdHeader>
            ) : (
              <RowTdHeader>Trial ends</RowTdHeader>
            )}
            <td>
              <span
                key={grafana.trial_remaining_msec}
                className="inline-block font-medium break-all first-letter:capitalize vertical-rl sm:horizontal-tb"
              >
                {dayjs(grafana.first_start_at).add(grafana.trial_length_min, "minute").fromNow()}
              </span>
            </td>
            <td>
              <button
                onClick={() => {
                  upgradeGrafanaMutation.mutate();
                }}
                className="btn btn-xs btn-secondary w-28"
              >
                {upgradeGrafanaMutation.isPending ? (
                  <span className="loading loading-ring loading-xs h-3" />
                ) : (
                  <span dangerouslySetInnerHTML={{ __html: nbsp("Upgrade to Pro") }} />
                )}
              </button>
            </td>
          </tr>
        )}
        {/*
        <tr>
          <RowHeader>Version</RowHeader>
          <td>
            <span className="font-medium">supafana-version</span>
          </td>
        </tr>
        */}
        {created && (
          <tr>
            <RowTdHeader>Created</RowTdHeader>
            <td colSpan={2}>
              <span className="inline-block font-medium first-letter:capitalize">{created}</span>
            </td>
          </tr>
        )}
        {grafana.state === "Running" && (
          <tr>
            <RowTdHeader>User/pass</RowTdHeader>
            <td>
              <span className="font-medium">
                <code>admin</code>
              </span>
            </td>
            <td>
              <button
                onClick={() => copyTextToClipboard(grafana.password, () => setPasswordCopied(true))}
                className={classNames("btn btn-xs", passwordCopied && "btn-success")}
                dangerouslySetInnerHTML={{ __html: nbsp("Copy password") }}
              />
            </td>
          </tr>
        )}
        {grafana.state === "Running" && (
          <tr>
            <RowTdHeader>Max client connections</RowTdHeader>
            <td>
              <div className="flex items-center gap-2">
                <input
                  className="text-sm input input-sm input-bordered w-full max-w-xs dark:text-black dark:bg-accent font-medium"
                  value={maxClientConnections}
                  onChange={e => {
                    setMaxClientConnections(e.target.value);
                  }}
                />
                <button
                  onClick={() => {
                    updateGrafanaMutation.mutate({ maxClientConnections });
                  }}
                  className="btn btn-sm btn-outline btn-primary dark:btn-accent w-14"
                >
                  {updateGrafanaMutation.isPending ? (
                    <span className="loading loading-ring loading-sm text-primary" />
                  ) : (
                    <span>Set</span>
                  )}
                </button>
              </div>
            </td>
            <td>
              <div className="w-48">
                Note: Supabase API doesn’t offer this information&mdash;please{" "}
                <a
                  className="items-center link link-primary dark:link-secondary"
                  target="_blank"
                  href={`https://supabase.com/dashboard/project/${project.id}/settings/database`}
                >
                  check the value on your Supabase dashboard
                </a>{" "}
                and update accordingly
              </div>
            </td>
          </tr>
        )}
        {grafana.state === "Running" && (
          <tr>
            <td colSpan={3}>
              <Alerting project={project} />
            </td>
          </tr>
        )}
      </tbody>
    </table>
  );
};

const Alerting = ({ project }: { project: ProjectT }) => {
  const { data: allMembers, isLoading: membersLoading } = useMembers({
    enabled: !!project,
    organizationId: project.organization_id as string,
    showEmails: true,
  });

  const {
    data: emailAlertContacts,
    isLoading: emailAlertContactsLoading,
    isFetching: emailAlertContactsFetching,
    isPending: emailAlertContactsPending,
  } = useQuery({
    queryKey: queryKeys.emailAlertContacts(project.id),
    initialData: [],
    queryFn: async () => {
      return await apiServer
        .url(`/grafanas/${project.id}/email-alert-contacts`)
        .get()
        .json<EmailAlertContact[]>();
    },
    enabled: !!project,
  });

  const emailAlertContactsInProgress =
    emailAlertContactsLoading || emailAlertContactsFetching || emailAlertContactsPending;

  const {
    data: alerts,
    isLoading: alertsLoading,
    isFetching: alertsFetching,
    isPending: alertsPending,
  } = useQuery({
    queryKey: queryKeys.alerts(project.id),
    initialData: [],
    queryFn: async () => {
      return await apiServer.url(`/grafanas/${project.id}/alerts`).get().json<Alert[]>();
    },
    enabled: !!project,
  });

  const alertsInProgress = alertsLoading || alertsFetching || alertsPending;

  const members = (allMembers ?? []).filter(m => !!m.email);

  const [clickedEmail, setClickedEmail] = React.useState<null | string>(null);

  const updateEmailAlertContactMutation = useMutation({
    mutationFn: ({ email, enabled }: { email: string; enabled: boolean }) => {
      return apiServer
        .url(`/grafanas/${project.id}/email-alert-contacts/${email}`)
        .post({ enabled })
        .text();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: queryKeys.emailAlertContacts(project.id),
      });
      setClickedEmail(null);
    },
  });

  const [clickedAlert, setClickedAlert] = React.useState<null | string>(null);

  const updateAlertMutation = useMutation({
    mutationFn: ({ title, enabled }: { title: string; enabled: boolean }) => {
      return apiServer.url(`/grafanas/${project.id}/alerts/${title}`).post({ enabled }).text();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: queryKeys.alerts(project.id),
      });
      setClickedAlert(null);
    },
  });

  return (
    <div className="flex flex-col gap-2">
      <div className="font-bold text-black dark:text-white">Alerting</div>
      <div className="p-4 border border-zinc-500 rounded-lg bg-white dark:bg-black">
        {membersLoading ? (
          <span className="loading loading-ring loading-lg text-accent" />
        ) : (
          <table className="text-gray-200 dark:text-gray-700 bg-dots table">
            <tbody className="text-black dark:text-white">
              <tr>
                <RowTdHeader>
                  <a
                    className={classNames(
                      "inline-flex items-center gap-1.5 font-medium link link-primary dark:link-secondary"
                    )}
                    href={`/dashboard/${project.id}/alerting/notifications`}
                    title={`Open contacts for ${project.name} in Grafana`}
                    target="_blank"
                  >
                    <img src={GrafanaLogo} alt="Supabase logo" width={12} height={12} />
                    Contacts
                    <ExternalLink size={18} />
                  </a>
                </RowTdHeader>
                <td>
                  {members.map(m => {
                    const checked = !!emailAlertContacts.find(
                      c => c.email === m.email && c.severity === "critical"
                    );

                    return (
                      <div key={m.user_id} className="flex items-center justify-between h-8">
                        <div>{m.email}</div>
                        <div>
                          {clickedEmail === m.email &&
                          (updateEmailAlertContactMutation.isPending ||
                            emailAlertContactsInProgress) ? (
                            <span className="loading loading-ring loading-sm text-info h-3" />
                          ) : (
                            <input
                              type="checkbox"
                              onChange={e => {
                                setClickedEmail(m.email as string);
                                updateEmailAlertContactMutation.mutate({
                                  email: m.email as string,
                                  enabled: e.target.checked,
                                });
                              }}
                              value={"checked"}
                              checked={checked}
                              className="checkbox checkbox-info checkbox-sm"
                            />
                          )}
                        </div>
                      </div>
                    );
                  })}
                </td>
              </tr>
              <tr>
                <RowTdHeader>
                  <a
                    className={classNames(
                      "inline-flex items-center gap-1.5 font-medium link link-primary dark:link-secondary"
                    )}
                    href={`/dashboard/${project.id}/alerting/list`}
                    title={`Open alerts for ${project.name} in Grafana`}
                    target="_blank"
                  >
                    <img src={GrafanaLogo} alt="Supabase logo" width={12} height={12} />
                    Alerts
                    <ExternalLink size={18} />
                  </a>
                </RowTdHeader>
                <td>
                  {alerts.map(a => {
                    return (
                      <div key={a.title} className="flex items-center justify-between h-8">
                        <div>{a.title}</div>
                        <div>
                          {clickedAlert === a.title &&
                          (updateAlertMutation.isPending || alertsInProgress) ? (
                            <span className="loading loading-ring loading-sm text-info h-3" />
                          ) : (
                            <input
                              type="checkbox"
                              onChange={e => {
                                setClickedAlert(a.title);
                                updateAlertMutation.mutate({
                                  title: a.title,
                                  enabled: e.target.checked,
                                });
                              }}
                              value={"checked"}
                              checked={a.enabled}
                              className="checkbox checkbox-info checkbox-sm"
                            />
                          )}
                        </div>
                      </div>
                    );
                  })}
                </td>
              </tr>
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};

const RowTdHeader = ({
  children,
  className,
}: {
  children: JSX.Element | string;
  className?: string;
}) => {
  return (
    <td className={classNames(className)}>
      <span className="text-gray-500 dark:text-gray-300">{children}</span>
    </td>
  );
};

const copyTextToClipboard = (text: string, onSuccess: () => void, onError?: () => void) => {
  navigator.clipboard.writeText(text).then(
    () => {
      onSuccess();
    },
    () => {
      if (onError) {
        onError();
      }
    }
  );
};

export default SupafanaProject;
